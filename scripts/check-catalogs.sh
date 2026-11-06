#!/usr/bin/env bash
# Fails when the main String Catalog breaks a rule (rules: docs/agents/testing.md, Localization catalog):
#   - a string has no translator comment (or a blank one)
#   - a string or one of its plural/device variations is in the state needs_review, in any language
#   - a string is missing, or not translated yet, in a required language
#   - a plural of a required language lacks a CLDR category of that language
#   scripts/check-catalogs.sh [repo root]    root defaults to the repository
#
# Checks App/Breathnest/Localizable.xcstrings. Safety.xcstrings has its own rule (#34) and is not read here.
# Languages required: the environment variable CATALOG_REQUIRED_LANGUAGES, a space separated list of
# en cs sk de fr es. Default "en": only English is filled in for now. #34 (localization in six languages) changes
# the default below to all six when the translations land.
# A string with "shouldTranslate": false (for example the exercise name 4-7-8) needs a comment, not translations.
# A string with no localizations at all is its own English value (the key), so it counts as English.
# Needs ruby (ships with macOS and the ubuntu runners), like scripts/check-docs.sh.
set -euo pipefail

root=${1:-$(git rev-parse --show-toplevel)}
[[ -d "$root" ]] || { echo "check-catalogs: no such directory '$root'" >&2; exit 1; }

# The languages the app is declared in, and the ones the check fills in. #34 changes the default to "en cs sk de fr es".
export CATALOG_REQUIRED_LANGUAGES=${CATALOG_REQUIRED_LANGUAGES-en}

ruby -E UTF-8 -rjson -e '
  root = ARGV[0]
  catalog = File.join(root, "App/Breathnest/Localizable.xcstrings")
  declared = %w[en cs sk de fr es]
  # CLDR plural categories of each language, as Xcode writes them.
  categories = {
    "en" => %w[one other], "de" => %w[one other],
    "cs" => %w[one few many other], "sk" => %w[one few many other],
    "fr" => %w[one many other], "es" => %w[one many other]
  }
  required = ENV["CATALOG_REQUIRED_LANGUAGES"].split
  bad = []

  (required - declared).each do |lang|
    bad << "CATALOG_REQUIRED_LANGUAGES names #{lang}, the app is declared in #{declared.join(" ")}"
  end
  required &= declared

  unless File.file?(catalog)
    bad << "App/Breathnest/Localizable.xcstrings does not exist"
  else
    begin
      data = JSON.parse(File.read(catalog))
    rescue JSON::ParserError => e
      bad << "App/Breathnest/Localizable.xcstrings is not valid JSON (#{e.message.lines.first.strip})"
    end
  end

  if data.is_a?(Hash)
    source = data["sourceLanguage"] || "en"
    strings = data["strings"] || {}

    # Every hash that holds a "state" under a node, with the path to it, for needs_review and "translated".
    units = lambda do |node, path, acc|
      case node
      when Hash
        acc << [path, node["stringUnit"]] if node["stringUnit"].is_a?(Hash)
        node.each { |k, v| units.call(v, path + [k], acc) unless k == "stringUnit" }
      end
      acc
    end

    # Every plural variation of a node: the list of its categories.
    plurals = lambda do |node, acc|
      return acc unless node.is_a?(Hash)
      node.each do |k, v|
        next unless v.is_a?(Hash)
        if k == "variations" && v["plural"].is_a?(Hash)
          acc << v["plural"].keys
          v["plural"].each_value { |category| plurals.call(category, acc) }
          v.each { |vk, vv| plurals.call(vv, acc) unless vk == "plural" }
        else
          plurals.call(v, acc)
        end
      end
      acc
    end

    strings.each do |key, entry|
      entry = {} unless entry.is_a?(Hash)
      label = key.inspect
      comment = entry["comment"]
      bad << "#{label} has no translator comment" if comment.to_s.strip.empty?

      locs = entry["localizations"].is_a?(Hash) ? entry["localizations"] : {}
      locs.each do |lang, loc|
        units.call(loc, [], []).each do |path, unit|
          where = ([lang] + path).join("/")
          bad << "#{label} [#{where}] is in the state needs_review" if unit["state"] == "needs_review"
        end
      end

      next if entry["shouldTranslate"] == false

      required.each do |lang|
        loc = locs[lang]
        if loc.nil?
          # No localizations at all: the key is the source string.
          bad << "#{label} [#{lang}] has no translation" unless lang == source && locs.empty?
          next
        end
        found = units.call(loc, [], [])
        if found.empty?
          bad << "#{label} [#{lang}] has no translation"
        end
        found.each do |path, unit|
          next if unit["state"] == "needs_review"
          if unit["state"] != "translated" || unit["value"].to_s.empty?
            bad << "#{label} [#{([lang] + path).join("/")}] is not translated yet"
          end
        end
        plurals.call(loc, []).each do |present|
          missing = categories[lang] - present
          bad << "#{label} [#{lang}] plural lacks #{missing.join(", ")}" unless missing.empty?
        end
      end
    end
  end

  unless bad.empty?
    warn bad.uniq.map { |b| "  - #{b}" }
    warn
    warn "  Every string needs a translator comment, no entry may be in review, and each required language needs"
    warn "  its translation and every plural category (en/de: one other, cs/sk: one few many other, fr/es: one many other)."
    warn "  Required languages: CATALOG_REQUIRED_LANGUAGES. Rules: docs/agents/testing.md, Localization catalog."
    exit 1
  end
  puts "The catalog has a comment on every string, nothing in review, and #{required.join(" ")} complete."
' "$root"
