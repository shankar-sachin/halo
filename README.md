<div align="center">

# Halo Lifestyle

**One voice for your whole day.** A voice-powered iOS 26 lifestyle app that bundles eight everyday trackers behind one conversational assistant.

<img src="assets/demo.gif" alt="Halo Lifestyle demo" width="260" />

</div>

A voice-powered lifestyle app for iOS 26 that bundles eight everyday trackers behind one conversational assistant. Speak a command — *"Halo, add a to-do"*, *"log a coffee"*, *"I drank a glass of water"* — and Halo turns it into the right entry, on device.

> Display name: **Halo Lifestyle** · Spoken name: **Halo** · Bundle ID: `com.sachi.halo`

## Features

Eight tabs, one shared data store:

| Tab | What it does |
| --- | --- |
| **To-Do** | Tasks with due dates, recurrence, and notifications |
| **Notes** | Quick text notes |
| **Diet** | Meal logging with on-device **AI** calorie + macro estimation, a daily calorie ring, weekly insights, and meal suggestions; syncs to the Health app |
| **Habits** | Daily habit check-ins |
| **Water** | Water intake tracking |
| **Workouts** | Workout logging (voice + AI calorie-burn estimate) — and your **Apple Watch / Apple Fitness** workouts appear here automatically |
| **Mood** | Mood check-ins |
| **Pills** | Medication / supplement logging |

Plus:

- **"Hey Siri, tell Halo that…"** — one command for everything. Say *"Hey Siri, tell Halo that I drank a glass of water"* (or to add a to-do, log a meal, …) and Halo figures out the rest — no app to open, no tab to find.
- **Talk to Halo (in-app voice)** — prefer to stay in the app? Tap **"Talk to Halo"** from any tab and speak a whole sentence. On-device speech recognition routes the command to the right tracker — no Siri needed, nothing leaves your phone.
- **WidgetKit** — home-screen widgets for upcoming to-dos and the daily calorie ring.
- **HealthKit** — meals write to Apple Health as dietary energy, and **workouts recorded on Apple Watch / Apple Fitness are read back into the Workouts tab** (read-only, merged with what you log in Halo).
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
- **AI weekly insights** — *"how was my week?"* turns your 7-day trends into a plain-language insight + tip (also shown in Diet → Insights).
- **AI mood journaling** — *"I feel stressed about the deadline"* logs the mood, writes a short reflective note, and replies with a supportive line.
- **Notes → to-dos** — *"pull to-dos from my last note"* extracts the action items and creates them as tasks.

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
- **[documentation/RELEASE_v0.2.0.md](documentation/RELEASE_v0.2.0.md)** — what's new in v0.2.0.

## Project layout

```
project.yml                 XcodeGen project definition (source of truth)
assets/                     Source artwork (e.g. app icon master)
Halo/
  HaloApp.swift             App entry point
  Models/                   SwiftData models (TodoItem, Note, DietEntry, …)
  Features/                 SwiftUI screens, grouped by tab
  Services/                 Speech, voice routing, on-device AI (HaloIntelligence), calorie estimation, HealthKit, notifications
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
- **On-device voice + AI.** `SpeechRecognizer` captures speech; `VoiceCommandRouter.handle` routes it — AI-first via `HaloIntelligence` (Apple's `FoundationModels`), which can split one sentence into several commands, with a rule-based classifier as the offline fallback. All AI (intent routing, calorie/macro estimation, mood reflection, insights, suggestions, briefing wording, note→to-dos, workout-burn) is **on-device, availability-gated, and falls back to deterministic logic** — nothing leaves the phone. User-facing numbers are computed in Swift; the model only words them.
- **Apple Health.** Meals write as dietary energy; Apple Watch / Apple Fitness workouts are read back into the Workouts tab (`HealthKitService`).
- Settings are shared across targets via an App Group `UserDefaults` suite.

## License

Not yet specified.
