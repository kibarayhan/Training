# Gap Analysis: Planned MVP vs Intervals.icu

Companion to `workout-app-market-research.md` and `workout-app-discovery-questions.md`.
Intervals.icu is the closest free competitor and the most feature-dense benchmark
([intervals.icu](https://www.intervals.icu/), 160K+ athletes, free). This doc lists what
it has that our MVP spec doesn't, grades whether each gap matters, and what we have
that it doesn't.

## Legend

- 🔴 **Real gap** — users (or you) will feel it; needs a plan even if deferred
- 🟡 **Deliberate deferral** — already consciously postponed in the decision rounds
- ⚪ **Fine to ignore** — off-strategy for a native personal training app

---

## 1. Activity analysis (their biggest lead)

| Intervals.icu feature | Grade | Notes |
|---|---|---|
| Automatic interval detection in completed activities ([source](https://www.intervals.icu/features/analyze/)) | 🔴 | Our matching compares planned vs actual; without interval detection, step-by-step compliance ("did you hold 250W in rep 4?") is much weaker. MVP can start with whole-activity load only, but per-step analysis is the natural v1.x. |
| Power curve / pace curve with season comparison, W/kg ([source](https://www.intervals.icu/features/power-curve/)) | 🟡 | Classic analytics; not needed for the plan→execute→project loop. v2. |
| Critical-power models: eFTP, Morton 3P, Monod-Scherrer, W' balance | 🟡 | We chose manual thresholds + history for MVP; auto eFTP was explicitly deferred to v2. |
| 70+ metric custom charts, custom activity charts ([source](https://www.intervals.icu/features/custom-charts/)) | ⚪ | This is Intervals.icu's identity — a data-scientist workbench. Competing there is a losing game; we compete on native UX, not chart count. |
| HR recovery, efficiency factor, aerobic decoupling, spike correction | 🟡 | Nice post-workout metrics; cheap to add later once samples are ingested. |
| CSV export of everything | ⚪ | Power-user feature; low demand in a personal iOS app. |

## 2. Fitness & load tracking

| Intervals.icu feature | Grade | Notes |
|---|---|---|
| Fitness/fatigue/form chart **including future projection from planned workouts** ([source](https://www.intervals.icu/features/fitness-chart/)) | ✅ parity planned | Note honestly: our "projection" feature is NOT novel — Intervals.icu already projects future form. Our version must win on presentation (native, glanceable, race-day framing), not existence. |
| Time-in-zone distribution, weekly/monthly totals per sport | 🔴 | Cheap to compute, expected by anyone who trains with zones. Should be in MVP — add to spec. |
| Custom zones per sport | ✅ parity planned | Already in our decisions (per-sport zones). |

## 3. Wellness

| Intervals.icu feature | Grade | Notes |
|---|---|---|
| Wellness tracking: sleep, HRV, resting HR, weight, readiness, glucose, mood, blood pressure, menstrual cycle — auto-synced from Garmin, Oura, WHOOP, Polar, Suunto, Coros ([source](https://www.intervals.icu/features/wellness/)) | 🟡 with a shortcut | We deferred wellness. BUT: on iOS most of this (sleep, HRV, RHR, weight) is already sitting in **HealthKit for free** — no per-vendor integrations needed. Displaying HealthKit wellness alongside the fitness chart is days of work, not months, and is a genuine native advantage. Reconsider for v1.x. |

## 4. Workout builder

| Intervals.icu feature | Grade | Notes |
|---|---|---|
| Text-syntax workout editor (type "4x 5m 105% 3m 60%") | ⚪→🟡 | Their beloved power-user feature. On mobile, a good touch editor matters more — but a quick-entry text parser is a great fit for phone keyboards too. Optional delight feature. |
| Import: ZWO, FIT, MRC, ERG ([source](https://www.intervals.icu/features/workout-builder/)) | 🔴 (import FIT/ZWO) | We specced FIT **export** but not **import**. Import matters twice: bringing an existing workout library in, and ingesting completed-activity FIT files from Garmin/Karoo (already flagged in decisions). Add FIT import to MVP; ZWO/MRC/ERG later. |
| Ramp steps (sliding target) | 🟡 | FIT/Zwift support ramps; WorkoutKit doesn't. Already noted as approximate-or-drop; decision stands (drop for MVP, approximate on export later). |
| Workout library with folders/organization | 🔴 | We have "workouts as templates" but no organization scheme. Trivial to add (tags or folders) — do it in MVP before the library grows. |

## 5. Planning

| Intervals.icu feature | Grade | Notes |
|---|---|---|
| Reusable multi-week **plan templates** applied to calendar | 🟡 | Our plan is calendar-first for personal use; multi-week reusable blocks become important the day a second user exists. |
| Drag-and-drop season planning on desktop web | ⚪ | Web planner consciously skipped (decision: native iOS only). Revisit only if the tool outgrows personal use. |
| Import plans from third-party calendars (TrainingPeaks etc.) | ⚪ | Ecosystem play; not needed for a personal tool. |

## 6. Platform & ecosystem (structural, not features)

| Intervals.icu | Grade | Notes |
|---|---|---|
| Direct sync with Garmin, Wahoo, Polar, Suunto, Coros, Zwift, Strava, Oura, WHOOP, Dropbox | 🔴 for Garmin/Strava inbound | Already flagged: without inbound activity sync, Garmin/Karoo rides only reach us via manual FIT import or HealthKit forwarding. This is the #1 v2 item. |
| Open API, 200+ third-party integrations ([source](https://forum.intervals.icu/t/api-access-to-intervals-icu/609)) | ⚪ | Platform play, irrelevant for personal tool. |
| All sports (swim, row, ski, strength…) | 🟡 | We chose run+bike. Keep `sport` an extensible enum so a third sport is data, not surgery. |
| Coach→athlete features | ⚪ | Explicitly out of scope. |
| Community forum, 25+ languages, free | ⚪ | Not product features we can or should chase. |

---

## What we'd have that Intervals.icu doesn't

1. **Native WorkoutKit scheduling** — planned workouts appear in the Apple Watch Workout app / iPhone Fitness app natively with power/pace/HR/cadence step alerts. Intervals.icu's iOS companion app is a thin client; it cannot match a first-party-feeling Watch experience.
2. **Mobile-first UX** — Intervals.icu is a desktop web tool at heart; building/editing a workout on a phone there is painful. Our entire product lives where the athlete is.
3. **HealthKit-native ingestion** — Apple Watch activities and wellness data (HRV, sleep, RHR) with zero account linking.
4. **Offline-first, no account, no server** — personal data stays on device/iCloud.

## Verdict

Intervals.icu wins on breadth (analytics, integrations, sports, price) and always will —
that's 10 years of a full-time developer's work. The correct strategy is unchanged:
**don't chase the workbench; own the native execution loop** (build → schedule → Watch/
head-unit → auto-match → fitness projection) that Intervals.icu can't do natively.

**Spec changes this analysis triggers (MVP additions):**
1. FIT **import** (workouts + completed activities), not just export
2. Time-in-zone + weekly totals per sport
3. Workout library organization (tags/folders)
4. v1.x shortlist: HealthKit wellness panel, per-step compliance analysis, text-entry workout parser
