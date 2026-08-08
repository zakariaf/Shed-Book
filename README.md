# Shed Book

[![CI](https://github.com/zakariaf/Shed-Book/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/zakariaf/Shed-Book/actions/workflows/ci.yml)

An offline lambing notebook for a phone, built around one fifteen-second interaction — pick the
animal, tap what happened — performed at 03:20, one-handed, in a cold shed with a head torch and no
signal.

This repository is public as a **worked example**: it is the companion to a video series on building
mobile applications with Claude Code. Everything is here on purpose — the decision record, the
thirteen engineering documents, the design system, all thirty-three epics with one file per task, and
the commit history that carries the measurements and the wrong turns. The interesting part is not the
finished code; it is `docs/` and `epics/` next to the commits that came out of them.

> Shed Book has no account, no server and no sync. The Android build ships without the internet
> permission, so the app itself cannot connect to anything. Your records only leave the phone when
> you deliberately export and share them.

## The toolchain

Flutter **3.44.8** stable / Dart **3.12.2**, pinned in `.fvmrc`. Never a floating channel, never a
caret, never a range — a bump re-runs the whole dependency resolution matrix, because the SDK pins
`meta`, `test_api` and `intl` exactly and those three pins are what make the dependency table in
`docs/research/00-tech-decisions.md` §5 the only resolvable combination.

```bash
dart pub global activate fvm     # once
fvm install                      # reads .fvmrc
fvm flutter --version            # 3.44.8 / 3.12.2
```

**`docs/research/00-tech-decisions.md` §5 is the only source of a version number in this project** —
not this README, not `pub add`, not memory.

## Which command first needs the network

`flutter pub get` needs a network and always has. Beyond that there is exactly one build-time fetch,
and it is worth knowing about before it surprises you offline:

**`package:sqlite3` 3.5.0 downloads a prebuilt SQLite binary through a Dart build hook.** Measured on
2026-08-01 on a fresh clone with an empty pub cache, blocking one command at a time by pointing the
proxy environment variables at a closed port — which is the block the hook itself honours, because it
installs `HttpClient.findProxyFromEnvironment`.

| Command | `make` target | Trips a fetch? |
|---|---|---|
| `fvm flutter pub get` | — | **yes, on an empty pub cache** — it is downloading the packages. With a warm `~/.pub-cache` it needs nothing, and `.dart_tool/hooks_runner/` is not even created |
| `fvm flutter analyze` | `make check` | **no** |
| `fvm flutter test` | **`make test`** | **yes** — one `libsqlite3.dylib` for the host, into `.dart_tool/hooks_runner/shared/sqlite3/build/download-<hash>/` |
| `fvm flutter build appbundle` | — | **yes, again** — three `libsqlite3.so`, one per Android ABI. **Different artefacts**, so having run `make test` does not warm this |
| `make gen` | `make gen` | **not yet measurable** — there is no database, so `drift_dev make-migrations` has nothing to do. N08 re-checks it |

So on a warm pub cache **`make test` is the first target that needs the network**, and `make check`
never does: its five steps are `dart tool/check_policy.dart`, the two Python validators, `dart format`
and `flutter analyze`. The gate is spelled without `run` for exactly that reason — `dart run` does an
implicit `pub get` and executes the package's build hooks, and was measured failing on a cold cache
with the network away at a pub.dev advisories fetch. Without `run` it exits 0 on the same tree.

The hook fetches from `https://github.com/simolus3/sqlite3.dart/releases/download/…` and verifies
the file against a sha256 compiled into the package, failing with *"Hash of downloaded file … is …,
expected …"* on a mismatch. It caches into `.dart_tool/hooks_runner/shared/`, so a warm working copy
builds and tests in plane mode — measured: the same `flutter test` that failed cold passes with the
network blocked once the artefact is there. A **cold** cache is a fresh clone, a new pub cache, or
anything after `flutter clean`, and `flutter clean` counts because it deletes `.dart_tool/` outright.

One more thing that looks like a hook failure and is not: **`flutter test` runs an implicit
`pub get`**, and pub contacts pub.dev for security advisories on a schedule of its own. A warm tree
can still fail offline on the first run after a resolution, with *"Got socket error trying to find
package …"* or an advisories URL in the message. `--no-pub` isolates it.

## The four integration journeys never run in GitHub Actions

**That absence is the design, not a gap.** `13 §4.2`: a `schedule:` trigger cannot drive a real
device, hosted runners' emulators are debug-mode only, and Firebase Test Lab wants an account and an
upload — the exact posture this product rejects (decision #117). And `continue-on-error: true` is a
named anti-pattern (`13 §4.6`): *if it is not worth failing on, delete it.* So there is no workflow,
and `test/policy/ci_jobs_test.dart` asserts there is none, because a rule everybody has forgotten the
reason for is a rule somebody helpfully reverses.

**"Nightly" in #117's words means a scheduled job on your own machine**, against a phone that is
plugged in anyway:

```bash
make integration DEVICE=<id>      # flutter devices, for the id
```

`DEVICE` is required and the target refuses without it: an unguarded run picks an arbitrary attached
device, and on a laptop with a simulator running that is the simulator — at which point journey 1's
*fresh install* proves nothing about a phone.

To run it nightly, a `launchd` agent on macOS (`~/Library/LaunchAgents/`, `StartCalendarInterval` at
an hour the phone is on the desk) or one `cron` line elsewhere:

```cron
0 2 * * *  cd /path/to/E01 && make integration DEVICE=<id> >> /tmp/shed-journeys.log 2>&1
```

Reported, never blocking. An integration suite in the blocking set is a suite that gets deleted the
first week it is flaky.

So: on a fresh clone, run `fvm flutter test` once — and `fvm flutter build appbundle --release` too
if you need Android — with a network, before you get on the plane. **A build-hook failure in plane
mode is `pub get` and a download, not a regression in the offline claim.** Every row above is about
the machine that builds the app; the shipped app makes no network call at all, and cannot, because
the release manifest carries no internet permission. Decision-record §3.4 #3 says the same in a line.

## Working in this repository

`CLAUDE.md` is the front door: the four non-negotiables, the vocabulary, the pinned stack and which
skill owns which change. The authority order is
`docs/research/00-tech-decisions.md` → `docs/engineering/CONVENTIONS.md` →
`docs/design/indelible.md` → the thirteen engineering documents → `.claude/skills/`.

`epics/` is the backlog: one folder per epic, one file per task, each carrying its own failing test,
its sources and its verification commands. `docs/calendar.md` is the ledger of every commitment that
needs somebody else's diary.

Open a pull request even when working alone — `.github/pull_request_template.md` is where the five
spec §12 safety questions get asked, and **never `gh pr create --fill`**, which takes the body from
the commit messages and skips the template entirely.

`main` takes no direct push. It requires a pull request with **`gate`, `codegen` and `test` all
green**, and it merges with a merge commit — squash and rebase are turned off at the repository, so
the per-task commits survive. They are the record: each one carries what was measured, what a
document got wrong, and what was left for the owner to rule on.

## Licence

**Apache License 2.0** — see [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).

Fork it, read it, teach from it, build on it, ship it. Two things the licence asks in return: keep
the copyright and `NOTICE` with any substantial portion you redistribute, and say what you changed.

Apache rather than MIT for two reasons that matter to a repository people are meant to copy from. It
carries an **express patent grant**, so anyone building on this gets that protection in writing
rather than by implication. And **section 6 does not grant the name**: "Shed Book" is the
application's name, not part of the grant. A derivative is welcome — under its own name.

© 2026 Zakaria Fatahi.
