# Halo v0.2.0

The **on-device AI** release. v0.2.0 turns Halo from a voice-logged tracker into an AI assistant that
understands natural language, answers questions, coaches you, and pulls in your Apple Watch workouts —
all on-device, with deterministic fallbacks so nothing breaks when Apple Intelligence isn't available.

> Baseline note: the repo had no `0.1.0` tag, so these notes cover the changes made in this development
> cycle relative to the previous (pre-AI) state of the app. See [RELEASE.md](RELEASE.md).

## ✨ New AI features (on-device, Apple `FoundationModels`)

- **AI understanding of every command** — natural phrasing now routes correctly across all voice paths
  (in-app, Siri, background). "I crushed a 5k this morning" → workout; "what's left for dinner?" → a
  question. A rule-based router remains the offline fallback.
- **Multi-command in one breath** — stack actions in one sentence: "I drank water and finished the
  dishes" runs both.
- **AI calorie *and macro* estimation** — meals now estimate protein/carbs/fat alongside calories
  (calorie estimation gains macros; shown per-entry in Diet).
- **Ask Halo (voice queries)** — "how many calories do I have left?", "what's on my to-do list?",
  "how much water today?" — answered from your data.
- **Daily briefing** — "how's my day?" gives a warm, AI-worded recap (exact numbers computed in Swift).
- **Weekly insights + coaching** — "how was my week?" and a new **AI insight card** in Diet → Insights
  turn your 7-day trends into a plain-language insight and tip.
- **AI meal suggestions** — "what should I eat?" suggests meals that fit your remaining budget (also a
  💡 button in the Diet tab).
- **AI mood journaling** — "I feel stressed about the deadline" logs the mood, writes a short reflective
  note, and replies with a supportive line.
- **Notes → to-dos** — "pull to-dos from my last note" extracts the action items and creates tasks.
- **AI workout calorie burn** — "log a 30 minute run" estimates calories burned (with a deterministic
  MET-based fallback) and stores it on the workout.

All AI is **on-device, availability-gated, and falls back to deterministic logic**; user-facing numbers
are computed in Swift and only worded by the model.

## ⌚ Apple Health / Apple Watch

- **Apple Watch & Apple Fitness workouts** are now read into the **Workouts** tab — merged read-only
  with what you log in Halo, including duration and calories burned, with pull-to-refresh.

## 🗣️ Voice — beyond logging

- **Edit & delete by voice** — "reschedule call mom to 7pm", "rename groceries to buy oat milk",
  "delete my last water".

## 🛠️ Fixes & polish

- **Onboarding now actually appears** on first launch (previously gated by a constant binding that
  never presented it).

## 🌐 Project & docs

- **Renamed the app to Halo** end-to-end — target, scheme, source folder, app entry point, and bundle
  identifiers (`com.sachi.halo`, `com.sachi.halo.widgets`, `com.sachi.halo.tests`); `xcodegen generate`
  now produces `Halo.xcodeproj`.
- **Landing page** added under `docs/` (GitHub Pages-ready) with an optimized demo video and a
  transparent circular favicon.
- **Documentation** added: [BUILD.md](BUILD.md), [RELEASE.md](RELEASE.md), and these notes; README and
  CLAUDE.md updated for the AI hub and HealthKit workout reads.

## Notes / requirements

- The AI features require an **Apple Intelligence-eligible device**; elsewhere (including the simulator)
  they use the deterministic fallbacks.
- Reading Apple Watch / Apple Fitness workouts requires a **real device** with HealthKit permission
  granted and a configured `DEVELOPMENT_TEAM` for signing.
