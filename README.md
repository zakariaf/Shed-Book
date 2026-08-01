# Shed Book

An offline lambing notebook for a phone, built around one fifteen-second interaction — pick the
animal, tap what happened — performed at 03:20, one-handed, in a cold shed with a head torch and no
signal.

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

**`package:sqlite3` 3.5.0 downloads a prebuilt SQLite binary through a Dart build hook, and
`flutter pub get` does *not* trigger it — `flutter test` is the first command that does.** Measured
on 2026-08-01 by deleting `.dart_tool/hooks_runner/` and running the two commands in order:

| Command | `make` target | Trips the fetch? |
|---|---|---|
| `fvm flutter pub get` | — | **no** — `.dart_tool/hooks_runner/` is not even created |
| `fvm flutter analyze` | `make check` | **no** |
| `fvm flutter test` | **`make test`** | **yes** — writes `.dart_tool/hooks_runner/shared/sqlite3/build/download-<hash>/libsqlite3.dylib` |

So **`make test` is the first target that needs the network on a cold cache**, and `make check` never
does: its four steps are the two Python validators, `dart format` and `flutter analyze`.

The hook fetches from `https://github.com/simolus3/sqlite3.dart/releases/download/…` and verifies
the file against a sha256 compiled into the package, failing with *"Hash of downloaded file … is …,
expected …"* on a mismatch. It caches into `.dart_tool/`, so a warm working copy builds and tests in
plane mode; a **cold** cache is a fresh clone, a new pub cache, or anything after `flutter clean`.

So: on a fresh clone, run `fvm flutter test` once with a network before you get on the plane. **A
build-hook failure in plane mode is `pub get` and a download, not a regression in the offline
claim** — the claim is about the shipped app, which makes no network call at all. Decision-record
§3.4 #3 says the same thing in one line.

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
