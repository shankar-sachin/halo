# Release Process

How to cut a tagged release of Halo. Versions follow **semantic versioning** (`vMAJOR.MINOR.PATCH`).

## Where the version lives

Both values are in **`project.yml`** (never hand-edit the generated project):

```yaml
settings:
  base:
    MARKETING_VERSION: "0.2.0"     # user-facing version (CFBundleShortVersionString)
    CURRENT_PROJECT_VERSION: "1"   # build number (CFBundleVersion)
```

After editing, run `xcodegen generate`.

## Steps

1. **Bump the version** in `project.yml` (`MARKETING_VERSION`, and increment `CURRENT_PROJECT_VERSION`),
   then `xcodegen generate`.
2. **Verify** the build and tests are green (see [BUILD.md](BUILD.md)):
   ```bash
   xcodebuild -project Halo.xcodeproj -scheme Halo -sdk iphonesimulator \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
   xcodebuild -project Halo.xcodeproj -scheme Halo -sdk iphonesimulator \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
   ```
3. **Write release notes** at `documentation/RELEASE_vX.Y.Z.md` describing what changed since the
   previous tag (see `RELEASE_v0.2.0.md` for the format).
4. **Commit** the version bump + notes.
5. **Tag** the release and push:
   ```bash
   git tag -a v0.2.0 -m "Halo v0.2.0"
   git push origin v0.2.0
   ```
6. (Optional) Create a **GitHub release** from the tag, pasting in `RELEASE_vX.Y.Z.md`:
   ```bash
   gh release create v0.2.0 --title "Halo v0.2.0" --notes-file documentation/RELEASE_v0.2.0.md
   ```

## Generating the change list since the last tag

```bash
# Commits since the previous release tag
git log --oneline <previous-tag>..HEAD

# Files changed since the previous release tag
git diff --stat <previous-tag>..HEAD
```

> Note: as of v0.2.0 there was **no prior `0.1.0` tag** in the repo — v0.2.0's notes were assembled
> from the development history of this cycle. Create the baseline tag if you want future diffs to be
> exact: `git tag -a v0.1.0 <commit> -m "Halo v0.1.0"`.

## Building an archive for distribution (TestFlight / App Store)

Requires a valid `DEVELOPMENT_TEAM` and signing set up.

```bash
xcodebuild -project Halo.xcodeproj -scheme Halo \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/Halo.xcarchive archive

xcodebuild -exportArchive \
  -archivePath build/Halo.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/export
```

Or use Xcode: **Product → Archive**, then distribute from the Organizer.

## Release checklist

- [ ] `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` bumped in `project.yml`
- [ ] `xcodegen generate` run
- [ ] Build + tests green
- [ ] App icon is 1024×1024 with no alpha
- [ ] `documentation/RELEASE_vX.Y.Z.md` written
- [ ] Version bump + notes committed
- [ ] Tag created and pushed
- [ ] (Optional) GitHub release published
