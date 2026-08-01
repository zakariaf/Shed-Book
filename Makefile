# Makefile — the local mirror of CI.
#
# CI does NOT run make: .github/workflows/ci.yml spells its steps out. So this
# file and that file are two copies of one list, kept in step by hand — which is
# why test/policy/makefile_test.dart asserts these recipes, ci_jobs_test.dart
# asserts those steps, and one case asserts the two spell the same filters.
#
# Recipe lines are indented with a TAB. A space-indented recipe fails with
# "missing separator" and the message names the line, not the cause.

# ?= and not =, so a caller can override. `fvm flutter` is right on the
# developer's machine and wrong on CI, where subosito/flutter-action installs
# Flutter directly and there is no FVM.
FLUTTER ?= fvm flutter
DART    ?= fvm dart

# The tags excluded from the broad run, and why each one is here (12 §11.2):
#   golden    verified only on the pinned macOS runner
#   uk-zone   asserts its own process offset and fails loudly under any other
#             zone — it runs in the TZ=Europe/London command below, which is the
#             only place it can pass
#   calendar  N00's ledger, red by design until N32 closes the last commitment
BROAD_EXCLUDE ?= golden || uk-zone || calendar

.PHONY: gen check validate test goldens goldens-update perf integration all

gen:                      ## codegen + migration artefacts. The ONLY way generated code changes
	$(DART) run build_runner build --delete-conflicting-outputs
	$(DART) run drift_dev make-migrations

check:                    ## cheapest failure first: <1s, then seconds, then tens of seconds
	$(MAKE) validate
	$(DART) format --output=none --set-exit-if-changed .
	$(FLUTTER) analyze --fatal-infos --fatal-warnings

validate:                 ## the two doc validators, on their own, for a docs-only change
	python3 tool/validate_skills.py
	python3 tool/validate_epics.py

test:                     ## 12 §11.4. Two commands, because TZ is per-process.
	$(FLUTTER) test --exclude-tags "$(BROAD_EXCLUDE)" --test-randomize-ordering-seed random --coverage
	TZ=Europe/London $(FLUTTER) test --tags uk-zone

goldens:                  ## VERIFY against the committed PNGs. Never a per-PR gate (#116)
	$(FLUTTER) test --tags golden

goldens-update:           ## RE-BASELINE. A deliberate act, its own commit (12 §8.5)
	$(FLUTTER) test --tags golden --update-goldens

perf:                     ## decision #126 — needs a real device, profile mode
	$(FLUTTER) run --profile --trace-startup -d $(DEVICE)

integration:              ## decision #117 — four journeys, real device, reported not blocking
	$(FLUTTER) test integration_test -d $(DEVICE)

all: gen check test       ## the full local pass, in the order a developer actually wants it
