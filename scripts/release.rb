#!/usr/bin/env ruby
# frozen_string_literal: true

# Bumps Halo to a new version everywhere the version lives, in one shot:
#
#   ruby scripts/release.rb 0.9.0 [--dry-run]
#
#   - project.yml            MARKETING_VERSION (both targets) + CURRENT_PROJECT_VERSION (+1)
#   - README.md              download links + a docs-list entry for the new release notes
#   - docs/index.html        hero badge version
#   - documentation/         scaffolds RELEASE_v<new>.md from a template
#
# then regenerates the Xcode project (xcodegen) and finishes with the same
# consistency checks as scripts/verify_release.rb. Runs on macOS system Ruby,
# no gems required. --dry-run reports what would change without writing.
#
# What stays manual, by design: writing the actual release notes, committing,
# and tagging — see documentation/RELEASE.md.

require_relative "verify_release"

def fail_with(message)
  warn "error: #{message}"
  warn "usage: ruby scripts/release.rb <new-version> [--dry-run]"
  exit 1
end

dry_run = ARGV.delete("--dry-run") ? true : false
new_version = ARGV.shift
fail_with("missing new version") unless new_version
fail_with("'#{new_version}' is not a MAJOR.MINOR.PATCH version") unless new_version =~ /\A#{HaloRelease::SEMVER}\z/

current = HaloRelease.current_version
fail_with("could not read the current version from project.yml") unless current
fail_with("#{new_version} is not newer than the current #{current}") unless
  Gem::Version.new(new_version) > Gem::Version.new(current)

current_build = HaloRelease.build_numbers.first.to_i
new_build = current_build + 1

puts "#{dry_run ? '[dry-run] ' : ''}Halo v#{current} (build #{current_build}) → v#{new_version} (build #{new_build})"

changes = [] # [path, new content]

# --- project.yml: version + build number, both targets
yml = File.read(HaloRelease::PROJECT_YML)
yml = yml.gsub(/MARKETING_VERSION: "#{Regexp.escape(current)}"/, %(MARKETING_VERSION: "#{new_version}"))
         .gsub(/CURRENT_PROJECT_VERSION: "#{current_build}"/, %(CURRENT_PROJECT_VERSION: "#{new_build}"))
changes << [HaloRelease::PROJECT_YML, yml]

# --- README.md: download links + docs list
readme = File.read(HaloRelease::README)
readme = readme.gsub("archive/refs/tags/v#{current}", "archive/refs/tags/v#{new_version}")
               .gsub("releases/download/v#{current}/", "releases/download/v#{new_version}/")
docs_anchor = /^- \*\*\[documentation\/RELEASE\.md\].*$/
new_entry = "- **[documentation/RELEASE_v#{new_version}.md](documentation/RELEASE_v#{new_version}.md)** — what's new in v#{new_version}."
if readme.include?("RELEASE_v#{new_version}.md")
  # docs list already has the entry; leave it alone
elsif readme =~ docs_anchor
  readme = readme.sub(docs_anchor) { |line| "#{line}\n#{new_entry}" }
else
  warn "warning: README docs list anchor not found — add the RELEASE_v#{new_version}.md entry by hand"
end
changes << [HaloRelease::README, readme]

# --- docs/index.html: hero badge
landing = File.read(HaloRelease::LANDING_PAGE)
landing = landing.sub(/(class="badge".*)v#{Regexp.escape(current)}/) { "#{Regexp.last_match(1)}v#{new_version}" }
changes << [HaloRelease::LANDING_PAGE, landing]

# --- documentation/RELEASE_v<new>.md: scaffold (never overwrites)
notes_path = HaloRelease.notes_path(new_version)
unless File.exist?(notes_path)
  notes = <<~NOTES
    <div align="center">
      <img src="https://github.com/shankar-sachin/halo/blob/main/docs/assets/halo.png" alt="Halo Icon" width="20%">

      # Halo v#{new_version}
      ### <one-line codename>
    </div>

    ### 🔗 [tinyurl.com/halo-voice](https://www.tinyurl.com/halo-voice)

    <!-- One-paragraph summary of the release. -->

    > Builds on [v#{current}](RELEASE_v#{current}.md). See
    > [RELEASE.md](RELEASE.md) for the versioning/tagging process.

    ## ✨ What's new

    - <!-- feature -->

    ## Notes / requirements

    - Existing requirements (Xcode 26, iOS 26, Apple Intelligence for AI features with
      deterministic fallbacks elsewhere) are unchanged.

    **Full Changelog**: https://github.com/shankar-sachin/halo/compare/v#{current}...v#{new_version}
  NOTES
  changes << [notes_path, notes]
end

changes.each do |path, content|
  rel = path.sub("#{HaloRelease::ROOT}/", "")
  existed = File.exist?(path)
  if existed && File.read(path) == content
    puts "  = #{rel} (no change needed)"
  elsif dry_run
    puts "  ~ #{rel} (would #{existed ? 'update' : 'create'})"
  else
    File.write(path, content)
    puts "  ✎ #{rel} #{existed ? 'updated' : 'created'}"
  end
end

if dry_run
  puts "[dry-run] skipped xcodegen and verification; no files were written."
  exit 0
end

# --- regenerate the Xcode project so the new version lands in the build
if system("which xcodegen > /dev/null 2>&1")
  puts "Running xcodegen generate…"
  system("xcodegen generate", chdir: HaloRelease::ROOT) || fail_with("xcodegen generate failed")
else
  warn "warning: xcodegen not installed — run 'xcodegen generate' before building"
end

puts "\nVerifying:"
failures = HaloRelease.verify
exit 1 unless failures.zero?

puts <<~NEXT

  Done. Next steps (see documentation/RELEASE.md):
    1. Write the release notes in documentation/RELEASE_v#{new_version}.md
    2. Build + test:  xcodebuild -project Halo.xcodeproj -scheme Halo -sdk iphonesimulator test
    3. Commit, then: git tag -a v#{new_version} -m "Halo v#{new_version}" && git push origin v#{new_version}
NEXT
