# CLAUDE.md

Guidance for Claude Code (and other AI agents) working in this repository.

## What this is

**Halo Lifestyle** — a voice-powered iOS 26 lifestyle app. One conversational assistant ("Halo") fronts eight trackers: To-Do, Notes, Diet, Habits, Water, Workouts, Mood, and Pills. Display name is "Halo Lifestyle"; the app target is `Todo` for historical reasons.

## Build & run

This is an **XcodeGen** project. `project.yml` is the source of truth; the `.xcodeproj` is generated and git-ignored.

```bash
xcodegen generate                                                   # regenerate the project after editing project.yml
xcodebuild -project Todo.xcodeproj -scheme Todo -sdk iphonesimulator # build
xcodebuild -project Todo.xcodeproj -scheme Todo \
  -sdk iphonesimulator test                                         # run tests (TodoTests)
```

- **Always edit `project.yml`** to change targets, build settings, capabilities, Info.plist keys, or entitlements — never hand-edit the generated `.xcodeproj`.
- After changing `project.yml`, run `xcodegen generate` before building.
- Toolchain: Xcode 26, Swift 6, iOS 26 deployment target. Swift 6 strict concurrency is on (`SWIFT_APPROACHABLE_CONCURRENCY`).

## Targets

- **Todo** — main app.
- **HaloWidgets** — WidgetKit extension. It compiles a *subset* of the app's sources directly: `Todo/Models`, `Todo/Support/AppSettings.swift`, and `Todo/DesignSystem/Theme.swift`. If you change those, keep them buildable in the extension context (no app-only dependencies).
- **TodoTests** — unit tests, depend on the Todo target.

## Architecture

- **SwiftUI + SwiftData.** Models live in `Todo/Models/`.
- **One shared store.** `DataController.shared.container` (`Todo/Persistence/DataController.swift`) is a single `ModelContainer` backed by the **App Group** `group.com.sachi.halo`. The app, the widgets, and the Siri/App Intents all use it, so an entry created by Siri appears in the running app immediately. Adding a new `@Model` means adding it to the `Schema` array here.
- **Voice pipeline (on device).** `SpeechRecognizer` → `VoiceCommandRouter` → tracker-specific actions (`CommandActions`, `MealLogger`, etc.). `HaloListener` handles optional background listening (gated behind the `listenInBackground` setting and the `audio` background mode). Keep voice handling on-device — no network calls.
- **App Intents / Siri** in `Todo/Intents/` write through the same shared container.
- **Settings** are shared across targets via an App Group `UserDefaults` suite — see `Todo/Support/AppSettings.swift` (`SettingsKey`, `SettingsDefault`, `.shared` store).
- **Design system** in `Todo/DesignSystem/` (`Theme.swift`, `GlassCard.swift`).

## Conventions

- Features are organized by tab under `Todo/Features/<Feature>/`.
- Match the surrounding SwiftUI style; prefer existing components in `DesignSystem/` over ad-hoc styling.
- HealthKit, Speech, Siri, and Microphone all have usage-description strings defined in `project.yml` — if you add a capability, add its entitlement and Info.plist key there.

## App icon

The master artwork is `assets/halo.png`. The installed icon is `Todo/Resources/Assets.xcassets/AppIcon.appiconset/halo.png` — it must be **1024×1024 with no alpha channel** (iOS rejects/blackens icons with alpha). Regenerate with:

```bash
sips -z 1024 1024 assets/halo.png --out Todo/Resources/Assets.xcassets/AppIcon.appiconset/halo.png
```

## Gotchas

- Voice, Siri, and HealthKit need granted permissions and a configured `DEVELOPMENT_TEAM`; they won't fully work in a fresh simulator without setup.
- `DEVELOPMENT_TEAM` is intentionally empty in `project.yml` — set it locally for device signing; don't commit a team ID.
- Don't commit `build/` or the generated `Todo.xcodeproj/` (both git-ignored).
