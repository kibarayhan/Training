import Foundation

/// One day's training load for one sport, the PMC engine's only input —
/// past days come from completed activities, future days from workout
/// estimates, which is what makes projection the same computation.
public struct DailyLoad: Equatable, Sendable {
    public var date: Date
    public var sport: Sport
    public var load: Double

    public init(date: Date, sport: Sport, load: Double) {
        self.date = date
        self.sport = sport
        self.load = load
    }
}

public struct PMCPoint: Equatable, Sendable {
    public var date: Date
    /// Fitness: 42-day exponentially weighted load.
    public var ctl: Double
    /// Fatigue: 7-day exponentially weighted load.
    public var atl: Double
    /// Form: yesterday's ctl − atl (what you can express today).
    public var tsb: Double
    public var ctlBySport: [Sport: Double]
    public var atlBySport: [Sport: Double]
}

/// Banister/Coggan performance-management model with exponential smoothing:
/// x_t = x_{t-1} · e^(−1/τ) + load_t · (1 − e^(−1/τ)), τ = 42 (CTL) / 7 (ATL).
/// Per-sport series use the same recursion; the combined value is their sum,
/// which equals running the recursion on summed loads.
public enum PMCEngine {

    public static let ctlTimeConstant = 42.0
    public static let atlTimeConstant = 7.0

    public static func series(loads: [DailyLoad], from: Date, to: Date) -> [PMCPoint] {
        guard from <= to else { return [] }

        let daySeconds = 86_400.0
        func dayIndex(_ date: Date) -> Int { date.utcDayIndex }

        var loadBySportAndDay: [Sport: [Int: Double]] = [:]
        var sports: Set<Sport> = []
        for entry in loads {
            sports.insert(entry.sport)
            loadBySportAndDay[entry.sport, default: [:]][dayIndex(entry.date), default: 0] += entry.load
        }

        let ctlDecay = exp(-1.0 / ctlTimeConstant)
        let atlDecay = exp(-1.0 / atlTimeConstant)

        var ctl: [Sport: Double] = [:]
        var atl: [Sport: Double] = [:]
        var points: [PMCPoint] = []

        let firstDay = dayIndex(from)
        let lastDay = dayIndex(to)
        // Seed history: loads earlier than the requested range still shape
        // the starting CTL/ATL instead of being silently dropped.
        let earliestLoadDay = loadBySportAndDay.values
            .flatMap(\.keys).min() ?? firstDay
        let startDay = min(earliestLoadDay, firstDay)

        for day in startDay...lastDay {
            let previousCombinedCTL = ctl.values.reduce(0, +)
            let previousCombinedATL = atl.values.reduce(0, +)

            for sport in sports {
                let load = loadBySportAndDay[sport]?[day] ?? 0
                ctl[sport] = (ctl[sport] ?? 0) * ctlDecay + load * (1 - ctlDecay)
                atl[sport] = (atl[sport] ?? 0) * atlDecay + load * (1 - atlDecay)
            }

            if day >= firstDay {
                points.append(PMCPoint(
                    date: Date(timeIntervalSince1970: Double(day) * daySeconds),
                    ctl: ctl.values.reduce(0, +),
                    atl: atl.values.reduce(0, +),
                    tsb: previousCombinedCTL - previousCombinedATL,
                    ctlBySport: ctl,
                    atlBySport: atl))
            }
        }
        return points
    }

    /// Form on a specific day (e.g. race day) from a computed series.
    public static func form(on date: Date, in series: [PMCPoint]) -> Double? {
        series.first { $0.date.utcDayIndex == date.utcDayIndex }?.tsb
    }
}

extension Date {
    /// Calendar-day bucket shared by PMC, matching, and the sync window.
    /// UTC-based for now; a future timezone-awareness fix lands in one place.
    public var utcDayIndex: Int {
        Int((timeIntervalSince1970 / 86_400).rounded(.down))
    }
}
