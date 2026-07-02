#!/usr/bin/env ruby
# frozen_string_literal: true

# Release-consistency checks for Halo, and the shared source of truth for every
# place the version number lives. Runs with the Ruby that ships with macOS —
# no gems required.
#
#   ruby scripts/verify_release.rb
#
# Exits non-zero if any check fails. Covers the mechanical half of the release
# checklist in documentation/RELEASE.md:
#   - project.yml agrees with itself (both targets, same version + build)
#   - documentation/RELEASE_v<current>.md exists and titles the right version
#   - README download links and docs list point at the current version
#   - the landing-page hero badge shows the current version
#   - the installed app icon is 1024x1024 with no alpha channel
module HaloRelease
  ROOT = File.expand_path("..", __dir__)

  PROJECT_YML  = File.join(ROOT, "project.yml")
  README       = File.join(ROOT, "README.md")
  LANDING_PAGE = File.join(ROOT, "docs", "index.html")
  NOTES_DIR    = File.join(ROOT, "documentation")
  APP_ICON     = File.join(ROOT, "Halo", "Resources", "Assets.xcassets",
                           "AppIcon.appiconset", "halo.png")

  SEMVER = /\d+\.\d+\.\d+/.freeze

  module_function

  def marketing_versions
    File.read(PROJECT_YML).scan(/MARKETING_VERSION: "(#{SEMVER})"/o).flatten
  end

  def build_numbers
    File.read(PROJECT_YML).scan(/CURRENT_PROJECT_VERSION: "(\d+)"/).flatten
  end

  def current_version
    marketing_versions.first
  end

  def notes_path(version)
    File.join(NOTES_DIR, "RELEASE_v#{version}.md")
  end

  # Each check returns nil on success or a failure message.

  def check_project_yml
    versions = marketing_versions.uniq
    builds = build_numbers.uniq
    return "no MARKETING_VERSION found in project.yml" if versions.empty?
    return "project.yml MARKETING_VERSION values disagree: #{versions.join(', ')}" if versions.size > 1
    return "project.yml CURRENT_PROJECT_VERSION values disagree: #{builds.join(', ')}" if builds.size > 1

    nil
  end

  def check_release_notes(version)
    path = notes_path(version)
    return "missing release notes: documentation/RELEASE_v#{version}.md" unless File.exist?(path)
    return "#{File.basename(path)} does not contain '# Halo v#{version}'" unless File.read(path).include?("# Halo v#{version}")

    nil
  end

  def check_readme(version)
    readme = File.read(README)
    problems = []
    stale = readme.scan(%r{(?:archive/refs/tags|releases/download)/v(#{SEMVER})}o).flatten.uniq - [version]
    problems << "download links still point at v#{stale.join(', v')}" unless stale.empty?
    problems << "docs list has no entry for RELEASE_v#{version}.md" unless readme.include?("RELEASE_v#{version}.md")
    problems.empty? ? nil : "README.md: #{problems.join('; ')}"
  end

  def check_landing_page(version)
    badge = File.read(LANDING_PAGE)[/class="badge".*/]
    return "docs/index.html: no hero badge found" unless badge
    return "docs/index.html: hero badge says '#{badge[/v#{SEMVER}/o]}', expected v#{version}" unless badge.include?("v#{version}")

    nil
  end

  def check_app_icon
    return "app icon missing at #{APP_ICON}" unless File.exist?(APP_ICON)

    info = `sips -g pixelWidth -g pixelHeight -g hasAlpha #{APP_ICON.shellescape} 2>/dev/null`
    width  = info[/pixelWidth: (\d+)/, 1]
    height = info[/pixelHeight: (\d+)/, 1]
    alpha  = info[/hasAlpha: (\w+)/, 1]
    return "could not read app icon metadata via sips" unless width && height && alpha
    return "app icon is #{width}x#{height}, expected 1024x1024" unless width == "1024" && height == "1024"
    return "app icon has an alpha channel (iOS rejects/blackens it) — regenerate per CLAUDE.md" unless alpha == "no"

    nil
  end

  def verify
    version = current_version
    checks = {
      "project.yml versions agree" => check_project_yml,
      "release notes exist for v#{version}" => check_release_notes(version),
      "README points at v#{version}" => check_readme(version),
      "landing page badge shows v#{version}" => check_landing_page(version),
      "app icon is 1024x1024, no alpha" => check_app_icon,
    }
    failures = 0
    checks.each do |name, failure|
      if failure
        failures += 1
        puts "  ✗ #{name}\n      #{failure}"
      else
        puts "  ✓ #{name}"
      end
    end
    failures
  end
end

require "shellwords"

if __FILE__ == $PROGRAM_NAME
  puts "Verifying release consistency for Halo v#{HaloRelease.current_version} " \
       "(build #{HaloRelease.build_numbers.first})"
  failures = HaloRelease.verify
  if failures.zero?
    puts "All checks passed."
  else
    puts "#{failures} check(s) failed."
    exit 1
  end
end
