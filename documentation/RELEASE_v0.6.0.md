# Halo v0.6.0

The **categories** release. The tab bar had grown to nine trackers — past what iOS comfortably
shows before spilling into a "More" overflow — and Weight and Sleep were buried behind Home
cards. This release reorganizes everything into **five categories**, promotes **Sleep** to a
first-class destination, and brings a round of iOS + iPadOS polish: a proper iPad sidebar,
single (no longer nested) navigation bars, and interactive Liquid Glass rows. No data-model,
voice, Siri, or HealthKit behavior changed — everything stays on-device with the same
deterministic fallbacks.

> Builds on [v0.5.0](RELEASE_v0.5.0.md) (the Sleep Coach release). See
> [RELEASE.md](RELEASE.md) for the versioning/tagging process.

## ✨ New: categorized navigation

The ten trackers now live under **five top-level destinations**, so the bar never overflows:

| Tab | Trackers |
| --- | --- |
| **Home** | the "Today" dashboard, unchanged in spirit |
| **Nutrition** | Diet · Water |
| **Health** | Workouts · Weight · **Sleep** · Pills |
| **Mind** | Mood · Habits |
| **Organize** | To-Do · Notes |

- **Sleep is first-class** — reachable in one tap from **Health** (with its AI Sleep Coach),
  instead of being tucked behind a Home card. Weight lives there too.
- **Each category is a hub** — a glance-and-go list that pushes into the individual tracker.
- **Home still deep-links everything** — every dashboard card taps straight through to its
  tracker, so the fast path is unchanged.

## 📱 iPad + iPhone polish

- **iPad sidebar** — the tab bar uses `.sidebarAdaptable`, so iPhone keeps a five-tab bar while
  iPad gets a sidebar (with the system show/hide toggle). One code path, both idioms.
- **Tap anywhere, with Liquid Glass** — category rows respond across the **whole** row, not just
  the chevron, and use the interactive iOS 26 Liquid Glass material so a press actually reacts.
  Home cards got the same full-card tap target.
- **Wider, readable layouts** — content is width-capped on iPad everywhere (the Habits list was
  the last holdout), and the Home grid flows to multiple columns.

## 🐞 Fixes

- **No more doubled navigation bars** — opening Weight or Sleep from Home previously pushed a
  view that carried its *own* `NavigationStack`, nesting two bars. Navigation is now centralized
  in the hubs/Home, so every tracker shows a single, correct navigation bar.

## 🛠️ Under the hood

- New `CategoryHubView` (+ a `TrackerLink` descriptor) owns the single `NavigationStack` each
  category pushes through; the ten tracker views dropped their own stacks accordingly.
- `RootTabView` collapses from nine tabs to five (`HomeTab` is now `home / nutrition / health /
  mind / organize`); `HomeView` cards switched from tab-switching to `NavigationLink` pushes and
  no longer need a selection binding.
- `GlassCard` gained an `interactive` option for whole-row Liquid Glass; new category tints
  (`nutritionTint`, `healthTint`, `mindTint`, `organizeTint`) reuse existing tracker hues.
- The **AI Sleep Coach is unchanged** — same on-device, availability-gated helper with its
  deterministic fallback; it just has a more prominent home now.

## Notes / requirements

- No new capabilities or permissions. Existing requirements (Xcode 26, iOS 26, Apple
  Intelligence for AI features with deterministic fallbacks elsewhere) are unchanged.
