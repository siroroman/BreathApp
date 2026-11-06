#!/usr/bin/env bash
# Tests scripts/check-catalogs.sh against throwaway catalogs (rules: docs/agents/testing.md, Localization catalog).
# Usage: test-check-catalogs.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0
catalog=App/Breathnest/Localizable.xcstrings

# fixture <json of the "strings" object>: a tree with one catalog. Each case writes the entries it needs.
fixture() {
  rm -rf "$tmp/repo" && mkdir -p "$tmp/repo/App/Breathnest" && cd "$tmp/repo" || exit 1
  printf '{"sourceLanguage":"en","version":"1.0","strings":%s}\n' "$1" >"$catalog"
}

unit() { printf '{"stringUnit":{"state":"%s","value":"%s"}}' "$1" "$2"; }

# case_ <expected exit> <description> [required languages]: runs the check on the fixture as the case left it.
case_() {
  local want=$1 desc=$2 got
  if [[ $# -ge 3 ]]; then
    CATALOG_REQUIRED_LANGUAGES=$3 "$root/scripts/check-catalogs.sh" "$tmp/repo" >"$tmp/out" 2>&1
  else
    env -u CATALOG_REQUIRED_LANGUAGES "$root/scripts/check-catalogs.sh" "$tmp/repo" >"$tmp/out" 2>&1
  fi
  got=$?
  if [[ "$got" -ne "$want" ]]; then
    printf 'FAIL (want %s, got %s): %s\n' "$want" "$got" "$desc"
    failed=1
  fi
}

# expect_message <text> <description>: the output of the last case names the offence.
expect_message() {
  if ! grep -q -- "$1" "$tmp/out"; then
    printf 'FAIL: %s (output did not contain "%s")\n' "$2" "$1"
    failed=1
  fi
}

en=$(unit translated "Hello")
cs=$(unit translated "Ahoj")

fixture "{\"hello\":{\"comment\":\"Greeting on the placeholder screen\",\"localizations\":{\"en\":$en}}}"
case_ 0 "clean catalog, only English required"

fixture "{\"hello\":{\"comment\":\"Greeting\",\"localizations\":{\"en\":$en,\"cs\":$cs}}}"
case_ 0 "clean catalog with Czech, English and Czech required" "en cs"

fixture "{\"hello\":{\"comment\":\"Greeting\",\"localizations\":{\"en\":$en}}}"
case_ 1 "Czech required and missing" "en cs"
expect_message "hello" "names the key"
expect_message "cs" "names the language"

fixture "{\"hello\":{\"comment\":\"Greeting\"}}"
case_ 0 "key with no localizations is the source string, English comes from the key" "en"

fixture "{\"hello\":{\"comment\":\"Greeting\",\"localizations\":{\"en\":$en,\"cs\":$(unit new "Ahoj")}}}"
case_ 1 "Czech value not translated yet (state new)" "en cs"

fixture "{\"hello\":{\"comment\":\"Greeting\",\"localizations\":{\"en\":$en,\"de\":$(unit needs_review "Hallo")}}}"
case_ 1 "needs review in a language that is not required"
expect_message "needs_review\|needs review" "names the state"

fixture "{\"hello\":{\"comment\":\"Greeting\",\"localizations\":{\"en\":$(unit needs_review "Hello")}}}"
case_ 1 "needs review in English"

fixture "{\"hello\":{\"localizations\":{\"en\":$en}}}"
case_ 1 "no translator comment"
expect_message "comment" "names the missing comment"

fixture "{\"hello\":{\"comment\":\"   \",\"localizations\":{\"en\":$en}}}"
case_ 1 "blank translator comment"

plural() {
  # plural <language> <category...>: a plural variation with the given categories.
  local lang=$1 out="" sep="" c
  shift
  for c in "$@"; do out+="$sep\"$c\":$(unit translated "$c")"; sep=","; done
  printf '"%s":{"variations":{"plural":{%s}}}' "$lang" "$out"
}

fixture "{\"cycles\":{\"comment\":\"Number of cycles\",\"localizations\":{$(plural en one other)}}}"
case_ 0 "English plural with one and other"

fixture "{\"cycles\":{\"comment\":\"Number of cycles\",\"localizations\":{$(plural en one)}}}"
case_ 1 "English plural without other"
expect_message "other" "names the missing category"

fixture "{\"cycles\":{\"comment\":\"Number of cycles\",\"localizations\":{$(plural en one other),$(plural cs one few other)}}}"
case_ 1 "Czech plural without many" "en cs"
expect_message "many" "names the missing category"

fixture "{\"cycles\":{\"comment\":\"Number of cycles\",\"localizations\":{$(plural en one other),$(plural cs one few many other)}}}"
case_ 0 "Czech plural with all four categories" "en cs"

fixture "{\"cycles\":{\"comment\":\"Number of cycles\",\"localizations\":{$(plural en one other),$(plural sk one few many other)}}}"
case_ 0 "Slovak plural with all four categories" "en sk"

fixture "{\"cycles\":{\"comment\":\"Number of cycles\",\"localizations\":{$(plural en one other),$(plural fr one other)}}}"
case_ 1 "French plural without many" "en fr"

fixture "{\"cycles\":{\"comment\":\"Number of cycles\",\"localizations\":{$(plural en one other),$(plural es one many other),$(plural de one other)}}}"
case_ 0 "Spanish with many, German with one and other" "en es de"

fixture "{\"cycles\":{\"comment\":\"Number of cycles\",\"localizations\":{$(plural en one other),$(plural cs one)}}}"
case_ 0 "plural of a language that is not required is not checked"

fixture "{\"cycles\":{\"comment\":\"Number of cycles\",\"localizations\":{\"en\":{\"variations\":{\"plural\":{\"one\":$(unit needs_review "x"),\"other\":$en}}}}}}"
case_ 1 "needs review inside a plural category"

fixture "{\"cycles\":{\"comment\":\"Number of cycles\",\"localizations\":{\"en\":{\"variations\":{\"plural\":{\"one\":$en,\"other\":$(unit new "")}}}}}}"
case_ 1 "plural category not translated yet"

fixture "{\"4-7-8\":{\"comment\":\"Name of an exercise, never translated\",\"shouldTranslate\":false}}"
case_ 0 "string that is not translated is exempt from the translation check" "en cs"

fixture "{\"4-7-8\":{\"shouldTranslate\":false}}"
case_ 1 "string that is not translated still needs a comment"

fixture "{\"hello\":{\"comment\":\"Greeting\",\"localizations\":{\"en\":$en}},\"bye\":{\"localizations\":{\"en\":$en}}}"
case_ 1 "one good and one bad entry"
expect_message "bye" "names the bad entry"

fixture "{}"
case_ 0 "empty catalog"

fixture "{}"
printf '{ not json' >"$catalog"
case_ 1 "invalid JSON"

fixture "{}"
rm "$catalog"
case_ 1 "catalog is missing"

fixture "{}"
case_ 1 "unknown language in the setting" "en xx"
expect_message "xx" "names the unknown language"

fixture "{\"hello\":{\"localizations\":{\"en\":$en}}}"
case_ 1 "failure message"
if ! grep -q 'docs/agents/testing.md' "$tmp/out"; then
  echo "FAIL: the message should name docs/agents/testing.md"
  failed=1
fi

if [[ $failed -eq 0 ]]; then echo "all check-catalogs cases passed"; fi
exit $failed
