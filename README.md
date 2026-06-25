# Halo Lifestyle

A voice-powered lifestyle app for iOS 26 that bundles eight everyday trackers behind one conversational assistant. Speak a command — *"Halo, add a to-do"*, *"log a coffee"*, *"I drank a glass of water"* — and Halo turns it into the right entry, on device.

> Display name: **Halo Lifestyle** · Spoken name: **Halo** · Bundle ID: `com.sachi.halo`

## Features

Eight tabs, one shared data store:

| Tab | What it does |
| --- | --- |
| **To-Do** | Tasks with due dates, recurrence, and notifications |
| **Notes** | Quick text notes |
| **Diet** | Meal logging with calorie estimation + a daily calorie ring; syncs to the Health app |
| **Habits** | Daily habit check-ins |
| **Water** | Water intake tracking |
| **Workouts** | Workout logging |
| **Mood** | Mood check-ins |
| **Pills** | Medication / supplement logging |

Plus:

- **Talk to Halo** — a voice mode accessible from every tab. On-device speech recognition routes spoken commands to the right tracker.
- **Siri & App Intents** — add to-dos, notes, and meals by voice without opening the app.
- **WidgetKit** — home-screen widgets for upcoming to-dos and the daily calorie ring.
- **HealthKit** — dietary energy reads/writes keep daily totals in sync with Apple Health.
- **App Group** — the app, the widgets, and the Siri intents share one SwiftData store (`group.com.sachi.halo`), so an entry created by Siri shows up everywhere immediately.

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
open Todo.xcodeproj

# Or build from the command line
xcodebuild -project Todo.xcodeproj -scheme Todo -sdk iphonesimulator
```

> The `.xcodeproj` is **generated** and git-ignored. After cloning, run `xcodegen generate` before building. Edit `project.yml` — not the project file — to change targets, settings, or capabilities.

Voice features (speech recognition, Siri, microphone) and HealthKit require a real device or a simulator with the relevant permissions granted, and a configured `DEVELOPMENT_TEAM` for signing.

## Project layout

```
project.yml                 XcodeGen project definition (source of truth)
assets/                     Source artwork (e.g. app icon master)
Todo/
  TodoApp.swift             App entry point
  Models/                   SwiftData models (TodoItem, Note, DietEntry, …)
  Features/                 SwiftUI screens, grouped by tab
  Services/                 Speech, voice routing, calorie estimation, HealthKit, notifications
  Intents/                  App Intents / Siri shortcuts
  Persistence/              Shared SwiftData ModelContainer
  DesignSystem/             Theme + glass UI components
  Support/                  AppSettings, shared defaults
  Resources/                foods.json, Assets.xcassets (incl. AppIcon)
HaloWidgets/                WidgetKit extension (shares Models + Theme + AppSettings)
TodoTests/                  Unit tests
```

## Targets

- **Todo** — the main iOS app
- **HaloWidgets** — WidgetKit app extension
- **TodoTests** — unit test bundle

## Architecture notes

- **SwiftUI + SwiftData** throughout. A single shared `ModelContainer` (`DataController.shared`) lives in an App Group container so the app, widgets, and Siri intents all read and write the same database.
- **On-device voice.** `SpeechRecognizer` and `VoiceCommandRouter` parse spoken input and dispatch to the right tracker — no network round-trip.
- Settings are shared across targets via an App Group `UserDefaults` suite.

## License

Not yet specified.
