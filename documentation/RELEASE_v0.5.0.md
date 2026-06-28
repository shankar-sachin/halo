# Halo v0.5.0

The **Sleep Coach** release. Sleep was the one tracker without any AI — now it has an
on-device coach that turns your recent nights into a personalized, actionable tip. This
release also fixes a handful of correctness bugs found in a codebase audit. Everything stays
on-device with deterministic fallbacks, exactly as before.

> Builds on [v0.4.0](RELEASE_v0.4.0.md) (the iPad / universal release). See
> [RELEASE.md](RELEASE.md) for the versioning/tagging process.

## ✨ New: AI Sleep Coach

- **Personalized sleep tips** — open **Sleep** and tap **Get sleep tips**. Halo reads your
  last seven nights (your manual logs *and* Apple Watch / Apple Fitness sleep, de-duplicated),
  computes the stats in Swift — average, nights that met your goal, your shortest and longest
  night — and the on-device Apple Intelligence model words them into a warm, specific tip.
- **Numbers stay honest** — as with every Halo AI feature, the figures are computed
  deterministically; the model only phrases them. It never invents a number and never gives
  medical advice.
- **Works everywhere** — on a non-Apple-Intelligence device (or the simulator) it falls back
  to a templated tip built from the same stats (e.g. "averaging 6.8 h, about 70 min short of
  your 8 h goal — try winding down a little earlier"), so the card is always useful.

## 🐞 Fixes

- **Decimal water amounts by voice** — *"log 1.5 liters of water"* now logs **1,500 ml**.
  Previously the parser stopped at the decimal point and logged the wrong amount. *"750.5 ml"*
  and similar phrasings are handled too.
- **Water "glasses" count** — the *X of Y glasses* line now rounds both numbers the same way,
  so a custom goal like 1,900 ml no longer shows an impossible "8 of 7 glasses."
- **Sleep duration guard** — malformed Health samples with inverted timestamps can no longer
  subtract from a night's total; each sample's duration is floored at zero.

## 🛠️ Under the hood

- New `HaloIntelligence.sleepCoach(facts:)` helper follows the established pattern — gated on
  `SystemLanguageModel.default.availability`, wrapped in `try/catch`, with the caller supplying
  a deterministic fallback. New voice-parsing test cases cover the decimal water amounts.
- No changes to the data model, voice routing, Siri, or HealthKit sync beyond the above.

## Notes / requirements

- The **AI Sleep Coach requires an Apple Intelligence-eligible device**; elsewhere (including
  the simulator) it uses the deterministic fallback tip.
- Reading Apple Watch / Apple Fitness sleep needs a real device with Health permission granted;
  manually logged nights work everywhere.
