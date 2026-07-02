# Halo v0.7.0

The **everywhere** release. Halo's trackers now meet you wherever you are: **Weight, Sleep, and
Pills join Shortcuts/Siri** with dedicated intents, a new **Habit Streak widget** and two new
**Control Center controls** put habits and pills one tap from anywhere, and the AI helpers that
used to be voice-only (mood reflection, note→to-dos) gained **in-app buttons**. Insights got
deeper too — three new cross-tracker correlations, a **monthly digest**, an **Activity card**
reading steps + active energy from Apple Health, and **diet categories** (food / caffeine /
alcohol). Everything stays on-device with the same deterministic fallbacks; all 67 tests pass
(4 new).

> Builds on [v0.6.0](RELEASE_v0.6.0.md) (the categories release). See
> [RELEASE.md](RELEASE.md) for the versioning/tagging process.

## ✨ Shortcuts & Siri parity

- **`LogWeightIntent`, `LogSleepIntent`, `LogPillIntent`** — Weight, Sleep, and Pills now have
  the same dedicated App Intents as every other tracker, so they show up as first-class actions
  in the Shortcuts app and Siri (they call the existing `CommandActions` methods, writing
  through the shared store like everything else).

## 🧠 AI helpers, now with buttons

- **Extract To-Dos** — a toolbar button in the note editor (existing notes) runs the same
  note→to-dos extraction the voice path uses, minus the fuzzy note matching, and confirms the
  result in an alert. The core logic moved to `CommandActions.extractTodos(from:)` so both
  paths share it.
- **Reflect** — a button under the Mood journal field runs the AI mood journaling (keyword
  rating as the deterministic fallback) and shows the inferred emoji, note, and supportive
  reply **for confirmation before logging** — the shared logic is
  `CommandActions.reflectOrFallback(_:)`.

## 📊 Deeper insights

- **Three new correlations** in `CorrelationEngine`, all with the usual minimum-sample guard:
  - **Calorie-budget adherence vs mood** — only days with logged meals count as "under budget."
  - **Medication adherence vs mood** — name-matched against active schedules; skipped entirely
    when there are no schedules.
  - **To-do completion vs mood.**
- **Monthly digest** — a "Review my month" card in Insights, 30-day stats with a
  first-half/second-half trend contrast, worded by on-device AI
  (`HaloIntelligence.monthlyInsight`) with a templated fallback. Also by voice — *"how was my
  month?"* — and an optional first-of-month reminder in Daily Coach settings.

## 📲 Widgets & Control Center

- **Habit Streak widget** (`systemSmall` + `accessoryCircular`) — today's habit progress and
  your best streak, on the Home and Lock Screen.
- **Two new controls** — **Complete a Habit** (marks the next incomplete habit) and **Mark Pill
  Taken** (logs the next due scheduled medication). Both write through `WidgetStore`, since the
  widget process can't reach the app-only `CommandActions`.

## 🍽️ New tracked data

- **Activity card on Home** — today's **steps + active energy** from Apple Health, read-only
  via a new `HKStatisticsQuery` helper. The card only appears when there's data (so the
  simulator simply shows nothing rather than a dead card).
- **Diet categories** — `DietEntry` gained a **food / caffeine / alcohol** category via an
  additive default-valued property (automatic lightweight migration). A segmented picker in
  Log Meal auto-infers from keywords (*"latte"* → Caffeine, *"beer"* → Alcohol), rows get
  matching icons, and voice-logged meals run the same deterministic inference. Per the v1
  decision, all categories still count toward the calorie budget.

## 🐞 Fixes

- **Voice habit actions now refresh widgets** — voice-driven `completeHabit`/`addHabit` never
  called `reloadWidgets()`, unlike every other mutating action; with habit data now on a
  widget, that gap is fixed.

## 🛠️ Under the hood

- One Swift 6 strict-concurrency fix: `NSPredicate` isn't `Sendable`, so the two HealthKit
  stat queries run sequentially with the predicate built inside the helper rather than shared
  across `async let`s.
- **4 new unit tests** cover the new correlations, including the no-schedules guard —
  67 tests total, all passing.

## Notes / requirements

- No new capabilities or permissions. Existing requirements (Xcode 26, iOS 26, Apple
  Intelligence for AI features with deterministic fallbacks elsewhere) are unchanged.
- Needs a real device to verify: the two new Control Center controls, the Activity card
  (the simulator has no step data), and the Apple Intelligence paths (the simulator exercises
  the deterministic fallbacks, which is what the tests cover).
