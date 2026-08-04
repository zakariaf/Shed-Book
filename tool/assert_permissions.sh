#!/usr/bin/env bash
# tool/assert_permissions.sh — gate G1.
#
# Not a violation of decision #10 (one *source-scanning* gate): this reads a BUILT
# ARTEFACT and needs the Android toolchain, so it can never live in
# check_policy.dart. `13 §2.3` publishes it; this is that script with the three
# corrections N31-T03 recorded, and §2.3 is amended in the same commit — or
# release.yml copies the broken form.
set -euo pipefail

AAB="${1:-build/app/outputs/bundle/release/app-release.aab}"
EXPECTED="android/expected_permissions.txt"
BUNDLETOOL="${BUNDLETOOL:-bundletool.jar}"

# CORRECTION 1 — the three exit-2 conditions §2.3 documents, all three implemented.
# Exit 2 is "the gate could not run", which is still a FAILURE, never a skip: a
# missing bundletool that reported success would let a permission ship unseen.
[ -f "$EXPECTED" ]   || { echo "::error::$EXPECTED is missing — gate G0 has not been closed."; exit 2; }
[ -f "$BUNDLETOOL" ] || { echo "::error::$BUNDLETOOL is missing — the gate could not run."; exit 2; }
[ -f "$AAB" ]        || { echo "::error::$AAB is missing — build the release bundle first."; exit 2; }

java -jar "$BUNDLETOOL" dump manifest --bundle "$AAB" > merged-manifest.xml

# Split on '<' and select the uses-permission elements, then read their android:name.
# Do NOT filter on the substring "permission": com.android.vending.BILLING does not
# contain it, and that is the one entry a careless filter would silently drop.
# The '^uses-permission' prefix also catches <uses-permission-sdk-23>, deliberately.
#
# CORRECTION 2 — `set -o pipefail` turns an empty grep into a silent death. Capture,
# then decide, so "no uses-permission elements at all" is a named failure and not a
# script that stops mid-pipe with no message.
tr '<' '\n' < merged-manifest.xml \
  | grep '^uses-permission' \
  | grep -o 'android:name="[^"]*"' \
  | sed 's/.*"\(.*\)"/\1/' | sort -u > actual-permissions.txt || true

[ -s actual-permissions.txt ] || {
  echo "::error::No uses-permission elements were read from $AAB."
  echo "Either the bundle is not what you think it is, or bundletool's dump format moved."
  exit 2; }

# CORRECTION 3 — strip the inline provenance comment before comparing.
# 13 §2.2 REQUIRES every line of the expected file to name its contributing library,
# so every line carries a trailing `# <library>`. Stripping only whole-line comments
# leaves that text on the line and diffs it against a bare permission name — which is
# red on the first run, for a reason that has nothing to do with permissions.
# Strip the comment, then the trailing whitespace, then drop the empties.
#
# `test/policy/permission_set_test.dart` normalises the same file the same way, and
# says so: a parser more forgiving than this one would pass locally and go red here.
sed 's/#.*//' "$EXPECTED" | sed 's/[[:space:]]*$//' \
  | grep -v '^$' | sort -u > expected-sorted.txt

if ! diff -u expected-sorted.txt actual-permissions.txt; then
  echo "::error::The shipped bundle's permission set does not match $EXPECTED."
  echo "Lines starting '-' are missing; lines starting '+' were added by a dependency."
  echo "Find the contributor in build/app/outputs/logs/manifest-merger-release-report.txt (gate G4)."
  echo "Do NOT edit $EXPECTED to make this pass without understanding what changed."
  exit 1
fi
echo "G1 ok — permission set matches exactly."
