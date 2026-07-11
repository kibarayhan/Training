# MVP Specification: Structured Training App for Running & Cycling

**Status:** Draft v1 — 2026-07-11
**Source of truth.** Consolidates the decisions from `workout-app-discovery-questions.md`
(rounds 1–2) and the spec changes from `workout-app-vs-intervals-icu.md`.
Background: `workout-app-market-research.md`.

---

## 1. Product definition

A native iOS + watchOS app for a self-coached athlete training in **running and
cycling**. The core loop:

> **Build** a structured workout → **schedule** it on a calendar → execute it on
> **Apple Watch (native sync)** or **Garmin/Karoo (FIT export)** → completed
> activity is **auto-matched** to the plan → **fitness chart** updates and
> **projects forward** through the remaining planned workouts.

**Intent:** personal tool first; data model designed as if users > 1, features
built for users = 1. No monetization, accounts, or server at MVP.

**Non-goals (MVP):** AI coaching features, Android/web, swim/other sports, coach→athlete
features, custom-chart analytics workbench, smart-trainer control, adaptive plan
reshuffling, wellness tracking (v1.x), open API.

## 2. Platform & architecture

- **Swift / SwiftUI**, iOS 17+ / watchOS 10+ (WorkoutKit floor). Developed with AI tooling (Claude Code).
- **Local-first storage** (SwiftData/Core Data) with CloudKit sync for backup across the user's devices. No custom backend. *(Note: CloudKit requires the paid Apple Developer membership — MVP starts local-only until enrollment; see implementation plan B1.)*
- Watch experience via **WorkoutKit sync into Apple's native Workout app** — no custom Watch app at MVP.
- **Design rule:** the internal workout model is the superset that exports **losslessly to both WorkoutKit and Garmin FIT**. Every builder feature must map to both targets (or explicitly degrade, documented per feature).

## 3. Athlete profile, thresholds & zones

- Sports: `run`, `ride` (extensible enum — a third sport must be data, not surgery).
- **Manual thresholds with dated history:** `ThresholdRecord(sport, kind, value, validFrom)` for FTP (bike power), threshold pace (run), LTHR (per sport). Activities and workouts are always scored against the threshold valid on their date.
- **Per-sport zone models:** power zones (bike), pace zones (run), separate run/bike HR zones. Default to standard 7-zone (power) / 5-zone (HR, pace) schemes; user-editable boundaries.
- Empty-state: guided first-run setup (enter thresholds or accept estimates from age/known race time).

## 4. Workout builder

- Workout = ordered list of **items**; an item is a **step** or a **single-level repeat block** (N × [steps]). No nested repeats.
- **Step length:** time, distance, or **lap-button press** (open-ended). No calorie goals.
- **Step intensity target:** power (W, %FTP), pace (min/km, %threshold), heart rate (bpm, %LTHR, zone), cadence, **RPE/no-target** (a step with no sensor target is valid). Targets are ranges. One primary target per step (WorkoutKit constraint); cadence allowed as secondary annotation for FIT export.
- Step roles: warm-up, work, recovery, cool-down, rest (affects display and WorkoutKit mapping, not physics).
- No ramp steps at MVP (WorkoutKit unsupported; revisit as export-only approximation later).
- **Workout library with organization: tags and/or folders from day one** *(gap-analysis addition #3)*, plus search and per-sport filtering.
- Workouts are **templates**; scheduling places an **instance** on the calendar. Editing a template never silently mutates past instances; future instances prompt.
- Each workout shows **estimated TSS/load and time-in-zone preview** computed from its steps.

## 5. Import & export *(gap-analysis addition #1)*

- **FIT structured-workout export** (MVP-core): for Garmin head units/watches and Hammerhead Karoo (dashboard import). Share-sheet delivery (file, AirDrop, iCloud Drive).
- **FIT import — both kinds** (MVP-core):
  - *Workout files* → builder templates (brings an existing library in).
  - *Completed-activity files* → activities (rides/runs recorded on Garmin/Karoo that never reach HealthKit).
- `.zwo` (Zwift) export for power-based workouts: stretch goal within MVP, else v1.x. MRC/ERG: v1.x.
- Lossless-mapping table (internal ↔ WorkoutKit ↔ FIT) maintained as a living doc/test suite.

## 6. Planning calendar

- Week and month views; drag-to-reschedule; duplicate/shift a week.
- A planned workout carries: workout instance, date, sport, estimated load.
- Target events (race date with name) shown on calendar and fitness projection.
- Weekly planned-load totals visible while planning (see §8).
- Rolling **WorkoutKit sync window** (≤15 scheduled workouts on Watch at any time; nearest-first).

## 7. Activity ingestion & plan matching

- **Sources (MVP):** HealthKit (Apple Watch and anything forwarded into Health) + **manual FIT activity import** (Garmin/Karoo/Zwift). Direct Garmin/Strava API sync is the #1 v2 item.
- **Duplicate detection is required:** same session arriving via multiple paths (e.g. Zwift ride via HealthKit and Karoo FIT) is deduped by sport + start-time proximity + duration/distance similarity; user can force merge/split.
- **Matching rule:** auto-match completed activity to a planned workout of the same sport within **±1 day**; manual re-link always available.
- Compliance states: `completed`, `substituted` (matched, different structure), `missed`, `unplanned`.
- Load fallback chain per activity: power-based TSS → HR-based (hrTSS/TRIMP) → pace-based (rTSS, runs) → RPE × duration → duration × sport default IF. The chain used is shown on the activity.

## 8. Fitness tracking & projection

- **Banister/PMC model:** CTL (42-day EWMA of daily load), ATL (7-day), TSB = CTL − ATL.
- **Combined chart + per-sport breakdown** (run/bike toggle or stacked contribution).
- **Projection:** future CTL/ATL/TSB computed from estimated load of scheduled workouts; rendered as a distinct continuation of the chart. Race-day form callout when a target event exists. Unstructured planned entries ("2h easy") use duration × default IF.
- **Time-in-zone and weekly/monthly totals per sport** *(gap-analysis addition #2)*: time, distance, elevation, load, and zone-time distribution for completed weeks; planned totals for future weeks.
- Load-jump warning when a scheduled week exceeds ~1.3× recent chronic weekly load (simple ramp-rate guard, presented as information, not medical advice).

## 9. Post-MVP roadmap (ordered)

1. **v1.x — per-step compliance analysis** *(gap-analysis addition #4)*: interval detection on completed activities, planned-vs-actual per step ("held 250W for rep 4?"), compliance score.
2. **v1.x — HealthKit wellness panel**: sleep, HRV, resting HR, weight alongside the fitness chart (data already in HealthKit; no vendor integrations).
3. **v1.x — quick-entry text parser** in the builder ("4x 5m 105% / 3m 60%").
4. **v2 — inbound platform sync**: Garmin API (apply for developer program early — approval takes time), Strava; then outbound push-to-device.
5. **v2 — auto threshold estimation** (eFTP-style) on top of threshold history.
6. Later: multi-week plan templates, ramps via export approximation, `.mrc`/`.erg`, third sport.

## 10. Acceptance criteria for "MVP done"

1. Build a workout with repeats, all three step-length types, and all target types in under 2 minutes on the phone.
2. Schedule it; it appears in the Watch's native Workout app with correct step alerts.
3. Export the same workout as FIT; it imports and runs correctly on a Garmin device and a Karoo.
4. Import a Garmin FIT activity; it dedupes against HealthKit, auto-matches the plan (±1 day), and updates the fitness chart with the correct threshold-dated load.
5. Fitness chart shows combined + per-sport CTL/ATL/TSB with future projection through planned workouts and race-day form for a target event.
6. Weekly view shows planned vs completed load, time-in-zone, and totals per sport.
