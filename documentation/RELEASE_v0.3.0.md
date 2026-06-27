# Halo v0.3.0

The **whole-day** release. v0.3.0 gives Halo a front door, two new health trackers, cross-tracker
intelligence that reasons about *patterns* across your day, and surfaces it all on the Lock Screen,
Control Center, and Dynamic Island. Everything stays on-device with deterministic fallbacks, exactly
as before.

> Builds on [v0.2.0](RELEASE_v0.2.0.md) (the on-device AI release). See [RELEASE.md](RELEASE.md) for the
> versioning/tagging process.

## 🏠 A home for your day

- **Today dashboard** — a new **Home** tab is now the front door: glanceable Liquid Glass cards for
  every tracker (calorie ring, water, habits + streak, next to-dos, mood, workouts, pills, weight,
  sleep). Tap a card to jump straight to its tracker.
- **Insights hub** — a chart button on Home opens **Insights**: detected patterns, an AI summary, and a
  one-tap end-of-day reflection.

## ➕ New & deeper trackers

- **Weight** — log by voice ("log my weight 80 kilos", pounds auto-convert) or by hand, with a trend
  chart. Reads and writes **Apple Health** body mass; Health weigh-ins merge in read-only.
- **Sleep** — log a night ("I slept 7 hours") or read **Apple Watch / Apple Fitness** sleep, with a
  nightly average against your goal.
- **Medication schedules & adherence** — Pills goes beyond logging: set recurring reminders ("remind me
  to take vitamin D at 9am every day"), see what's still due today, and tap **Take** to log a dose.
- **Mood + journaling** — every mood check-in now carries an optional long-form journal entry (and the
  AI reflection from a spoken mood is saved with it).
- **Rich-text Notes** — the note editor gains a formatting bar (bold, italic, headings) on the iOS 26
  attributed `TextEditor`.

## 🧠 Cross-tracker AI

- **Patterns** — a deterministic correlation engine surfaces cross-tracker trends ("your mood averages
  4.2 on workout days vs 3.1 on rest days") across mood, workouts, water, habits, and sleep, with a
  minimum-sample guard so noise never becomes a "trend." The model only words the top finding.
- **End-of-day reflection** — "wrap up my day" writes a warm recap across every tracker (briefing
  fallback when AI is unavailable).
- **History questions** — ask about the past: "what did I eat Tuesday?", "how much water yesterday?",
  "how did I sleep last week?" — resolved to the exact figures for that day or week.
- **Proactive daily coach** — an opt-in daily briefing reminder (time configurable in Settings).
- **Personalized meal suggestions** — "what should I eat?" now respects your diet preferences and
  **never suggests an allergen**.

## 🍽️ Diet preferences

- **Onboarding** gains a "Your food, your way" step: pick your eating style (omnivore / vegetarian /
  vegan / pescatarian), the foods you love, and your allergies (quick chips + free text).
- All of it is editable later under **Settings → Diet**, and feeds the AI meal suggestions.

## 🎛️ Control Center, Lock Screen & Dynamic Island

- **Control Center / Lock Screen controls** — one-tap **Log a Glass of Water** and **Talk to Halo**.
- **Workout Live Activity** — start a live workout from the Workouts tab and watch a running timer on
  the **Lock Screen and Dynamic Island**; tap **Finish** to log it with an estimated calorie burn.
- **Fresh widgets** — logging by voice/Siri/control now refreshes the Home Screen widgets.

## ⚙️ Settings, reorganized

- Settings is now a **per-tracker hub** — focused pages for Diet (incl. preferences), Water, Sleep,
  Voice & Siri, and the Daily Coach — instead of one long form.

## 🛠️ Under the hood

- New SwiftData models — `WeightEntry`, `SleepEntry`, `MedicationSchedule` — added to the shared
  App Group store; `MoodEntry` gains a `journal` field.
- New voice actions (`weight`, `sleep`, `pillSchedule`, `reflect`) route through the same AI-first
  pipeline with rule-based fallbacks.
- New services: `CorrelationEngine` (pure, unit-tested), `LiveWorkoutController`, plus weight/sleep
  reads and repeating reminders in `HealthKitService` / `NotificationService`.
- **58 unit tests** pass, including new coverage for weight/sleep parsing, past-date resolution, the
  correlation engine's sample guard, and the new voice routing.

## Notes / requirements

- AI features require an **Apple Intelligence-eligible device**; elsewhere (including the simulator)
  they use deterministic fallbacks.
- Apple Health reads/writes (weight, sleep, workouts, dietary energy), Live Activities, and Control
  Center controls need a **real device** with the relevant permissions and a configured
  `DEVELOPMENT_TEAM` for signing.
- Adding Weight and Sleep keeps the tab bar tidy by surfacing them from the **Home** dashboard rather
  than as top-level tabs.
