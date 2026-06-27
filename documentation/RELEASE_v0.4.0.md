# Halo v0.4.0

The **iPad** release. Halo is now a **universal app** — the same voice-powered assistant and
ten trackers, built to run and look right on iPad as well as iPhone. Everything stays
on-device with deterministic fallbacks, exactly as before.

> Builds on [v0.3.0](RELEASE_v0.3.0.md) (the whole-day release). See [RELEASE.md](RELEASE.md)
> for the versioning/tagging process.

## 📱➡️🖥️ Universal app

- **iPhone + iPad** — Halo now installs and runs on iPad (`TARGETED_DEVICE_FAMILY` is universal).
  The on-device voice pipeline, Siri/App Intents, widgets, and HealthKit sync all work on both.
- **All orientations on iPad** — portrait, upside-down, and both landscapes are supported on
  iPad; iPhone stays portrait, as before.

## 📐 Layouts that fit the bigger screen

- **Readable columns** — the Home dashboard and every tracker (Diet, Water, Mood, Workouts,
  Pills, Sleep, Weight, Insights) cap their content to a comfortable, centered column instead
  of stretching cards and charts edge-to-edge on a large display. iPhone layouts are unchanged.
- **Adaptive dashboard grid** — the Home "Today" grid now flows into more columns on wide
  screens (≈3 on iPad) while keeping two columns on iPhone.

## 🛠️ Under the hood

- A single reusable `readableWidth()` modifier in the design system (`Theme.swift`) drives the
  column sizing, so the rule lives in one place and stays consistent across trackers.
- No behavioral changes to data, voice routing, AI, or HealthKit — this release is platform
  reach and layout only.

## Notes / requirements

- **Live Activities and Dynamic Island remain iPhone-only** — this is a platform limitation
  (iPadOS doesn't present Live Activities); the workout Live Activity is already guarded by
  `areActivitiesEnabled`, so it simply doesn't appear on iPad.
- HealthKit availability is checked at runtime (`HKHealthStore.isHealthDataAvailable()`), so
  Health sync degrades gracefully on devices without a Health store.
- AI features still require an **Apple Intelligence-eligible device**; elsewhere (including the
  simulator) they use deterministic fallbacks.
