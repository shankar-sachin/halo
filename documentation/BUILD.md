# Building & Running Halo

Halo is an **XcodeGen** project: `project.yml` is the source of truth and the `.xcodeproj` is
generated (and git-ignored). Always regenerate after pulling or editing `project.yml`.

## Prerequisites

- **macOS** with **Xcode 26** (Swift 6, iOS 26 SDK)
- **XcodeGen** — `brew install xcodegen`
- For voice / Siri / HealthKit / Apple Intelligence features on a device: a configured
  `DEVELOPMENT_TEAM` (set it locally; do **not** commit a team ID)

## 1. Generate the Xcode project

```bash
xcodegen generate
```

> Run this once after cloning, and again any time you change `project.yml` or add/remove source files.

## 2a. Build & run in Xcode (recommended)

```bash
open Halo.xcodeproj
```

In Xcode: pick the **Halo** scheme and an iOS Simulator in the toolbar, then press **⌘R** to build
and run (⌘U to run tests).

## 2b. Build & run the simulator from the command line

```bash
# Build the app for the simulator
xcodebuild -project Halo.xcodeproj -scheme Halo \
  -configuration Debug -sdk iphonesimulator \
  -derivedDataPath build build

# List available simulators and boot one (any iOS 26 device)
xcrun simctl list devices available
xcrun simctl boot "iPhone 17 Pro"
open -a Simulator                       # opens the Simulator window

# Install and launch the built app on the booted simulator
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/Halo.app
xcrun simctl launch booted com.sachi.halo
```

To rebuild-and-run in one go against a named simulator, you can also use a destination:

```bash
xcodebuild -project Halo.xcodeproj -scheme Halo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## 3. Run the tests

```bash
xcodebuild -project Halo.xcodeproj -scheme Halo \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Tests use the **Swift Testing** framework (`@Test`); xcodebuild reports them under each suite
(the `Executed 0 tests` line is the legacy XCTest counter and can be ignored).

## 4. Run on a physical device

1. `open Halo.xcodeproj`, select your device, and set **Signing & Capabilities → Team**
   (or set `DEVELOPMENT_TEAM` locally in `project.yml` and regenerate).
2. Press **⌘R**.

A real device is required to fully exercise **Apple Intelligence** (on-device AI features fall back to
deterministic logic elsewhere), **Siri**, and **reading Apple Watch / Apple Fitness workouts** from
HealthKit.

## Useful resets

```bash
# Reset onboarding / clear app data on a simulator
xcrun simctl erase "iPhone 17 Pro"

# Regenerate the app icon (must be 1024×1024, no alpha)
sips -z 1024 1024 assets/halo.png --out Halo/Resources/Assets.xcassets/AppIcon.appiconset/halo.png
```

## Gotchas

- Never hand-edit the generated `Halo.xcodeproj` — change `project.yml` and re-run `xcodegen generate`.
- Don't commit `build/` or `Halo.xcodeproj/` (both git-ignored).
- The widget extension (`HaloWidgets`) compiles a subset of app sources (`Halo/Models`,
  `Halo/Support/AppSettings.swift`, `Halo/DesignSystem/Theme.swift`) — keep those buildable without
  app-only dependencies.
