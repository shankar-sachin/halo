<div align="center">
  <img src="https://github.com/shankar-sachin/halo/blob/main/docs/assets/halo.png" alt="Halo Icon" width="20%">

  # Halo v0.8.0
  ### The polish release
</div>

### 🔗 [tinyurl.com/halo-voice](https://www.tinyurl.com/halo-voice)

The **polish** release. Voice Mode gets a proper identity: a new **waveform glyph**
(`HaloWaveform`) replaces the plain microphone on the tab-bar button, and the Voice Mode orb
now shows **animated, bouncing waveform bars** in a blue→purple gradient while Halo listens.
Onboarding's diet-preference chips got a **legibility fix** — selected chips now use a solid
tinted fill with white text instead of tint-on-tint. The README and landing page were brought
fully up to date (including features shipped in v0.6.0/v0.7.0 that never made it to the site),
and the license is now correctly documented as **Apache 2.0**.

> Builds on [v0.7.0](RELEASE_v0.7.0.md) (the everywhere release). See
> [RELEASE.md](RELEASE.md) for the versioning/tagging process.

## 🎙️ Voice Mode, redesigned

- **New waveform glyph** — `HaloWaveform` (in `Halo/DesignSystem/`) draws seven symmetric
  rounded bars, tallest in the middle, in the style of the system sound-recorder icon. It takes
  its color from `foregroundStyle` and its size from `frame`, so it drops in anywhere.
- **Tab-bar Voice Mode button** — the bottom-accessory "Talk to Halo" button now shows white
  waveform bars inside its existing gradient circle instead of `mic.fill`.
- **Living listening orb** — while Halo listens, the Voice Mode orb shows the waveform in a
  blue→purple gradient with the bars gently bouncing on a staggered delay (recorder-style).
  The bars freeze while processing; result and permission-denied states keep their symbols
  (`resultAction.systemImage` / `mic.slash.fill`).

## 🎨 Onboarding & Settings fixes

- **Diet-preference chips are legible again** — selected eating-style and allergen chips used
  tint-colored text on a same-tint glass background (mint-on-mint, rose-on-rose), which was
  nearly unreadable. Selected chips now get a **full-strength tinted glass fill with white
  semibold text**, and the redundant colored stroke ring is gone. Unselected chips stay plain
  glass with primary text, so the selected state reads instantly. Because `DietTypeChips` /
  `AllergenChips` are shared, the fix applies both in onboarding and in Settings → Diet.

## 📝 Documentation & site

- **README** — Downloads now point at v0.8.0; the License section now correctly says
  **Apache 2.0** (the LICENSE file shipped in v0.7.0 but the README still said "Not yet
  specified"); voice/feature lists refreshed.
- **Landing page** — caught up with everything since v0.6.0: the **habit streak widget**,
  the **Complete a Habit / Mark Pill Taken** Control Center controls, the **monthly digest**,
  **Weight / Sleep / Pills App Intents** (full Shortcuts parity), **diet categories**
  (food / caffeine / alcohol), **macros** in the Diet card, the Home **Activity card**
  (steps + active energy), and the **Reflect** / **Extract To-Dos** in-app AI buttons.
- **CLAUDE.md** — design-system notes now mention `HaloWaveform`.

## 🛠️ Under the hood

- No schema, capability, or permission changes. No new AI calls — this release is pure UI and
  documentation.
- All existing unit tests pass unchanged (67 tests).

## Notes / requirements

- Existing requirements (Xcode 26, iOS 26, Apple Intelligence for AI features with
  deterministic fallbacks elsewhere) are unchanged.
- The animated listening orb is best seen on a device or simulator with microphone/speech
  permission granted, since the orb animates while actually listening.

**Full Changelog**: https://github.com/shankar-sachin/halo/compare/v0.7.0...v0.8.0
