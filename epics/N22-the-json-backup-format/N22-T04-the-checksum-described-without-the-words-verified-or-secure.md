# N22-T04 — The checksum, described without the words *verified* or *secure*

| | |
|---|---|
| **Epic** | [N22 — The JSON backup format](epic.md) · `00-README` §9 step 8 (2 of 3) |
| **Task** | 4 of 5 |
| **Depends on** | N22-T03 |
| **Commit** | one commit · `feat(backup): a checksum, described honestly` |

## 1. Why this task exists

A checksum that detects **accidental corruption** — a truncated AirDrop, a bad SD card —
and nothing else. It is not a signature, it proves nothing about tampering, and `CLAUDE.md` bans the
words *verified* and *secure* about it precisely because those words promise what it does not do.

The temptation here is not the wording, it is the dependency. `package:crypto` is already in
`pubspec.lock` because `pdf` declares it, so `import 'package:crypto/crypto.dart';` resolves and the
build stays green. Decision-record §5.1 does not list it as a direct dependency, and 09 §5.7 is explicit:
gate G2's transitive allowlist *"records what is in the graph, and it is not a licence to import from
it."* Fifteen lines of FNV-1a is the whole cost of not making a transitive edge load-bearing without an
audit.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/09-export-formats.md` | §5.7 (FNV-1a 64 over the canonical `tables` bytes; why not `crypto`; the two count comparisons; the writer that encodes once; the 20 MB tripwire) · §5.2 (`checksum` is a header key and the header is outside the checksum) · §9 (the anti-pattern rows) | the arithmetic and what it covers |
| `docs/engineering/04-migrations-media-backup-restore.md` | §6.6 (corruption check, not a tamper check; *"the export screen says 'checks the file is complete' and never 'verifies the file is authentic'"*) · §7.4 (the incomplete-file wording) | the honest sentence, verbatim |
| `CLAUDE.md` | the offline-purity section · the banned-words list (*"verified"/"secure" about the backup checksum"*) | the words that may never be used |
| `docs/engineering/CONVENTIONS.md` | §5.3 (banned words, absolutely) · §5.4 (copy conventions) | the same ban, as the naming authority states it |
| `docs/engineering/10-accessibility-and-i18n.md` | §8.4 (ARB house rules — a `description` carrying the safety rationale) | where the honest sentence lives |
| `docs/engineering/07-screens.md` | §13.3 (the Export screen's seven rows) · §13.4 (§12 and the honest wording; the permanently banned copy) | the one line this task adds to a screen that already exists |
| `docs/research/00-tech-decisions.md` | §5.1 (the verified dependency table — `crypto` is **not** in it) · §5.3 (what was dropped and why) | why the arithmetic is hand-written |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-export-and-restore` | the checksum, what it does and what it must not claim |
| `shed-accessibility-and-copy` | the banned words and the honest wording |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/offline_wording_test.dart`
- **Test** — `'the words verified and secure appear nowhere near the backup checksum'`
- **Why it is red today** — there is no integrity check, and the first wording written would over-claim.

```bash
fvm flutter test test/policy/offline_wording_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it fails on the real thing rather than on a stray word. Scan the joined string
literals of `lib/data/backup_format.dart`, `lib/features/export/`, `lib/features/settings/` and every
message value in `lib/l10n/app_en.arb` for `verified`, `verify`, `secure`, `security`, `authentic` and
`tamper`, case-insensitively, and assert **zero** hits. Use `joinedStringLiterals`, not
`file.contains(...)`: Dart wraps long strings across adjacent literals and a naive scan misses exactly
the sentence you are trying to police (09 §6.4). Add the six words to the `const` banned-phrase list
already in this file rather than starting a second one — a list that moves to `test/support/` acquires a
second allowlist, which is the failure `12 §1.4` describes.

**Green.** The minimum code that passes, and nothing beyond it — the checksum, the honest wording, and the vocabulary assertion.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema, no domain, no wiring, no controller.** The arithmetic is fifteen lines in `lib/data/` and
the rest is copy. Say so in the commit message. `test/policy/offline_wording_test.dart` already exists —
N02-T02 created it and its refactor note names this task as one of the two that extend it. Extend it; do
not create a second file.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/backup_format.dart` | Edit. `fnv1a64Hex`'s body (T01 declared it), the `checksum` block's two keys, and `checkBackupIntegrity` — the checksum comparison and the per-table count comparison, together, because they are one decision |
| 2 | `lib/l10n/app_en.arb` | Edit. The incomplete-file refusal and the Export screen's integrity line, each with a `description` saying which words are banned and why |
| 3 | `lib/l10n/app_localizations*.dart` | Regenerated by gen-l10n and **committed in this same commit** — the `codegen` job diffs `lib/` |
| 4 | `lib/features/export/export_screen.dart` | Edit. One line on the backup row: what the check does and what it does not. The row itself is N21-T07's and does not move |
| 5 | `test/policy/offline_wording_test.dart` | Edit. The anchor, added to N02-T02's file and its existing `const` banned-phrase list |
| 6 | `test/features/backup_format_test.dart` | Edit. The arithmetic cases in §5.4 |

### 5.2 The signatures

```dart
// lib/data/backup_format.dart
// FNV-1a 64. Fifteen lines, no dependency, deterministic.
// NOT package:crypto: it is in the lockfile because `pdf` declares it, and
// decision-record §5.1 does not list it as a direct dependency (09 §5.7).

const int _fnvOffsetBasis = 0xcbf29ce484222325;   // 14695981039346656037
const int _fnvPrime       = 0x100000001b3;        // 1099511628211

String fnv1a64Hex(List<int> bytes) {
  var hash = _fnvOffsetBasis;
  for (final byte in bytes) {
    hash ^= byte;
    hash *= _fnvPrime;          // wraps mod 2^64 on the Dart VM — that IS the algorithm
  }
  return _hex64(hash);
}

/// A Dart `int` is a SIGNED 64-bit value, so `hash.toRadixString(16)` prints a
/// minus sign for half of all inputs and `toUnsigned(64)` is a no-op at width
/// 64. Split it. See the gotchas.
String _hex64(int v) =>
    ((v >> 32) & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0') +
    (v & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
```

```dart
/// Two independent comparisons, in one place because they are one decision:
/// the checksum over the canonical `tables` bytes, and `counts` per table
/// against the number of rows actually parsed. N23's importer runs the same
/// count comparison a second time, against the rows actually INSERTED.
sealed class BackupIntegrityOutcome { const BackupIntegrityOutcome(); }
final class BackupIntact   extends BackupIntegrityOutcome { const BackupIntact(); }
final class BackupIncomplete extends BackupIntegrityOutcome {
  const BackupIncomplete({this.table, this.expected, this.parsed});
  final String? table;   // null when it is the checksum that disagreed
  final int? expected;
  final int? parsed;
}

BackupIntegrityOutcome checkBackupIntegrity({
  required BackupHeader header,
  required Uint8List canonicalTablesBytes,
  required Map<String, int> parsedCounts,
});
```

The published block, exactly as it appears in every file:

```jsonc
"checksum": { "algorithm": "fnv1a64", "value": "9f2b1c04a77e3d51" }
```

The wording, from 04 §6.6 and §7.4:

```json
"backupIntegrityNote": "Checks the file is complete.",
"@backupIntegrityNote": {
  "description": "The Export screen's one line about the backup checksum. It detects accidental corruption — a truncated transfer, a bad card — and NOTHING else. The words 'verified', 'secure' and 'authentic' are banned here by CLAUDE.md and CONVENTIONS 5.3: they promise tamper detection this app does not have and cannot have without a cryptographic digest, and crypto is not a direct dependency."
},
"restoreRefusedIncomplete": "This file is incomplete — it may have been cut off when it was sent. Try sending the original again.",
"@restoreRefusedIncomplete": {
  "description": "Shown when the checksum or a per-table count disagrees. Names the likely cause, which is a truncated transfer, and gives the shepherd the one action that helps. Never 'the file failed verification': the check is a corruption check, not a tamper check. 04 7.4."
}
```

### 5.3 The details that are easy to get wrong

- **`14695981039346656037` will not compile as a decimal literal.** It is above `2^63 − 1`, and Dart
  rejects a decimal integer literal that does not fit a signed 64-bit int. Written as
  `0xcbf29ce484222325` it compiles: Dart reinterprets a hexadecimal literal in `0 .. 2^64 − 1` as the
  corresponding signed value, which is `-3750763034362895579` and is exactly the right bit pattern. The
  same is not true of the prime — `1099511628211` fits comfortably — so only one of the two constants
  carries the trap, which is why it is easy to hit.
- **`toRadixString(16)` on a negative `int` prints a minus sign.** Roughly half of all inputs produce a
  hash whose top bit is set, so half of all backups would carry a `checksum.value` starting `-`. Split
  the value into two 32-bit halves and pad each to eight hex digits.
- **`toUnsigned(64)` does not help, and looks as though it should.** `x.toUnsigned(width)` is
  `x & ((1 << width) - 1)`; at width 64 the shift overflows to `0`, so the mask is `-1` and the result is
  `x` unchanged — sign and all. Reach for it, get a green-looking call, and ship the minus sign anyway.
- **`hash *= prime` wrapping is the algorithm, not a bug to guard against.** On the Dart VM `int` is
  64-bit two's complement and arithmetic wraps silently, which is exactly FNV's modulo-2^64 step. Do not
  add a mask, do not reach for `BigInt`, and do not "fix" the overflow. Note in the file that this
  relies on VM `int` semantics; the project ships no web target (decision #1), and `flutter test` runs on
  the VM.
- **Hash the bytes, not the string.** `fnv1a64Hex` takes `List<int>` and is fed
  `canonicalJsonBytes(tables)` directly. Hashing `utf8.encode(jsonEncode(tables))` re-encodes — which is
  the second encode 09 §5.7 exists to forbid, doubles peak heap on the largest artefact the app produces,
  and is how the hashed bytes and the written bytes silently diverge.
- **The checksum covers the `tables` value and nothing else.** Not the header, not the whole file. The
  header carries `exportedAtUtc`, so including it would make the checksum differ between two exports of
  the same database — the exact property T01 spent a task establishing. Say it in a comment beside the
  call, because "why isn't the whole file covered?" is the first review question.
- **The published `algorithm` string is part of the format.** `"fnv1a64"`, lower case, no hyphen, no
  version suffix. It is written into every file a shepherd has ever exported; changing it later means
  either two readers or a `formatVersion` bump.
- **`counts` is a second, independent check and is not redundant.** The checksum catches truncation and
  byte damage; the counts catch a writer that silently dropped a table. Compare per table, over all 21
  keys, including the zeros — a table absent from `counts` is a table nothing verifies (09 §5.2). N23's
  importer runs the same comparison again against the rows actually **inserted**; that second run is
  what catches an importer bug rather than a file problem, and it is not this task's.
- **Any failure aborts before the restore confirmation screen is ever shown.** Refuse a corrupt file;
  never half-import one. `checkBackupIntegrity` returns a value and touches nothing, which is what makes
  that structural rather than a matter of call order.
- **The banned words are banned in three places, not one.** `lib/`, `assets/` and `lib/l10n/app_en.arb`.
  The ARB is the one people forget, and it is the one a translator would touch — which is also why the
  `description` carries the reason rather than only the instruction.
- **"Complete" is the honest word and it is not a hedge.** The check really does tell you the file is
  whole. What it cannot tell you is that nobody changed it, and the difference matters because the file
  is the only recovery path in a product with no server. `Checks the file is complete.` — that sentence,
  and no adjective in front of it.
- **The banned-word scan must not fire on this task's own test.** A test file that names the words in
  order to ban them is a hit for a naive `lib/`-and-`test/` scan. Scope the scan to `lib/`, `assets/` and
  the ARB, exactly as N02-T02 scoped it, and say so in a comment; widening it later to `test/` will look
  like a strengthening and will be a self-inflicted red.
- **`crypto` stays out, and a future digest has a written path in.** If a real digest is ever required:
  audit it by c1's method — pub.dev API, publisher, transitive graph, merged manifest — and promote it
  into decision-record §5.1 **first**. Not the other way round.

### 5.4 The full test set

`test/policy/offline_wording_test.dart` (extended) and `test/features/backup_format_test.dart` (extended).

| Case | What it asserts |
|---|---|
| `'the words verified and secure appear nowhere near the backup checksum'` | **The anchor.** Six words, case-insensitive, over `lib/`, `assets/` and every ARB message value, through `joinedStringLiterals` |
| `'package:crypto is imported nowhere under lib/'` | Source text. The gate proves it too; this fails first and names the file |
| `'fnv1a64Hex matches the published FNV-1a 64 vectors'` | Empty → `cbf29ce484222325`; `a` → `af63dc4c8601ec8c`; `foobar` → `85944171f73967e8`. Reference vectors, not self-generated ones |
| `'fnv1a64Hex always returns sixteen lower-case hex digits'` | Over a few thousand random byte strings. The case that catches the minus sign and the missing pad |
| `'a hash whose top bit is set still renders without a sign'` | Pick an input that produces a negative `int` and assert the string directly |
| `'the checksum covers the tables bytes and not the header'` | Change `exportedAtUtc`, re-write the file, assert `checksum.value` is unchanged |
| `'a single flipped byte in the tables value changes the checksum'` | The property the check exists for |
| `'a truncated file is detected'` | Chop the last 200 bytes and assert `BackupIncomplete` |
| `'the algorithm string is fnv1a64, lower case, no hyphen'` | Read from a written file, not from the constant |
| `'a table dropped from tables is caught by counts even when the checksum agrees'` | Rebuild the file with one table removed **and** its checksum recomputed. This is the case that proves the two checks are independent |
| `'counts is compared per table, over all 21 keys including zeros'` | Not a total, not a sum |
| `'checkBackupIntegrity touches no file and no database'` | It takes bytes and a map; the signature is the proof |
| `'the Export screen says checks the file is complete and nothing stronger'` | Widget test over the backup row |
| `'the incomplete-file refusal names the likely cause and one action'` | The 04 §7.4 wording, verbatim from the ARB |
| `'no import of package:intl or NumberFormat appears in backup_format.dart'` | Still true after this task's edits |

**The `uk-zone` group** — added to T01's group in the same file.

| Case | What it asserts |
|---|---|
| `'DST: two exports an hour apart in the ambiguous 01:00–01:59 hour produce the same checksum'` | The header moved and the body did not, so the value must not. This is the strongest single statement of what the checksum covers |

## 6. Constraints that bind this task

- **The five safety rules — §12.3 by way of honesty.** Over-claiming what the checksum does is the same
  failure as presenting the app as a regulatory record: it invites a shepherd to trust a file more than
  they should. The mechanism is a source-text test, which is the fourth level of the hierarchy — say so,
  because it is weaker than the disclaimer's *unconstructible* and the wording therefore needs the
  `description` to carry its own reason.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. **This is the task where G2 earns its keep:** `crypto` resolves, and it is not ours to import.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. And in this task specifically: no *verified*, no *secure*, no *authentic* — in the code, in the copy, in the commit message, or in the PR body.

## 7. Definition of Done

- [ ] `'the words verified and secure appear nowhere near the backup checksum'` passes, and was seen to fail first for the stated reason
- [ ] a truncated file is detected
- [ ] the words *verified* and *secure* appear nowhere in this context
- [ ] the wording says what it detects and what it does not
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `package:crypto` is imported nowhere under `lib/` and `pubspec.yaml` gains no dependency
- [ ] `fnv1a64Hex` matches the published FNV-1a 64 reference vectors and always returns sixteen lower-case hex digits
- [ ] the offset basis is written as a hexadecimal literal, with a comment saying why the decimal form does not compile
- [ ] the checksum covers `canonicalJsonBytes(tables)` only — proved by changing `exportedAtUtc` and asserting the value does not move
- [ ] `tables` is encoded exactly once and the hashed bytes are the written bytes
- [ ] `counts` is compared per table over all 21 keys, and a dropped table is caught even when the checksum agrees
- [ ] `checkBackupIntegrity` returns a value, touches no file and no database, and aborts before any confirmation screen
- [ ] the banned-word scan is added to N02-T02's existing `const` list in the same file, not to a second one
- [ ] every added ARB message has a `description` and the regenerated `lib/l10n/app_localizations*.dart` is committed in this commit
- [ ] **the `uk-zone` case asserting one checksum across two exports in the 01:00–01:59 ambiguous hour is present and tagged**

## 8. Verification

```bash
fvm flutter test test/policy/offline_wording_test.dart
fvm flutter test test/features/backup_format_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

```bash
grep -rni "verified\|verify\|secure\|authentic\|tamper" \
     lib/data/backup_format.dart lib/features/export/ lib/features/settings/ lib/l10n/app_en.arb
     # expect zero — this is the scope CLAUDE.md's ban is about
grep -rn "package:crypto" lib/                              # expect zero
grep -n "14695981039346656037" lib/data/backup_format.dart  # expect zero — the hex literal only
git diff --stat -- pubspec.yaml pubspec.lock                # expect empty
```

Then confirm by hand that the `tables` value as written is already canonical, which is the whole reason
the checksum is reproducible outside the app — sorting it must change nothing:

```bash
cmp <(jq -c '.tables' backup.json) <(jq -cS '.tables' backup.json) && echo "canonical"
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(backup): a checksum, described honestly`
