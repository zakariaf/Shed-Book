# N21-T06 — `ShareService` — the share sheet and nowhere else

| | |
|---|---|
| **Epic** | [N21 — Export: CSV, PDF and share](epic.md) · `00-README` §9 step 8 (1 of 3) |
| **Task** | 6 of 8 |
| **Depends on** | N21-T05 |
| **Commit** | one commit · `feat(gateway): ShareService, the share sheet and nowhere else` |

## 1. Why this task exists

Delivery through the system share sheet and **nowhere else**, always as a file path. This
is the boundary of the offline claim's tier 3: the share sheet is another process, and the public
wording says so.

`08 §5` calls it *"the highest-stakes non-database code path in the app"*, and the reason is that it
is the only way anything a shepherd has recorded reaches anywhere else. There is no "save to Files"
path of our own, nothing is written to a user-visible folder, and nothing is opened in place.

This is also where the app learns whether an export actually happened, which is what the end-of-day
banner in T08 depends on. Getting the three-way result wrong makes the app's one safety nag either
useless or a liar.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/08-platform-integration.md` | **§5** (`ShareService` printed in full, `ShareOutcome`, the four operational rules, the `sharePositionOrigin` requirement, and the `last_exported_at` three-way) · **§1.1–§1.2** (the gateway rule; *"no plugin type crosses a gateway's boundary in either direction"*; `_confinedPackages` and `layer.plugin_share_plus`) · §8.3–§8.4 (the final Android and iOS key sets — this task changes neither) · §11 (who writes `last_exported_at`) | the class, member for member, and the rule that keeps the plugin behind it |
| `docs/engineering/09-export-formats.md` | **§8.1** (the share sheet and only the share sheet; the four operational rules; file naming from `seasons.year`, never `seasons.label`; `getTemporaryDirectory()`) · **§8.3** (`lastExportedAt`: stamp on success **and** unavailable, never on dismissed; never before the sheet opens) · §8.2 (there is no in-app print dialog and the screen does not pretend otherwise) · §8.4 (media is a separate share, batched at 50) · §10 item 5 | what may be shared, in what form, and what the result means |
| `docs/research/00-tech-decisions.md` | **§5.1** (`share_plus` **13.3.0**, fluttercommunity.dev, verified — the only source of that number; requires Flutter ≥ 3.38.1) · **#80** (`SharePlus.instance.share(ShareParams(...))`; always a path; `sharePositionOrigin` required on iPad) · #112 (hand-written fakes for all six gateways) · #123/#124 (no telemetry) | the version, the API, and the fake |
| `docs/engineering/12-testing.md` | **§4.2** (`FakeShareService`, what it records, and its two tripwires) · **§5.1** (`shedContainer` printed — the override list this task edits) · §5.3 (the closed twelve-file `test/support/` list) · §4.1 (*"a fake is a real implementation"*) | the fake and where it plugs in |
| `docs/engineering/CONVENTIONS.md` | §2.12 (the six platform seams and one store seam; `ShareService` wraps `share_plus`) · §3.1 (`shareServiceProvider` is a plain `Provider`, keepAlive) · **§1.1 rule 4** (`lib/data/` may not import `material.dart` or `cupertino.dart`) · §4.2 (`<Name>Service`) · §4.7 (rule-id grammar) | **BINDING** on the class name, the provider name and the import |
| `epics/N12-.../N12-T05` | the fake table comment | `FakeShareService` is **N21's**, and this is the commit where it joins the override list |
| `epics/00-PLAN-CRITIQUE.md` | §S6 | `last_exported_at` is `SettingsRepository`'s to write, on `completed` and `unknown` only |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-platform-gateways` | the share seam, its permissions and its fake are its subject |
| `shed-dependencies-and-toolchain` | `share_plus` 13.3.0 enters `pubspec.yaml`, the allowlist and the merged manifest in this commit |

Two auto-firing skills is the cap, and the dependency slot is spent here because this is the one
package whose merged manifest is checked by eye in §5.5 — a share plugin that quietly merges a
permission is the offline-purity contract failing silently. What may be shared and in what form is
`shed-export-and-restore`'s and is not reloaded: §5.1 lists every artefact the seam accepts and §6
states the refusal. The fake joins `pumpApp`'s override list here; its shape is printed in §5.4.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/data/share_service_test.dart`
- **Test** — `'ShareService always shares a file path and never a byte stream or a URL'`
- **Why it is red today** — nothing leaves the phone, and the plugin's API offers three ways to do it wrong.

```bash
fvm flutter test test/data/share_service_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. Assert **three** things and none of them needs
a real share sheet: `ShareService.shareFiles`'s signature takes `List<String> paths` and there is no
overload, no optional `bytes:` and no `Uri` parameter; the source of `share_service.dart` contains
`XFile(` exactly once and `XFile.fromData` zero times; and `origin` is a **required named** parameter
of type `Rect`, so a call site that omits it does not compile. The third is the one worth stating out
loud — `08 §5` chooses a required parameter over a lint precisely because *"a required parameter is a
better gate than a lint, because it fails at compile time."*

**Green.** The minimum code that passes, and nothing beyond it — the gateway, a single share verb, and `FakeShareService` joining `pumpApp`'s override
list in this commit.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

No schema (**this task stores nothing**), no domain, no controller, no screen, no route, no ARB. The
work is one dependency, one gateway, one provider, one fake and one gate row.

| # | Path | What changes in it, and why |
|---|---|---|
| 1 | `pubspec.yaml` | **Edit.** `share_plus: 13.3.0` under `dependencies`, exactly that version, from decision-record §5.1. It requires Flutter ≥ 3.38.1 — confirm against `.fvmrc` before `pub get`, not after |
| 2 | `pubspec.lock` | **Committed, and read.** `share_plus` pulls a small federated set (`share_plus_platform_interface`, the per-platform implementations, `cross_file`, `mime`). Every new line is accounted for in the allowlist |
| 3 | `tool/policy_allowlist.txt` | **Edit.** `share_plus` joins `[dependencies]`; its transitive set joins `[transitive]` |
| 4 | `lib/data/share_service.dart` | **New.** `final class ShareService` with one verb, plus `enum ShareOutcome`. `08 §5` prints both |
| 5 | `lib/data/providers.dart` | **Edit.** `shareServiceProvider` — a plain `Provider<ShareService>`, keepAlive, exactly as `CONVENTIONS §3.1` spells it. Not a `FutureProvider`: there is nothing to initialise |
| 6 | `tool/check_policy.dart` | **Edit.** `layer.plugin_share_plus` (the `package:share_plus` import outside `share_service.dart`) — `08 §1.2` catalogues it as one of the nine confinement rows, and this is the first task with a real file for it to point at. Plus **`export.share_static`** (`Share.share`, `Share.shareXFiles` — the deprecated static API) and `share.from_data` (`XFile.fromData`) |
| 7 | `test/policy/gate_rules_test.dart` | **Edit.** A `firesOn` entry per rule id that did not already have one |
| 8 | `test/support/fake_share_service.dart` | **New.** `12 §4.2`'s fake: `implements ShareService`, never `extends`, recording `List<FakeShared> shared` (path, mime, filename), carrying two tripwires — a share of a path that does not exist, and any call passing bytes rather than a path |
| 9 | `test/support/harness.dart` | **Edit.** `shedContainer` gains `FakeShareService? share` and `shareServiceProvider.overrideWithValue(share ?? FakeShareService())`. N12-T05 deliberately left the seven fakes to the epics that create their gateways; this is share's turn |
| 10 | `test/data/share_service_test.dart` | **New. The anchor, written first.** |
| 11 | `android/app/src/main/AndroidManifest.xml` | **Not edited by hand — but read after `pub get`.** `share_plus` merges a `ShareFileProvider` and a `SharePlusPendingIntent` receiver and **no `uses-permission`**. G1's expected-permission file must not change. If it does, stop |

### 5.2 The signature

`08 §5` prints it. Copy it; the two comments are the load-bearing ones.

```dart
// lib/data/share_service.dart
import 'dart:ui' show Rect;   // NOT package:flutter/material.dart — layer rule 4

final class ShareService {
  /// `origin` is REQUIRED and named — not optional with a default. The
  /// share_plus README states that omitting sharePositionOrigin on iPad
  /// "may cause crashes or unresponsive UI". A required parameter is a
  /// better gate than a lint, because it fails at compile time.
  Future<ShareOutcome> shareFiles({
    required List<String> paths,
    required List<String> fileNames,
    required Rect origin,          // dart:ui — no material import needed
    String? subject,
  }) async {
    assert(paths.length == fileNames.length);
    final result = await SharePlus.instance.share(ShareParams(
      files: [for (final path in paths) XFile(path)],
      fileNameOverrides: fileNames,
      subject: subject,
      sharePositionOrigin: origin,
    ));
    return switch (result.status) {
      ShareResultStatus.success => ShareOutcome.completed,
      ShareResultStatus.dismissed => ShareOutcome.dismissed,
      ShareResultStatus.unavailable => ShareOutcome.unknown,
    };
  }
}

enum ShareOutcome { completed, dismissed, unknown }
```

**The share names** (`09 §1.1`), built by the caller and passed in `fileNames`:

| Artefact | `fileNameOverrides` value |
|---|---|
| `lambs.csv` | `shed-book-2026-lambs.csv` |
| `ewes.csv` | `shed-book-2026-ewes.csv` |
| `treatments.csv` | `shed-book-2026-treatments.csv` |
| Flock book | `shed-book-2026-flock-book-ewes.pdf`, `…-lambs.pdf` |
| Medicine record | `shed-book-2026-medicine-record.pdf` |
| JSON backup (N22) | `shed-book-backup-2026-07-27-2104.json` |

### 5.3 The details that are easy to get wrong

- **`import 'dart:ui' show Rect;` and not `package:flutter/material.dart`.** Layer rule 4 bans
  `material.dart` and `cupertino.dart` in `lib/data/` outright. `Rect` lives in `dart:ui`, and the
  `show` clause is what keeps the rest of `dart:ui` out. If you find yourself reaching for a
  `BuildContext` in this file, you are in the wrong file — the caller computes the rect.
- **`origin` is required and `Rect.zero` is not a workaround, it is the bug.** The caller computes it
  from the button that was tapped:
  `final box = context.findRenderObject()! as RenderBox; box.localToGlobal(Offset.zero) & box.size;`
  Passing `Rect.zero` produces a popover anchored to the top-left corner of an iPad screen, or no
  popover at all. `08`'s own definition of done says *"`Rect.zero` appears at no call site"*.
- **Always a file path; never `XFile.fromData`.** `fromData` writes a temp copy you then have to find
  and delete yourself, which is a second temp-file lifecycle nobody owns. The rule has its own gate
  row for that reason.
- **The static `Share.share*` API is deprecated** and `export.share_static` bans it. Every tutorial
  and every StackOverflow answer older than a year uses it, so it will be reintroduced by someone
  copying a snippet; the gate is what catches that, not review.
- **No plugin type crosses the gateway's boundary in either direction** (`08 §1.1`). Not
  `ShareResultStatus`, not `XFile`, not `ShareParams`. The gateway declares `ShareOutcome` and
  translates at the plugin call. A leaked `ShareResultStatus` in a public signature drags
  `package:share_plus` into `lib/features/` and makes `layer.plugin_share_plus` unsatisfiable — the
  confinement rule and the plugin-free public surface are the same rule seen from two ends.
- **`ShareResultStatus`'s member names are UNVERIFIED against 13.3.0** (`09 §10` item 5). Read them
  off the package before relying on the three-way `switch`, and record what each platform actually
  returns. Then run the airplane-mode pass on both OSes — this is the one place where the answer
  differs by platform and by user action, and the code that depends on it is the banner in T08.
- **`dismissed` is not failure.** The user may have changed their mind, or the platform may simply
  not report. The rule, identical in `08 §11` and `09 §8.3`, is:
  **stamp `last_exported_at` on `completed` and on `unknown`; never on `dismissed`; never before the
  sheet opens.** Recording an export we cannot confirm is the safer error — the cost is one un-nagged
  evening, whereas refusing to record a real export nags a shepherd who did exactly what the app
  asked, and that is how you teach someone to ignore the one banner that matters.
- **The result must reach the caller at all.** A `Future<void>` here would swallow the three-way and
  make T08's rule unimplementable. `08` owns the signature; what `09` requires is that the outcome is
  returned rather than logged.
- **Artefacts are written to `getTemporaryDirectory()`, never to the media root** (04 §4.2). That
  directory is excluded from iCloud and from Android Auto Backup, so stale exports never inflate a
  user's backup. **This task does not sweep it** — `MediaSweeper` is N23-T03, in both directions.
- **File names are built from `seasons.year`, an integer, and never from `seasons.label`.** A
  user-authored label can contain `/`, and a filename is the one place this app would otherwise have
  to sanitise user text. The backup name carries the date **and the time** because a shepherd who
  exports before and after a night would otherwise overwrite the morning's file in Downloads.
- **`share_plus` merges no permission, and the merged manifest is where you prove it.** It adds a
  `ShareFileProvider` and a `SharePlusPendingIntent` receiver. Read the G4 merger report after
  `pub get`; if G1 reports a permission delta, the epic stops until it is explained.
- **`FakeShareService` `implements` and never `extends`** (`12 §4.2`). When `08` changes a signature,
  the fake becomes a **compile error** rather than a silent divergence. Its two tripwires are named
  in that section and are not optional: a share of a path that does not exist, and any call passing
  bytes rather than a path.
- **The fake records the bytes, and that is what makes N23 possible.** `12 §4.1`: *"a fake is a real
  implementation. `FakeShareService` capturing bytes is what makes the export → import → export round
  trip possible at all — you need the bytes, not a `verify`."* Write it as a recorder, not a spy.
- **There is no in-app print dialog and the gateway does not pretend there is.** Printing is the OS
  Print action from inside the share sheet. Nothing in this file is named `print`.

### 5.4 The full test set

`test/data/share_service_test.dart` — against `FakeShareService` and against the real class's
**source and signature**; there is no way to drive a real share sheet in a host test, and pretending
otherwise produces a test that asserts a mock.

| Case | What it asserts |
|---|---|
| `'ShareService always shares a file path and never a byte stream or a URL'` | **The anchor.** The signature takes `List<String> paths`; `XFile(` appears once in the source and `XFile.fromData` zero times; `origin` is a required named `Rect` |
| `'origin is required, so a call site that omits it does not compile'` | An analyzer-level assertion — a `// expect-error` fixture compiled by the analyzer, or a source-text check that the parameter carries `required`. The compile-time gate is the design and a test that only checks runtime behaviour misses it |
| `'Rect.zero appears at no call site under lib/'` | Source text over `lib/`. `08`'s definition of done, made mechanical |
| `'the three ShareResultStatus values map to the three ShareOutcome values'` | The `switch` is exhaustive and total; a fourth status would be a compile error at this one site |
| `'no share_plus type appears in any public signature outside share_service.dart'` | `ShareResultStatus`, `ShareParams`, `XFile`, `SharePlus` appear in exactly one file |
| `'FakeShareService records path, mime and filename for every share'` | The recorder shape `12 §4.2` fixes |
| `'FakeShareService fails a share of a path that does not exist'` | Tripwire one. A test that shares a path nothing wrote is a test that would pass against a broken writer |
| `'FakeShareService fails any call that passes bytes rather than a path'` | Tripwire two, decision #80 |
| `'shedContainer overrides shareServiceProvider with the fake by default'` | The harness edit, asserted rather than assumed. Every widget test from here on depends on it |
| `'the deprecated static Share API appears nowhere under lib/'` | `Share.share`, `Share.shareXFiles`. Complements `export.share_static` — the gate is the build, the test names the file |
| `'no artefact path is under the media root'` | Every path handed to `shareFiles` in the suite is under the temporary directory, never under `getApplicationSupportDirectory()/media` |
| `'a share name is built from the season year and never from the season label'` | Seed a season whose `label` contains `/`; assert the produced `fileNameOverrides` value contains no separator and contains the year |

**Nothing in this task is time-shaped**, so there is no `uk-zone` case: a share carries no clock. The
one instant the seam influences — `last_exported_at` — is written by `SettingsRepository` in **T08**,
and its DST case lives there.

### 5.5 The manifest, checked by eye

```bash
fvm flutter pub get
fvm flutter build apk --debug            # produces the merged manifest
grep -c "uses-permission" build/app/intermediates/merged_manifests/debug/AndroidManifest.xml
# compare against android/expected_permissions.txt — the count must not have moved
grep -n "ShareFileProvider\|SharePlusPendingIntent" build/app/intermediates/merged_manifests/debug/AndroidManifest.xml
# expect both, and expect nothing else new
```

## 6. Constraints that bind this task

- **Offline, and this is the task where the boundary is drawn.** The share sheet is **another process** — decision-record §3.1's tier 3, the part the public wording explicitly does not claim. No network path may be added inside the app: G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. `share_plus` merges **zero** permissions and G1 is what proves that after this commit.
- **The gateway rule** — one plugin per gateway, one gateway per plugin, no plugin type in a public signature, a hand-written fake in `test/support/` (#112). Seven fakes when this epic is done, and this is the fifth.
- **The five safety rules** — none is *implemented* here, but §12.5 is *enabled* here: the three-way outcome is what lets T08 record an export honestly instead of guessing.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. **`sync` is worth a second look in this file**, because "share" and "sync" are the two words a reader will confuse and only one of them is true.

## 7. Definition of Done

- [ ] `'ShareService always shares a file path and never a byte stream or a URL'` passes, and was seen to fail first for the stated reason
- [ ] always a file path
- [ ] no network route exists in the gateway's surface
- [ ] the fake joins the override list here, per N12-T05's rule
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `share_plus` is pinned at **13.3.0** from decision-record §5.1, Flutter's version floor was checked against `.fvmrc` **before** `pub get`, and `pubspec.lock`'s diff was read
- [ ] `origin` is a **required** named `Rect`; `Rect.zero` appears at no call site; `XFile.fromData` appears nowhere
- [ ] `layer.plugin_share_plus`, `export.share_static` and `share.from_data` exist, have `firesOn` entries, and were each watched to fire
- [ ] no `share_plus` type appears outside `lib/data/share_service.dart`
- [ ] `FakeShareService` `implements` `ShareService`, records path/mime/filename, and carries both tripwires
- [ ] the merged Android manifest gained a `ShareFileProvider` and a `SharePlusPendingIntent` receiver and **no `uses-permission`**; G1 is unchanged
- [ ] `09 §10` item 5 has been run and `ShareResultStatus`'s member names and per-platform semantics are recorded in the PR body

## 8. Verification

```bash
fvm flutter test test/data/share_service_test.dart
make check
make test
```

Then the confinement, and the manifest:

```bash
grep -rn "package:share_plus" lib/ --include='*.dart'
# expect exactly: lib/data/share_service.dart

grep -rn "Share\.share\|XFile.fromData\|Rect.zero" lib/
# expect nothing

grep -rn "ShareResultStatus\|ShareParams\|SharePlus\." lib/ | grep -v share_service.dart
# expect nothing — no plugin type crosses the seam
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(gateway): ShareService, the share sheet and nowhere else`
