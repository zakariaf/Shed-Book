# N21-T01 — `CsvWriter` — hand-rolled RFC 4180

| | |
|---|---|
| **Epic** | [N21 — Export: CSV, PDF and share](epic.md) · `00-README` §9 step 8 (1 of 3) |
| **Task** | 1 of 8 |
| **Depends on** | N20-T07 |
| **Commit** | one commit · `feat(export): a hand-rolled RFC 4180 CSV writer` |

## 1. Why this task exists

Hand-rolled because the quoting rules are the whole job and a dependency for them is a
dependency to audit: the quoting rules, UTF-8 with a BOM decision recorded, the line ending, and the
**formula-injection guard** — a tag beginning `=` must not execute when the file is opened in a
spreadsheet.

`csv` 8.0.0 is rejected in decision-record §5.3 with a specific reason, not a taste: an unverified
uploader shipping a fresh breaking rewrite (`CsvCodec` → `Csv`, no longer a `dart:convert` `Codec`,
`CsvEncoder` moved from `Converter` to `StreamTransformerBase`) for roughly fifty lines of behaviour
that RFC 4180 specifies completely. Three of the properties this app needs are byte-level and no
general-purpose package gives you all three at once: the UTF-8 BOM, CRLF line endings, and a quoting
predicate that also fires on `;` and TAB.

The second half of the task is what makes the trailer structural rather than habitual: **this file is
the only producer of CSV bytes in the app**, enforced by the policy rule `export.csv_bytes`. A writer
that cannot be bypassed is a writer whose footer cannot be forgotten.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/09-export-formats.md` | **§2.1** (why hand-rolled, and the one-producer rule) · **§2.2** (the encoder printed in full — copy the shape, not the comments) · **§2.3** (the nine quoting rows, each with its RFC clause) · **§2.4** (UTF-8, the BOM, CRLF, and why there is no `sep=;` line and no delimiter setting) · **§2.5** (the formatting table, and why `package:intl` is banned in this file) · **§2.6** (the formula guard, and the three reasons it is not a §12.4 violation) · **§2.7** (the six trailer records, padded, on every CSV including a zero-row one) · §9 (the anti-pattern rows this file's rules catch) · §10 item 6 (`DateTime.timeZoneName` varies by platform) | the class, member for member, and every byte it emits |
| `docs/engineering/05-domain-correctness.md` | §4.1–§4.4 (`RecordedTime`, `enum TimeSource`, the three provenance labels verbatim, the exhaustive-switch test) · §7.4 (`Disclaimers` and `ExportEnvelope`, printed) | the getter this task adds, and the two types the constructor takes |
| `docs/engineering/CONVENTIONS.md` | §1 (`lib/data/` is flat — R18) · §1.1 layer rules 3 and 4 (`lib/data/` may import `package:intl`, and **may not** import `package:flutter/material.dart`) · **§2.2** (`Instant`, `TimeSource` — the row this task amends) · §2.14 (`Disclaimers`) · §4.1 (file naming) · §4.2 (`final class`; `Helper`/`Util` are banned suffixes) · **§4.7** (dotted `namespace.name`; the namespace list this task extends) · §5.3 (banned words) | **BINDING** on the file path, the class name, the rule ids and the getter's spelling |
| `docs/engineering/12-testing.md` | §1.4 (what is a gate and what is a test) · §11.1 (a policy test is named for the property) · §11.6 (`Future.delayed` in a test body is banned) | where the assertions live |
| `docs/research/00-tech-decisions.md` | **§5.3** (`csv` 8.0.0, rejected, with the reason and the alternative) · #82 (the writer, spelled out) · #56 (canonical grams — no floats) · #108 (numeric dates only inside CSV, beside an ISO-8601 column) | the decision this task implements, and the one it must not re-open |
| `epics/N04-.../N04-T04` | the whole task, especially gotchas 5–8 | `TimeSource`'s three keys are frozen forever; the label is English in the domain deliberately; there is no `default:` arm |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-export-and-restore` | CSV, its shapes and its quoting are its subject |
| `shed-testing` | the round-trip property is what proves the quoting |

`CLAUDE.md` caps auto-firing skills at two per intent, and this task spends both. The two it also
touches are handled in this file rather than reloaded: the `enum TimeSource` getter and the switch
that has to stay exhaustive are written out in §5.2, and the `CONVENTIONS` §2.2 catalogue row plus the
new `export` rule-id namespace in §4.7 are quoted in §5.1 and §5.5. Read those before you name a file
or a rule id — `shed-conventions` is the front door for both and it says nothing this task contradicts.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/csv_writer_test.dart`
- **Test** — `'a field containing a comma, a quote and a newline round-trips per RFC 4180'`
- **Why it is red today** — nothing writes CSV, so the first export would reach for a package or for string interpolation, and neither survives a field containing a quote and a newline.

```bash
fvm flutter test test/features/csv_writer_test.dart   # expect: failing, for the reason above
```

Make the assertion specific while you are writing it. The field is
`she said "kick", then⏎the lamb came` — one comma, one pair of quotes, one embedded LF, all in the
value a shepherd actually types into `lambs.notes`. Encode a one-row file with a two-column header,
decode the bytes with a **strict** RFC 4180 reader written inside the test (twenty lines: a state
machine over quoted/unquoted), and assert the decoded field is **identical to the input, character
for character** — including the newline, which must have stayed inside the quotes and must not have
become a second record. Assert the escape is `""` and never `\"`. That is the single most common
hand-rolled CSV bug, and it is what the test name means by *per RFC 4180*.

**Green.** The minimum code that passes, and nothing beyond it — the writer, the guard, and the round-trip property over generated fields.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

§8 has no schema step here (**this task stores nothing — say so in the commit message**), and no
controller, screen, route or ARB step either. It reaches two layers: `lib/domain/` for one getter and
`lib/data/` for the writer. Plus the gate, because two new rules are born with the file they police.

| # | Path | What changes in it, and why |
|---|---|---|
| 1 | `lib/domain/time/recorded_time.dart` | **Edit.** `enum TimeSource` gains `String get label`, and `RecordedTime.provenanceLabel` becomes `=> source.label`. Required by `09 §1.3`: the §12.5 trailer line is built from `TimeSource.values.map((s) => s.label)` and a writer has no `RecordedTime` instance to ask. Moving the exhaustive switch onto the enum keeps the same compiler check. **One getter; nothing else in this file moves.** |
| 2 | `docs/engineering/CONVENTIONS.md` §2.2 | **Edit, same commit.** `TimeSource`'s shape row gains `String get label`. `09 §1.3` says why this is not optional: *"the 05 edit is not applied until the catalogue records it, or the next fixer reverts it as a stray name."* CONVENTIONS outranks every other document on a type shape |
| 3 | `docs/engineering/05-domain-correctness.md` §4.1 | **Edit, same commit.** The same one-line addition, in the document that owns `RecordedTime` |
| 4 | `lib/data/csv_writer.dart` | **New.** `final class CsvWriter` and nothing else. `lib/data/` is flat (R18) — there is no `lib/data/export/`. `09 §1.2` calls this file out precisely because `CONVENTIONS §1` does not list it |
| 5 | `tool/check_policy.dart` | **Edit.** Two rows: **`export.csv_bytes`** (a `\r\n` literal or the BOM byte triple `0xEF, 0xBB, 0xBF` outside `csv_writer.dart`) and **`export.intl_in_writer`** (`package:intl`, `NumberFormat` or `DateFormat` inside `csv_writer.dart`, `pdf_writer.dart` or `backup_format.dart`). N03's rule table is documented as **not closed**; this is one of the epics that extends it |
| 6 | `docs/engineering/CONVENTIONS.md` §4.7 | **Edit, same commit.** The namespace list gains **`export`**. R54: a rule id whose namespace is not in §4.7's list is a rule id the inventory test rejects |
| 7 | `test/policy/gate_rules_test.dart` | **Edit.** A `firesOn` entry per new rule id. N03-T07's inventory assertion fails any rule in `check_policy.dart` with no proving case **and** any proving case with no rule — plant the violation, watch it fire, delete it |
| 8 | `test/features/csv_writer_test.dart` | **New. The anchor, written first.** |
| 9 | `test/domain/uk_zone/csv_local_rendering_test.dart` | **New.** `@Tags(['uk-zone'])`. The `dd/MM/yyyy HH:mm` rendering and the zone label across the ambiguous hour — see §5.4 |

`pubspec.yaml` is **not** touched. That is the point of the task: `csv` 8.0.0 does not enter the
graph and G2's allowlist does not move.

### 5.2 The signature

`09 §2.2` prints it. Copy the shape exactly; the comments below are the ones worth keeping.

```dart
// lib/data/csv_writer.dart
// RFC 4180 — https://www.rfc-editor.org/rfc/rfc4180
import 'dart:convert';
import 'dart:typed_data';

import '../domain/policy/disclaimers.dart';
import '../domain/policy/export_envelope.dart';
import '../domain/time/recorded_time.dart';   // for TimeSource.label

final class CsvWriter {
  /// The envelope is not optional and the disclaimer is not a parameter of it
  /// (05 §7.4). A CsvWriter that cannot emit the footer cannot be constructed.
  const CsvWriter(this.envelope, {required this.localZoneLabel});

  final ExportEnvelope envelope;

  /// e.g. "IST (UTC+01:00)". Built from `envelope.generatedAt.local` by the
  /// caller, never from a clock read and never from package:timezone
  /// (R48 confines tz to the notification seam).
  final String localZoneLabel;

  static const String _eol = '\r\n';                 // RFC 4180 §2.1
  static const List<int> _bom = [0xEF, 0xBB, 0xBF];  // UTF-8 BOM, for Excel

  static final RegExp _needsQuote = RegExp(r'[",\r\n;\t]');

  /// Excel, Numbers and Google Sheets evaluate a field beginning with one of
  /// these as a formula. `=` `+` `-` `@` TAB CR — the full set, not the four
  /// obvious ones. This is a transformation of the EXPORT (§2.6).
  static final RegExp _formulaLead = RegExp(r'^[=+\-@\t\r]');

  String _field(Object? v);

  /// Bytes, not a String: the BOM is a byte-level concern and a String cannot
  /// carry it without lying about its own length. Throws a StateError naming
  /// both counts if any row's length differs from the header's.
  Uint8List encode(List<String> header, Iterable<List<Object?>> rows);

  /// Six records, appended by `encode` itself and padded to the header's
  /// field count. T03 owns their content; T01 owns that they exist.
  List<String> _trailer();
}
```

And the domain edit, which is one getter and one delegation:

```dart
// lib/domain/time/recorded_time.dart
enum TimeSource {
  autoCaptured('auto'),
  userEntered('entered'),
  userEdited('edited');

  const TimeSource(this.key);
  final String key;

  /// 07 §1.5's three strings, verbatim. On the enum rather than on
  /// RecordedTime because the §12.5 CSV trailer is built from
  /// TimeSource.values and has no instance to ask (09 §1.3).
  String get label => switch (this) {
        TimeSource.autoCaptured => 'recorded automatically',
        TimeSource.userEntered  => 'time entered by you',
        TimeSource.userEdited   => 'time edited by you',
      };
}
```

`RecordedTime.provenanceLabel` becomes `String get provenanceLabel => source.label;`. N04-T04's
`'provenanceLabel is exhaustive and never returns an empty string'` stays green — it iterates
`TimeSource.values` and never named where the switch lived.

### 5.3 The details that are easy to get wrong

- **`""`, never `\"`.** RFC 4180 §2.7 escapes a quote by doubling it. Backslash escaping is a
  C-family habit no spreadsheet implements, and the file it produces opens with visible backslashes
  and a field count that is right by accident. `09 §2.3` calls it *"the single most common
  hand-rolled CSV bug"*, which is why it is the anchor.
- **The formula-lead set has six members, not four.** `=` `+` `-` `@` **TAB** and **CR**. The two
  everyone forgets are the two that arrive from a paste. Prefixing with `'` neutralises them: Excel
  consumes the apostrophe as a text marker, a plain-text viewer shows it.
- **The guard transforms the export and never the record, and there are three reasons it is not a
  §12.4 violation.** SQLite holds the exact bytes the shepherd typed and so will the JSON backup —
  the guard lives only in this file, which `backup_format.dart` never calls. The transformation is
  declared inside the file, in the trailer, in plain words. And it cannot corrupt a numeric column,
  because **no exported numeric column can be negative**: every numeric `CHECK` in `03` is `>= 0`
  (`days`, `birth_weight_g`, `scanned_count`, `bottle_feeds`, `byte_size`, `volume_ml`,
  `ewes_to_ram`). If a future column can hold a negative number, the guard becomes per-column in the
  same commit as that column — write it down where the column is added, not here.
- **Never apply the guard in the PDF or the JSON writer "for consistency".** It would put an
  apostrophe into the vet's medicine book and break the backup round trip.
- **`#` is deliberately not in the formula-lead set.** RFC 4180 has no comment syntax; the trailer
  rows are ordinary records whose first field begins `#`, which every parser reads as data and every
  human reads as a note. Put `#` in the set and every trailer row reads `'#` in a text editor.
- **The ragged-row check is a `throw`, not an `assert`.** Asserts are compiled out of the release
  build, and a ragged file is a release-mode failure: it reaches the share sheet, it reaches the
  shepherd's spreadsheet, and every column after the short row is shifted. One integer comparison per
  row is not a cost. `09 §9` lists *"an `assert` as the only guard on a ragged CSV row"* as an
  anti-pattern by name.
- **Trailer rows are padded to the header's field count.** RFC 4180 §2.4 requires a rectangular
  file, and a two-field trailer row breaks a strict parser on the **last line** — exactly where a
  shepherd's spreadsheet stops importing, and it looks like the export was truncated.
- **The BOM is CSV-only. JSON must never carry it.** A leading BOM makes `jsonDecode` fail, or turns
  itself into part of the first key. `backup_format.dart` (N22) never touches `_bom`, and
  `export.csv_bytes` is what stops the triple appearing anywhere else.
- **`_field` has no `DateTime` branch and no `double` branch, and that is a design decision.** Every
  value handed to the encoder is already a `String`, an `int` or `null`, because formatting is the
  caller's decision and a formatter hidden inside an encoder is a locale bug waiting for a Welsh
  name. Adding a `DateTime` arm here is how `NumberFormat` eventually gets imported.
- **`package:intl` is banned in this file, and the failure it prevents is a shifted column.**
  `dd/MM/yyyy HH:mm` is built by hand from `Instant.local`'s components with zero-padding.
  `NumberFormat` on a device set to French emits `4,10` for a weight; the comma is then quoted or not
  depending on the predicate, and every column after the weight moves. Note that layer rule 3
  *permits* `package:intl` in `lib/data/` generally — this is a narrower, file-scoped ban, which is
  why it needs its own rule id rather than relying on the layer table.
- **`localZoneLabel` is a constructor parameter and never a clock read.** R48 confines
  `package:timezone` to `lib/data/notification_scheduler.dart`, and `appNow()` (R23) is the only
  wall-clock reader in the app. The label is derived from `envelope.generatedAt.local` by the caller.
  `09 §10` item 6 goes with it: **`DateTime.timeZoneName` returns an abbreviation on some platforms
  and a full name on others.** Log what each platform actually returns before promising the format
  `IST (UTC+01:00)`, and record the answer in the PR body.
- **`BytesBuilder(copy: false)` and `takeBytes()` are a one-shot pair.** `takeBytes()` empties the
  builder and returns a view over its internal buffer; a second `encode` on the same builder, or a
  `toBytes()` after `takeBytes()`, gives you an empty list. Construct the builder **inside** `encode`
  — which the printed shape does — and do not hoist it to a field to "avoid an allocation".
- **CRLF after the last record too**, including after the last trailer row. Every parser accepts it,
  some Excel versions prefer it.
- **No `sep=;` line, ever.** Excel's sniffing line is Microsoft-proprietary and breaks strict RFC
  4180 parsers; decision #82 rejects it explicitly. The semicolon-delimited reader is served by
  quoting `;`, which the predicate already does — not by a header hack. There is also no delimiter
  setting in v1: a per-user delimiter is a second file format to test.
- **Leading and trailing whitespace is quoted.** `" 412 "` survives; `412` with the spaces trimmed by
  a parser is a different tag. The predicate `!_needsQuote.hasMatch(s) && s.trim() == s` is doing two
  jobs, and the second is easy to delete by accident while "simplifying".
- **`null` is an empty field.** Never the string `null`, never `N/A`, never `-`. A `-` would also
  trip the formula guard, which is how you would find out.

### 5.4 The full test set

`test/features/csv_writer_test.dart` — pure Dart, no database, no `pumpApp`. (The path is
`00-PLAN-CRITIQUE`'s anchor and is preserved verbatim; `CONVENTIONS §4.1`'s mirror convention would
put it in `test/data/`. **Do not move it** — see the epic's Notes.)

| Case | What it asserts |
|---|---|
| `'a field containing a comma, a quote and a newline round-trips per RFC 4180'` | **The anchor.** `she said "kick", then⏎the lamb came` encodes to `"she said ""kick"", then⏎the lamb came"` and decodes back identically through a strict reader written in the test. One record in, one record out — the embedded LF did not create a second row |
| `'each of the nine quoting rows in 09 §2.3 emits exactly what the table says'` | One case per row, table-driven: `412`→`412`; `Ewe, prolapsed`→quoted; `she "kicked"`→`""` doubled; embedded CR/LF→quoted; `prolapse; mastitis`→quoted; `a⇥b`→quoted; `` 412 `` with spaces→quoted; `null`→empty; `-2 lambs born`→`'-2 lambs born` |
| `'the file begins with the UTF-8 BOM and every record ends CRLF, including the last'` | `bytes.take(3)` is `[0xEF, 0xBB, 0xBF]`; the bytes end `0x0D 0x0A`; the count of `\r\n` equals `1 + rows + 6` |
| `'a ragged row throws in release mode as well as in debug'` | A row one field short raises a `StateError` naming both counts and RFC 4180 §2.4. Run it with asserts disabled so the `throw`-not-`assert` property is actually exercised — a debug-only run passes for either implementation |
| `'the formula guard fires on all six leads and on nothing else'` | `=`, `+`, `-`, `@`, TAB, CR are prefixed; `#`, a digit, a letter, a space and a `'` are not. The `#` case is what keeps the trailer readable |
| `'the guard changes the export and never the record'` | Encode a value, then assert the source `String` is unchanged by content and by identity. The §12.4 property, stated at the one place it could be violated |
| `'a zero-row file still carries a header, six trailer records and the BOM'` | 07 §13.2: *"a 0-row CSV still carries its disclaimer trailer."* Seven records total |
| `'every trailer row is padded to the header\'s field count'` | Parse the produced file with the strict reader and assert every record has the same field count. This is the assertion that catches a two-field trailer row |
| `'csv_writer.dart formats no date and no number'` | Source text: no `DateFormat`, no `NumberFormat`, no `toStringAsFixed`, no `package:intl`. Complements the gate row — the gate is the build, this is the reason |
| `'the §12.5 trailer line lists every TimeSource, built from the enum'` | The line contains all three labels joined by `·`, and a fourth enum member would change the line with no edit here. A hand-typed list of three labels is a list that goes stale silently |
| `'encode is deterministic — the same input twice produces identical bytes'` | Two calls, `expect(a, b)`. Cheap, and it catches a hoisted `BytesBuilder` immediately |

`test/domain/uk_zone/csv_local_rendering_test.dart` — `@Tags(['uk-zone'])`, run under
`TZ=Europe/London`:

| Case | What it asserts |
|---|---|
| `'an instant inside the ambiguous hour renders its local time with the offset in force'` | Two instants one hour apart that both render `01:30` locally on the clocks-back Sunday produce **different** `*_at_utc` strings and the **same** `*_at_local` string. Both are correct, and that is exactly why the ISO column sits beside the local one (`09 §2.5` consequence 2). The case exists to prove the pair is never collapsed into one column |
| `'a local rendering never loses its leading zero'` | `01:05`, not `1:5`. Hand-rolled zero-padding is the price of banning `intl`, and it is the thing hand-rolling gets wrong |
| `'the zone label in the trailer is the export instant\'s, not the current clock\'s'` | Build the envelope at a fixed winter instant, run the test in summer, assert the trailer says GMT. `withClock` installs the time; `appNow()` is never called from this file |

### 5.5 The gate rows, proved by hand

A rule nobody has watched fire is indistinguishable from a broken rule:

```bash
printf 'const x = "\\r\\n";\n' > lib/data/_scratch.dart
dart tool/check_policy.dart ; echo "exit=$?"    # POLICY [export.csv_bytes] …, exit=1
rm lib/data/_scratch.dart
```

Repeat with a planted `import 'package:intl/intl.dart';` inside `csv_writer.dart` for
`export.intl_in_writer`.

## 6. Constraints that bind this task

- **The five safety rules** — §12.4 is the one this task touches, and it is held **structurally**: the guard transforms the export, declares itself inside the file, and cannot reach the record because `backup_format.dart` does not call this class. A rule that drops to merely *documented* has been deleted, whatever the prose says.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence. This task adds **no** dependency; that is its whole argument.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'a field containing a comma, a quote and a newline round-trips per RFC 4180'` passes, and was seen to fail first for the stated reason
- [ ] the round trip holds for every quoting case
- [ ] a leading `=`, `+`, `-` or `@` is neutralised
- [ ] the encoding and line ending are recorded decisions, not accidents
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] TAB and CR are in the formula-lead set as well as the four obvious characters
- [ ] the ragged-row guard is a `throw` and has a test that runs with asserts disabled
- [ ] `export.csv_bytes` and `export.intl_in_writer` exist in `tool/check_policy.dart`, have `firesOn` entries in `test/policy/gate_rules_test.dart`, and were each watched to fire on a planted violation
- [ ] `CONVENTIONS §4.7`'s namespace list contains `export`
- [ ] `TimeSource.label` exists, `RecordedTime.provenanceLabel` delegates to it, and `CONVENTIONS §2.2` and `05 §4.1` were amended in **this** commit
- [ ] `pubspec.yaml` and `pubspec.lock` are untouched

## 8. Verification

```bash
fvm flutter test test/features/csv_writer_test.dart
make check
make test
```

Then the release-mode arm of the ragged-row case, and the DST tier:

```bash
fvm flutter test test/features/csv_writer_test.dart --release --plain-name 'ragged'
TZ=Europe/London fvm flutter test --tags uk-zone
```

Then confirm the confinements the rules exist to hold:

```bash
grep -rn '\\r\\n' lib/ --include='*.dart' | grep -v '\.g\.dart'
# expect exactly one file: lib/data/csv_writer.dart

grep -rn 'package:intl' lib/data/csv_writer.dart
# expect nothing

grep -rn 'provenanceLabel' lib/ | grep -v recorded_time.dart
# expect screen-layer call sites only — a writer uses TimeSource.label
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(export): a hand-rolled RFC 4180 CSV writer`
