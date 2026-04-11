# Grip Strength (握力) Measure — Design Spec

Date: 2026-04-11
Status: Draft — awaiting user review

## Summary

Add **grip strength (握力)** as a new tracked measure in LeiLeMe, positioned **first** in the measure ordering. Unlike existing measures (which are either HealthKit-synced, in-app active tests, or subjective ratings), grip strength is user-logged from an external device (home/gym dynamometer). Users record one or more readings per day, each tagged with a hand (left/right) and timestamp. The "today's value" used by the baseline engine, recovery score, and trend chart is derived as **the latest reading from the user's dominant hand on that day**.

## Motivation

Grip strength is a strongly evidenced indicator of overall physical reserve, recovery, and longevity. Adding it as the first-listed measure signals its importance and gives users with a home dynamometer a simple way to incorporate a hard physiological metric into their daily tracking.

## Scope

### In scope

- New SwiftData model for per-reading grip strength entries
- New `.gripStrength` case in the `Measure` enum (first position)
- New `.manualLog` case in the `MeasureType` enum (4th category alongside healthKit / activeTest / subjective)
- Daily-value aggregation: latest reading from dominant hand
- Entry UI: add a reading (value / hand / timestamp) via the measure detail view
- History UI: today's readings list with swipe-to-delete; existing trend chart continues to work via the aggregated daily value
- Settings: dominant hand picker, default right
- Baseline, recovery score, and weekly insights engines updated to include grip strength
- `DataExporter` (CSV/JSON) updated to include grip strength — one row per reading, with fields `date`, `valueKg`, `hand`, `timestamp`
- Chinese and English localization for all new strings

### Out of scope (YAGNI)

- Bluetooth dynamometer integration
- HealthKit sync for hand grip strength
- Editing an existing reading (only add and delete)
- Non-dominant-hand contribution to recovery score
- Left/right asymmetry as a derived metric
- Grip strength onboarding prompts

## User-Facing Behavior

### Home page

- Grip strength card appears as the **first** card in the measure list.
- Card visual follows the same three-state pattern as other cards: no data / has today / stale.
- Tapping the card navigates to `MeasureDetailView(measure: .gripStrength)`, same pattern as every other measure.
- `todayCompletedCount` denominator goes from 9 to 10. The completion celebration overlay fires when all 10 are filled.

### Measure detail view (grip strength variant)

Because `.gripStrength` has `type == .manualLog`, the detail view shows an extra interaction not present for the other measures:

- A prominent **"+ 记录一次"** button at the top of the detail area.
- A **"今日读数"** section listing today's readings (all hands, newest first). Each row: value + unit, hand tag (L/R), relative time. Swipe left to delete a row.
- The existing trend chart (`SingleMeasureTrendChart`) continues to work; it reads `DailyAssessment.value(for: .gripStrength)` which returns the aggregated daily value.
- Educational description (from `measure.description`) shown as usual.

### Add-reading sheet

Tapping "+ 记录一次" opens a modal sheet with:

- **Value** — decimal number input, unit label "kg" to the right
- **Hand** — segmented control, left / right
- **Time** — date picker, defaults to "now", editable
- **Save** / **Cancel** buttons

On save, a new `GripStrengthReading` is inserted into today's `DailyAssessment` (creating the assessment if it doesn't exist yet). The card and detail view update immediately via SwiftData observation.

### Settings

A new section **"握力"** in `SettingsTab`:

- Row: **惯用手** / Dominant hand — segmented or picker, values 左手 / 右手, default 右手.
- Persisted under `UserDefaults.standard` key `"dominantHand"` with string value `"left"` or `"right"`.

First launch does **not** prompt for dominant hand — the default (right) is fine for most users, and the setting is discoverable in Settings.

## Data Model

### New model: `GripStrengthReading`

```swift
@Model
final class GripStrengthReading {
    var valueKg: Double
    var hand: String      // "left" | "right" — String raw value for SwiftData compatibility
    var timestamp: Date
    var assessment: DailyAssessment?  // inverse relationship

    init(valueKg: Double, hand: Hand, timestamp: Date = Date()) {
        self.valueKg = valueKg
        self.hand = hand.rawValue
        self.timestamp = timestamp
    }
}

enum Hand: String {
    case left
    case right
}
```

### `DailyAssessment` additions

```swift
@Relationship(deleteRule: .cascade, inverse: \GripStrengthReading.assessment)
var gripStrengthReadings: [GripStrengthReading] = []
```

The initializer gains a default-empty parameter for backwards-compatible construction.

### Schema migration

This is a SwiftData lightweight migration: adding a new `@Model` class and adding a new to-many relationship to an existing model, both with safe defaults (empty collection). Existing installations with prior data must continue to load without loss. Verified via a migration test that seeds a pre-change assessment and loads it post-change.

## Aggregation Rule — "Today's Grip Strength Value"

In `DailyAssessment.value(for:)`, the new case:

```swift
case .gripStrength:
    let dominant = UserSettings.dominantHand  // reads UserDefaults, fallback .right
    let onDominant = gripStrengthReadings.filter { $0.hand == dominant.rawValue }
    guard let latest = onDominant.max(by: { $0.timestamp < $1.timestamp }) else { return nil }
    return latest.valueKg
```

Properties:

- Non-dominant-hand readings are stored and shown in history but **do not** contribute to the daily value or the recovery score.
- If the user only logged non-dominant readings today → today's value is `nil` (same as not measuring).
- If the user logs multiple dominant-hand readings, the latest by timestamp wins — letting users retry and have the newer attempt override.
- Changing dominant hand in Settings retroactively changes all historical daily values (trend chart re-renders). This is an acceptable consequence — dominant hand rarely changes.

## Engines

### `BaselineEngine.BaselineSnapshot`

- New field: `gripStrengthBaseline: Double?`
- `computeBaseline(from:)` adds a rolling-mean accumulator for grip strength across the baseline window, using the aggregated `value(for: .gripStrength)` per day.
- `BaselineSnapshot.value(for:)` extension adds `.gripStrength` case returning `gripStrengthBaseline`.

### `RecoveryScoreEngine`

The engine hard-codes a `[Dimension]` array literal inside `evaluate(...)`, each with an explicit weight. The constant `dimensionCount = 9` is also hard-coded. Both must be updated explicitly:

- Bump `dimensionCount` from 9 to 10.
- Prepend a new `Dimension` entry for grip strength:
  ```swift
  Dimension(name: "Grip Strength",
            todayValue: assessment.value(for: .gripStrength),
            baselineValue: baseline.gripStrengthBaseline,
            weight: 20, higherIsBetter: true),
  ```
- **Weight: 20**, matching HRV as the highest-weighted dimension. This reflects grip strength's status as a hard physiological indicator and the user's explicit intent to position it first.
- The existing weights (HRV=20, RHR=10, Tap Freq=15, Stability=5, Reaction Time=15, Sleep Dur=10, Sleep Quality=5, Soreness=10, Energy=10, total=100) remain unchanged. The new total is 120. This is fine because the engine already renormalizes weights based on available dimensions on each call, so absolute sum doesn't matter — only relative ratios.
- The scoring loop (ratio vs. baseline, then normalized-weight-weighted sum) already handles arbitrary dimensions via `higherIsBetter`; no special-case code needed.
- Note that using `assessment.value(for: .gripStrength)` here introduces a `UserDefaults` read inside the engine's evaluate path via the aggregation rule. See the UserSettings section below.

### `WeeklyInsightsService`

- Should automatically pick up grip strength via `Measure.allCases`. Verify no hard-coded exclusion.

## `Measure` Enum Changes

```swift
enum Measure: String, CaseIterable, Identifiable {
    case gripStrength      // NEW — first position
    case hrvSDNN
    case restingHeartRate
    case sleepDuration
    case tapFrequency
    case tapStability
    case reactionTime
    case sleepQuality
    case muscleSoreness
    case energyLevel
    ...
}
```

New case properties:

| Property | Value |
|---|---|
| `name` | `measure.gripStrength.name` → 握力 / Grip Strength |
| `icon` | `hand.raised.fill` (SF Symbol — confirmed to exist; can be swapped during UI review) |
| `unit` | `measure.unit.kg` → kg |
| `higherIsBetter` | `true` |
| `type` | `.manualLog` |
| `formatString` | `%.1f` |
| `description` | `measure.gripStrength.description` — educational blurb |

## `MeasureType` Enum Changes

```swift
enum MeasureType: String, Codable {
    case healthKit
    case activeTest
    case subjective
    case manualLog    // NEW
}
```

`promptText` gains a new branch returning `measure.prompt.log` → "记录一次" / "Log a reading".

## Localization

New keys in both `zh-Hans.lproj/Localizable.strings` and `en.lproj/Localizable.strings`:

- `measure.gripStrength.name` — 握力 / Grip Strength
- `measure.gripStrength.description` — educational blurb (1–2 sentences)
- `measure.unit.kg` — kg / kg
- `measure.prompt.log` — 记录一次 / Log a reading
- `settings.gripStrength.section` — 握力 / Grip Strength
- `settings.gripStrength.dominantHand.title` — 惯用手 / Dominant hand
- `settings.gripStrength.dominantHand.left` — 左手 / Left
- `settings.gripStrength.dominantHand.right` — 右手 / Right
- `gripStrength.add.title` — 记录握力 / Log grip strength
- `gripStrength.add.valueLabel` — 数值 / Value
- `gripStrength.add.handLabel` — 哪只手 / Hand
- `gripStrength.add.timeLabel` — 时间 / Time
- `gripStrength.add.save` — 保存 / Save
- `gripStrength.add.cancel` — 取消 / Cancel
- `gripStrength.today.title` — 今日读数 / Today's readings
- `gripStrength.hand.left.short` — 左 / L
- `gripStrength.hand.right.short` — 右 / R

## Testing

Unit tests covering:

- `DailyAssessment.value(for: .gripStrength)` — empty readings → nil; only non-dominant → nil; multiple dominant → latest by timestamp; dominant-hand change flips the value correctly.
- `BaselineEngine.computeBaseline` — includes grip strength rolling mean; excludes days with no dominant-hand readings from the mean.
- `RecoveryScoreEngine.evaluate` — grip strength contributes a dimension; score with grip strength matches expected formula; score ignores grip strength when its daily value is nil.
- `Measure.allCases` invariants — `.gripStrength` is at index 0; count is 10; all case properties are non-nil/valid.
- Migration — seed an in-memory store with a pre-change `DailyAssessment` fixture and verify post-change load succeeds with empty `gripStrengthReadings`.

## UserSettings Layer

The project does not currently have a `UserSettings` singleton. `UserDefaults.standard` is read/written directly in `NotificationManager`, `HealthKitService`, and `CompletionCelebrationView`. For grip strength we introduce a small focused wrapper:

```swift
enum UserSettings {
    private static let dominantHandKey = "dominantHand"

    static var dominantHand: Hand {
        get {
            guard let raw = UserDefaults.standard.string(forKey: dominantHandKey),
                  let hand = Hand(rawValue: raw) else {
                return .right
            }
            return hand
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: dominantHandKey)
        }
    }
}
```

Rationale: keeping this as an `enum` with static properties (not a singleton class) avoids injecting a dependency into the `DailyAssessment.value(for:)` extension, matches Swift idiom, and is easy to override in tests by setting `UserDefaults.standard` directly. Not attempting to refactor the other direct-UserDefaults call sites — that's out of scope.

## Notes for Implementation

- **Icon choice**: `hand.raised.fill` is a safe placeholder. During UI implementation, consider alternatives (e.g., `dumbbell.fill`, `figure.strengthtraining.traditional`) and pick what visually reads as "grip strength" without ambiguity. This is a pure UI decision and does not need to block the spec.
