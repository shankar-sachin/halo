<div align="center">
<img src="https://github.com/shankar-sachin/halo/blob/main/assets/halo.png" alt="Halo Icon" width="20%"> 

  # Halo Lifestyle

**One voice for your whole day.** A voice-powered iOS 26 lifestyle app that bundles ten everyday trackers — behind one conversational assistant and a glanceable Home dashboard.

<img src="assets/demo.gif" alt="Halo Lifestyle on iPhone" width="240" />
&nbsp;&nbsp;
<img src="assets/demo-ipad.gif" alt="Halo Lifestyle on iPad" width="340" />

<sub>Halo Lifestyle on iPhone and iPad — universal, on iOS&nbsp;26 / iPadOS&nbsp;26.</sub>

</div>

A voice-powered lifestyle app for iOS 26 that bundles ten everyday trackers behind one conversational assistant. Speak a command — *"Halo, add a to-do"*, *"log a coffee"*, *"I drank a glass of water"*, *"I slept 7 hours"* — and Halo turns it into the right entry, on device. A **Home dashboard** sums up your whole day at a glance, and an on-device **patterns** engine finds connections across your trackers.

> Display name: **Halo Lifestyle** · Spoken name: **Halo** · Bundle ID: `com.sachi.halo`

## Features

A **Home** dashboard plus ten trackers, one shared data store:

| Tab | What it does |
| --- | --- |
| **Home** | A "Today" dashboard summarizing every tracker at a glance, with a tap-through to each, an Insights hub, and an **Activity** card (steps + active energy from Apple Health) |
| **To-Do** | Tasks with due dates, recurrence, and notifications |
| **Notes** | Quick text notes with a **rich-text** editor (bold, italic, headings) |
| **Diet** | Meal logging with on-device **AI** calorie + macro estimation, **food / caffeine / alcohol categories** (auto-inferred from what you say), a daily calorie ring, weekly insights, and **preference-aware** meal suggestions; syncs to the Health app |
| **Habits** | Daily habit check-ins with streaks |
| **Water** | Water intake tracking |
| **Workouts** | Workout logging (voice + AI calorie-burn estimate), a **live workout** with Lock Screen / Dynamic Island timer, and your **Apple Watch / Apple Fitness** workouts merged in automatically |
| **Mood** | Mood check-ins with optional **journaling** |
| **Pills** | Medication / supplement logging, plus **recurring schedules & adherence** |
| **Weight** | Body-weight logging with a trend chart, reading & writing **Apple Health** *(reachable from Home)* |
| **Sleep** | Sleep logging and **Apple Watch / Apple Fitness** sleep, against your goal, with an on-device **AI Sleep Coach** *(reachable from Home)* |

Plus:

- **"Hey Siri, tell Halo that…"** — one command for everything. Say *"Hey Siri, tell Halo that I drank a glass of water"* (or to add a to-do, log a meal, …) and Halo figures out the rest — no app to open, no tab to find.
- **Talk to Halo (in-app voice)** — prefer to stay in the app? Tap **"Talk to Halo"** from any tab and speak a whole sentence. On-device speech recognition routes the command to the right tracker — no Siri needed, nothing leaves your phone.
- **Patterns & Insights** — an on-device correlation engine surfaces cross-tracker trends ("your mood is higher on workout days") across workouts, water, habits, sleep, calorie budget, medication adherence, and to-do completion, plus an end-of-day reflection and a **monthly digest** ("Review my month") — all under Home → Insights.
- **Diet preferences** — set your eating style and allergies in onboarding (and Settings); Halo tailors meal suggestions and never suggests an allergen.
- **Control Center & Dynamic Island** — one-tap **Log Water** / **Talk to Halo** / **Complete a Habit** / **Mark Pill Taken** controls, and a live workout timer in the Dynamic Island.
- **WidgetKit** — home-screen widgets for upcoming to-dos, the daily calorie ring, and your **habit streak** (home screen + Lock Screen).
- **Shortcuts** — every tracker has a dedicated App Intent (including Weight, Sleep, and Pills), so all of Halo composes into your own Shortcuts automations.
- **HealthKit** — meals (dietary energy) and weight write to Apple Health; **workouts, weight, sleep, steps, and active energy recorded on Apple Watch / Apple Fitness are read back in** (merged read-only with what you log in Halo).
- **App Group** — the app, the widgets, and the Siri intents share one SwiftData store (`group.com.sachi.halo`), so an entry created by Siri shows up everywhere immediately.

## What your voice can do

Control your whole day by talking — no menus, no tab-hopping.

- **AI calorie & macros (on-device)** — say what you ate in plain words and Halo's on-device Apple Intelligence foundation model estimates the calories **and** protein/carbs/fat (free-form, offline, private), tracks your budget, and syncs to Apple Health. Falls back to a bundled food database when Apple Intelligence isn't available.
- **AI understanding** — the same on-device model reads your intent, so natural phrasing just works: *"I crushed a 5k this morning"* logs a workout, *"what's left for dinner?"* answers a question. A deterministic rule-based router is the offline fallback.
- **Ask Halo** — *"How many calories do I have left?"*, *"what's on my to-do list?"*, *"how much water today?"* — Halo reads your data and answers.
- **Daily briefing** — *"Halo, how's my day?"* recaps calories, water, open to-dos, and habit streaks in one go.
- **Edit & delete by voice** — beyond creating: *"reschedule call mom to 7pm"*, *"rename groceries to buy oat milk"*, *"delete my last water"*.
- **One breath, done** — the in-app and background modes capture the whole sentence at once; natural-language times become scheduled reminders, and *"I finished the dishes"* fuzzy-matches and checks off the task (streaks included).
- **Multi-command in one breath** — stack actions in a single sentence: *"I drank water and finished the dishes"* runs both. The on-device model splits them; a rule-based router is the fallback.
- **AI workout calorie burn** — *"log a 30 minute run"* estimates calories burned on-device (with a deterministic MET-based fallback) and stores it on the workout.
- **AI meal suggestions** — *"what should I eat?"* suggests meals that fit your remaining calories for the day.
- **AI weekly & monthly insights & patterns** — *"how was my week?"* turns your 7-day trends into a plain-language insight + tip, now with a cross-tracker pattern ("your mood is higher on workout days") from the on-device correlation engine (also shown in Home → Insights); *"how was my month?"* does the same over 30 days with a first-half/second-half trend.
- **AI mood journaling** — *"I feel stressed about the deadline"* logs the mood, writes a short reflective note, replies with a supportive line, and keeps your words as a journal entry. A **Reflect** button in the Mood tab does the same for typed journal entries, with confirmation before logging.
- **AI Sleep Coach** — open Sleep and tap **Get sleep tips** for a personalized recommendation from your last seven nights (your logs + Apple Watch sleep). Stats are computed in Swift; the model only words them, with a templated fallback when Apple Intelligence isn't available.
- **End-of-day reflection** — *"wrap up my day"* writes a warm recap across every tracker.
- **History questions** — *"what did I eat Tuesday?"*, *"how much water yesterday?"*, *"how did I sleep last week?"* — answered with the exact figures for that day or week.
- **Weight & sleep by voice** — *"log my weight 80 kilos"*, *"I slept 7 hours"* — with Apple Health reads merged in.
- **Medication schedules** — *"remind me to take vitamin D at 9am every day"* sets a recurring reminder; *"did I take my pills today?"* reports adherence.
- **Notes → to-dos** — *"pull to-dos from my last note"* extracts the action items and creates them as tasks (also a one-tap **Extract To-Dos** button in the note editor).

## Downloads
- If you have a Mac or a macOS-powered device AND have Xcode downloaded, you can host directly from the [source code](https://github.com/shankar-sachin/halo/archive/refs/tags/v0.7.0.tar.gz)
- If you don't have macOS, don't have Xcode, or don't want to host locally, download the raw iOS .app file to test on your iPhone through the ZIP file at [halo-lifestyle.zip](https://github.com/shankar-sachin/halo/releases/download/v0.7.0/Halo-Lifestyle.zip), or you can download the build files [here](https://github.com/shankar-sachin/halo/releases/download/v0.7.0/Build.zip)
- If you want to go the long way, follow the instructions beneath

## Requirements

- **Xcode 26** or newer
- **iOS 26** deployment target
- **Swift 6**
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) — the Xcode project is generated from `project.yml`

## Getting started

```bash
# 1. Generate the Xcode project from project.yml
xcodegen generate

# 2. Open it
open Halo.xcodeproj

# Or build from the command line
xcodebuild -project Halo.xcodeproj -scheme Halo -sdk iphonesimulator
```

> The `.xcodeproj` is **generated** and git-ignored. After cloning, run `xcodegen generate` before building. Edit `project.yml` — not the project file — to change targets, settings, or capabilities.

For full command-line build, simulator, and on-device instructions, see **[documentation/BUILD.md](documentation/BUILD.md)**.

Voice features (speech recognition, Siri, microphone) and HealthKit require a real device or a simulator with the relevant permissions granted, and a configured `DEVELOPMENT_TEAM` for signing. The **AI features use Apple Intelligence's on-device foundation model** (`FoundationModels`) — on a non-eligible device or the simulator they automatically fall back to deterministic logic, and reading Apple Watch / Apple Fitness workouts needs a real device signed into iCloud with Health permission granted.

## Documentation

- **[documentation/BUILD.md](documentation/BUILD.md)** — build the app and run the simulator from the command line or Xcode, run tests, and run on a device.
- **[documentation/RELEASE.md](documentation/RELEASE.md)** — versioning and the release/tagging process.
- **[documentation/RELEASE_v0.7.0.md](documentation/RELEASE_v0.7.0.md)** — what's new in v0.7.0 (the everywhere release).
- **[documentation/RELEASE_v0.6.0.md](documentation/RELEASE_v0.6.0.md)** — what's new in v0.6.0 (the categories release).
- **[documentation/RELEASE_v0.5.0.md](documentation/RELEASE_v0.5.0.md)** — what's new in v0.5.0 (the Sleep Coach release).
- **[documentation/RELEASE_v0.4.0.md](documentation/RELEASE_v0.4.0.md)** — what's new in v0.4.0 (the iPad / universal release).
- **[documentation/RELEASE_v0.3.0.md](documentation/RELEASE_v0.3.0.md)** — what's new in v0.3.0 (the whole-day release).
- **[documentation/RELEASE_v0.2.0.md](documentation/RELEASE_v0.2.0.md)** — what's new in v0.2.0 (the on-device AI release).

## Project layout

```
project.yml                 XcodeGen project definition (source of truth)
assets/                     Source artwork (e.g. app icon master)
Halo/
  HaloApp.swift             App entry point
  Models/                   SwiftData models (TodoItem, Note, DietEntry, …)
  Features/                 SwiftUI screens, grouped by tab
  Services/                 Speech, voice routing, on-device AI (HaloIntelligence), CorrelationEngine, calorie estimation, HealthKit, notifications, LiveWorkoutController
  Intents/                  App Intents / Siri shortcuts
  Persistence/              Shared SwiftData ModelContainer
  DesignSystem/             Theme + glass UI components
  Support/                  AppSettings, shared defaults
  Resources/                foods.json, Assets.xcassets (incl. AppIcon)
HaloWidgets/                WidgetKit extension (shares Models + Theme + AppSettings)
HaloTests/                  Unit tests
documentation/              BUILD.md, RELEASE.md, and per-version release notes
docs/                       Landing page (GitHub Pages)
```

## Targets

- **Halo** — the main iOS app
- **HaloWidgets** — WidgetKit app extension
- **HaloTests** — unit test bundle

## Architecture notes

- **SwiftUI + SwiftData** throughout. A single shared `ModelContainer` (`DataController.shared`) lives in an App Group container so the app, widgets, and Siri intents all read and write the same database.
- **On-device voice + AI.** `SpeechRecognizer` captures speech; `VoiceCommandRouter.handle` routes it — AI-first via `HaloIntelligence` (Apple's `FoundationModels`), which can split one sentence into several commands, with a rule-based classifier as the offline fallback. All AI (intent routing, calorie/macro estimation, mood reflection, weekly/monthly insights, suggestions, briefing wording, note→to-dos, workout-burn, end-of-day reflection, pattern wording, sleep coaching) is **on-device, availability-gated, and falls back to deterministic logic** — nothing leaves the phone. User-facing numbers are computed in Swift; the model only words them. Cross-tracker **patterns** are computed deterministically by `CorrelationEngine` with a minimum-sample guard.
- **Apple Health.** Meals (dietary energy) and weight read/write; Apple Watch / Apple Fitness **workouts, weight, and sleep** are read back into their tabs, and **steps + active energy** feed the Home Activity card (`HealthKitService`).
- **Lock Screen presence.** Control Center controls and a workout Live Activity / Dynamic Island live in the widget extension; the app refreshes widgets after each change.
- Settings (including diet preferences) are shared across targets via an App Group `UserDefaults` suite.

## License

Not yet specified.
