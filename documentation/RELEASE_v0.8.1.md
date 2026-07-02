<div align="center">
  <img src="https://github.com/shankar-sachin/halo/blob/main/docs/assets/halo.png" alt="Halo Icon" width="20%">

  # Halo v0.8.1
  ### The automation release
</div>

### 🔗 [tinyurl.com/halo-voice](https://www.tinyurl.com/halo-voice)

The **automation** release. No app changes — this one is for the repo: two Ruby scripts in
`scripts/` now automate the mechanical half of cutting a release. `release.rb` bumps the
version everywhere it lives in one shot (this very release was cut with it), and
`verify_release.rb` is a CI-ready consistency check that catches version drift and the
app-icon alpha-channel gotcha before they ship. Both run on the Ruby that ships with macOS —
no gems, no Bundler, nothing to install.

> Builds on [v0.8.0](RELEASE_v0.8.0.md) (the polish release). See
> [RELEASE.md](RELEASE.md) for the versioning/tagging process.

## 💎 Release automation (Ruby)

- **`scripts/release.rb`** — `ruby scripts/release.rb X.Y.Z` bumps `MARKETING_VERSION` in both
  targets and increments `CURRENT_PROJECT_VERSION` in `project.yml`, rewrites the README
  download links, inserts the new release-notes entry in the README docs list, updates the
  landing-page hero badge, scaffolds `documentation/RELEASE_vX.Y.Z.md` from a template (never
  overwriting an existing file), runs `xcodegen generate`, and finishes with the full
  consistency verification. `--dry-run` previews every change without writing. It refuses
  non-semver input and versions that aren't newer than the current one. Writing the notes,
  committing, and tagging stay manual, by design.
- **`scripts/verify_release.rb`** — standalone checker (also the shared source of truth for
  every place the version lives, `require`d by `release.rb`). Verifies that both targets agree
  on version + build, the release notes exist and title the right version, the README download
  links and docs list point at the current version, the landing-page badge matches, and — via
  `sips` — that the installed app icon is **1024×1024 with no alpha channel** (the checklist
  item that has bitten before). Exits non-zero on any failure, so it drops straight into CI.

## 📝 Documentation

- **RELEASE.md** — new "Scripted (recommended)" section; step 1 of the release process now
  points at `release.rb` with the manual path kept as the fallback.
- **README** — `scripts/` added to the project layout.
- **CLAUDE.md** — build/release notes mention both scripts and warn to keep their patterns in
  sync if the version's home ever moves.

## 🛠️ Under the hood

- **Zero new dependencies** — both scripts run on macOS system Ruby (2.6+), standard library
  only.
- No app code, schema, capability, or permission changes; all 67 unit tests pass unchanged.

## Notes / requirements

- Existing app requirements (Xcode 26, iOS 26, Apple Intelligence for AI features with
  deterministic fallbacks elsewhere) are unchanged.
- The scripts are macOS-only in one spot: the icon check shells out to `sips`. Everything else
  is portable Ruby.

**Full Changelog**: https://github.com/shankar-sachin/halo/compare/v0.8.0...v0.8.1
