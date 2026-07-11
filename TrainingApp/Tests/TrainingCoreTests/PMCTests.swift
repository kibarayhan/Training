import XCTest
@testable import TrainingCore

final class PMCTests: XCTestCase {

    private func day(_ n: Int) -> Date {
        // Day n of a synthetic season, UTC midnights.
        Date(timeIntervalSince1970: 1_767_225_600 + Double(n) * 86_400)
    }

    private func constantSeason(days: Int, load: Double, sport: Sport = .ride) -> [DailyLoad] {
        (0..<days).map { DailyLoad(date: day($0), sport: sport, load: load) }
    }

    func testSingleDayImpulse() {
        let series = PMCEngine.series(loads: [DailyLoad(date: day(0), sport: .ride, load: 100)],
                                      from: day(0), to: day(0))
        let alphaCTL = 1 - exp(-1.0 / 42.0)
        let alphaATL = 1 - exp(-1.0 / 7.0)
        XCTAssertEqual(series[0].ctl, 100 * alphaCTL, accuracy: 1e-9)
        XCTAssertEqual(series[0].atl, 100 * alphaATL, accuracy: 1e-9)
    }

    func testConstantLoadConvergesToLoad() {
        let series = PMCEngine.series(loads: constantSeason(days: 600, load: 80),
                                      from: day(0), to: day(599))
        XCTAssertEqual(series.last!.ctl, 80, accuracy: 0.1)
        XCTAssertEqual(series.last!.atl, 80, accuracy: 0.1)
        XCTAssertEqual(series.last!.tsb, 0, accuracy: 0.2)
    }

    func testCTLMonotonicWhileLoadAboveCTL() {
        let series = PMCEngine.series(loads: constantSeason(days: 100, load: 80),
                                      from: day(0), to: day(99))
        for i in 1..<series.count {
            XCTAssertGreaterThan(series[i].ctl, series[i-1].ctl)
        }
    }

    func testFormIsYesterdaysCTLMinusATL() {
        // Convention: TSB shown for a day uses the previous day's CTL/ATL.
        let series = PMCEngine.series(loads: constantSeason(days: 10, load: 100),
                                      from: day(0), to: day(10))
        let d9 = series[9], d10 = series[10]
        XCTAssertEqual(d10.tsb, d9.ctl - d9.atl, accuracy: 1e-9)
    }

    func testRestDaysRaiseForm() {
        // Hard block then 7 days rest: form must climb during rest.
        var loads = constantSeason(days: 28, load: 100)
        loads += (28..<35).map { DailyLoad(date: day($0), sport: .ride, load: 0) }
        let series = PMCEngine.series(loads: loads, from: day(0), to: day(34))
        XCTAssertGreaterThan(series[34].tsb, series[28].tsb)
        XCTAssertLessThan(series[34].ctl, series[27].ctl, "fitness decays during rest")
    }

    func testPerSportBreakdown() {
        let loads = [
            DailyLoad(date: day(0), sport: .ride, load: 100),
            DailyLoad(date: day(0), sport: .run, load: 50),
            DailyLoad(date: day(1), sport: .run, load: 60),
        ]
        let series = PMCEngine.series(loads: loads, from: day(0), to: day(1))
        let alphaCTL = 1 - exp(-1.0 / 42.0)
        XCTAssertEqual(series[0].ctlBySport[.ride]!, 100 * alphaCTL, accuracy: 1e-9)
        XCTAssertEqual(series[0].ctlBySport[.run]!, 50 * alphaCTL, accuracy: 1e-9)
        // Combined = sum of per-sport contributions
        XCTAssertEqual(series[0].ctl, series[0].ctlBySport.values.reduce(0, +), accuracy: 1e-9)
        XCTAssertEqual(series[1].ctl, series[1].ctlBySport.values.reduce(0, +), accuracy: 1e-9)
    }

    func testProjectionEqualsActualsWhenPlansCompleteExactly() {
        // Feeding the same loads as "actual" or as "planned continuation"
        // must produce the identical curve.
        let all = constantSeason(days: 60, load: 70)
        let continuous = PMCEngine.series(loads: all, from: day(0), to: day(59))

        let actuals = Array(all[0..<30])
        let planned = Array(all[30..<60])
        let projected = PMCEngine.series(loads: actuals + planned, from: day(0), to: day(59))

        for (a, b) in zip(continuous, projected) {
            XCTAssertEqual(a.ctl, b.ctl, accuracy: 1e-9)
            XCTAssertEqual(a.atl, b.atl, accuracy: 1e-9)
        }
    }

    func testFormOnDateForRaceDay() {
        var loads = constantSeason(days: 50, load: 90)
        // Taper: one easy week before race day 56
        loads += (50..<56).map { DailyLoad(date: day($0), sport: .ride, load: 30) }
        let series = PMCEngine.series(loads: loads, from: day(0), to: day(56))
        let raceDay = day(56)
        let raceForm = series.first { $0.date == raceDay }?.tsb
        XCTAssertNotNil(raceForm)
        XCTAssertGreaterThan(raceForm!, 0, "tapered race day should be positive form")
    }

    func testMultipleLoadsSameDayAreSummed() {
        let loads = [
            DailyLoad(date: day(0), sport: .ride, load: 60),
            DailyLoad(date: day(0), sport: .ride, load: 40),
        ]
        let series = PMCEngine.series(loads: loads, from: day(0), to: day(0))
        let alphaCTL = 1 - exp(-1.0 / 42.0)
        XCTAssertEqual(series[0].ctl, 100 * alphaCTL, accuracy: 1e-9)
    }

    func testEmptyRangeIsEmpty() {
        XCTAssertTrue(PMCEngine.series(loads: [], from: day(5), to: day(4)).isEmpty)
    }
}
