# N04-T04 — `RecordedTime` and `TimeSource` — provenance as part of the value

| | |
|---|---|
| **Epic** | [N04 — Domain: time and units](epic.md) · `00-README` §9 step 2 (1 of 3) |
| **Task** | 4 of 8 |
| **Depends on** | N04-T03 |
| **Commit** | one commit · `feat(domain): RecordedTime and TimeSource — provenance in the value` |

## 1. Why this task exists

§12.5 made unrepresentable: the time and where it came from are **one value**, so a
timestamp cannot be stored without its provenance. `TimeSource` is a closed enum —
captured / entered / corrected — and `provenanceLabel` is an exhaustive switch that can never return
an empty string.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §4.1 | the type printed in full — three fields, three factories, `editedTo`, `isEdited`, `provenanceLabel`, `entryLag` |
| `docs/engineering/05-domain-correctness.md` | §4.2, §4.3, §4.4 | the four columns and their paired `CHECK`s, the render/export rules, and the three tests this task must contain |
| `docs/engineering/CONVENTIONS.md` | §2.2, §2.9, §4.6 | the member list, the frozen stored keys, and the `captured_at` / `original_effective` / `time_source` column names (R37, R38) |
| `docs/engineering/07-screens.md` | §1.5, §2.4, the timeline row spec | the three labels, verbatim, and *"a bare `03:21` is a review failure"* |
| `docs/research/00-tech-decisions.md` | §2.E #53, #108 | `RecordedTime`; `en` only in v1, which is why the label is English in the domain |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-safety-rules` | §12.5 is its rule and this is the mechanism that holds it |
| `shed-domain` | the value type, its ordering and its label |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/time/recorded_time_test.dart`
- **Test** — `'provenanceLabel is exhaustive and never returns an empty string'`
- **Why it is red today** — nothing carries provenance, so a corrected time is indistinguishable from a captured one.

```dart
// `05` §4.4's shape — the switch in the test mirrors the switch in the type, so a
// fourth TimeSource member breaks BOTH at compile time, which is the mechanism.
for (final s in TimeSource.values) {
  final rt = switch (s) {
    TimeSource.autoCaptured => RecordedTime.capture(t0),
    TimeSource.userEntered  => RecordedTime.entered(effective: t0, now: t1),
    TimeSource.userEdited   => RecordedTime.capture(t0).editedTo(t1),
  };
  expect(rt.provenanceLabel, isNotEmpty);
}
```

```bash
fvm flutter test test/domain/time/recorded_time_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the value type with a required source, the closed enum, and the exhaustive switch — no
`default:` arm, so a new source is a compile error at every call site.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 step 2 (domain) and step 7 (tests). Step 1 is skipped and it matters more here than
anywhere else in this epic: the §12.5 **provenance quad** — `occurred_at`, `captured_at`,
`original_effective`, `time_source` plus its two paired `CHECK`s — lands on eight tables in N07, and
R37 requires it **before the first schema snapshot**. This task fixes the shape those columns must
carry. Say so in the commit message.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `test/domain/time/recorded_time_test.dart` | new | The anchor, written first |
| 2 | `lib/domain/time/recorded_time.dart` | new | Both types in one file (CONVENTIONS §2.2 places `TimeSource` here, not in its own). Three fields, one private generative constructor, two factories, one `editedTo`, three getters |

Not touched, and deliberately: `lib/domain/time/instant.dart` (this type holds three `Instant`s and
teaches `Instant` nothing), and `lib/core/db/tables/**` (N07's).

### 5.2 The signature

`05` §4.1 prints this in full. Copy it, comments included:

```dart
// lib/domain/time/recorded_time.dart
enum TimeSource {
  autoCaptured('auto'),
  userEntered('entered'),
  userEdited('edited');

  const TimeSource(this.key);
  /// Frozen. Written to SQLite, CSV and the JSON backup. Never localised.
  final String key;

  static TimeSource fromKey(String k) =>
      TimeSource.values.firstWhere((s) => s.key == k,
          orElse: () => throw FormatException('Unknown time source', k));
}

final class RecordedTime {
  /// The value that counts: when the event happened.
  final Instant effective;

  /// When the row was first written. Never changes. Never editable.
  final Instant capturedAt;

  /// Present only when [source] is userEdited: the FIRST effective value ever
  /// held, preserved across an unbounded chain of edits.
  final Instant? originalEffective;

  final TimeSource source;

  const RecordedTime._(this.effective, this.capturedAt, this.originalEffective, this.source);

  /// Auto-captured: effective == the moment of the write.
  factory RecordedTime.capture(Instant now) =>
      RecordedTime._(now, now, null, TimeSource.autoCaptured);

  /// The user typed a time at creation — a deferred entry. It was never wrong.
  factory RecordedTime.entered({required Instant effective, required Instant now}) =>
      RecordedTime._(effective, now, null, TimeSource.userEntered);

  /// There is no setter and no way to clear [originalEffective].
  RecordedTime editedTo(Instant newEffective) => RecordedTime._(
      newEffective, capturedAt, originalEffective ?? effective, TimeSource.userEdited);

  bool get isEdited => source == TimeSource.userEdited;

  /// Never empty: the label is part of the value, by exhaustive switch.
  String get provenanceLabel => switch (source) {
        TimeSource.autoCaptured => 'recorded automatically',
        TimeSource.userEntered  => 'time entered by you',
        TimeSource.userEdited   => 'time edited by you',
      };

  /// The time it takes an entry to reach the app. Only meaningful because
  /// [capturedAt] is immutable; it is how spec §15's "within five minutes of
  /// the event" is measurable at all.
  Duration get entryLag => capturedAt.difference(effective);
}
```

The three label strings are `07-screens.md`'s, verbatim: `recorded automatically` /
`time entered by you` / `time edited by you`. Not paraphrases, not sentence case, no full stop.

### 5.3 The details that are easy to get wrong

1. **`originalEffective ?? effective` — the `??` is the whole feature.** On the *first* edit,
   `originalEffective` is null and `effective` is the value being replaced, so the pre-edit value is
   captured. On every later edit, `originalEffective` is already set and is passed through unchanged.
   Write `originalEffective = effective` instead and the chain keeps only the *previous* value; the
   type then records *that* a time was edited and loses *what it was edited from*, which is `05`
   §4.3's named anti-pattern and makes the §12.5 label true but uninformative.
2. **`capturedAt` never moves, including on an edit.** It is *when we found out*. `editedTo` passes
   `capturedAt` through untouched. A `copyWith` that accepts `capturedAt` is an anti-pattern named in
   `05` §4.3 — do not add a `copyWith` at all.
3. **The third member is `userEdited`, key `'edited'` — not "corrected".** §1 above says
   *"captured / entered / corrected"* as loose prose; the code and the stored key do not. The word
   *correct* is reserved for the thing safety rule 4 **bans** (the app silently correcting a user's
   entry). An edit is the user's own act and is labelled as theirs. Swapping the two words in a doc
   comment or a commit message is a review finding.
4. **`entered` and `edited` are different facts and must not be merged.** A deferred entry typed at
   07:00 for an 03:20 lambing *was never wrong*; an edited one *was*. Merging them into a single
   "user-supplied" state loses the distinction the §12.5 label exists to make.
5. **The keys `'auto'`, `'entered'`, `'edited'` are frozen forever.** They go into SQLite, into every
   CSV `time_source` column and into every JSON backup, and a v1.0 backup is restored by v1.9.
   `05` §4.4's literal-list test — `expect(TimeSource.values.map((s) => s.key).toList(), ['auto', 'entered', 'edited'])`
   — looks like a tautology and is the cheapest possible guard on the one thing in this file that
   cannot be changed later. It ships.
6. **Export the key, never the label.** `05` §4.3: CSV carries `time_source` as the *stable key*; the
   PDF carries a dagger `†` plus a footer legend; the JSON backup carries all four fields so a restore
   is lossless. `provenanceLabel` is for screens only. Exporting the localised label instead of the
   key is a named anti-pattern.
7. **No `default:` arm in `provenanceLabel`, ever.** With the switch exhaustive over a closed enum, a
   fourth `TimeSource` is a compile error at this site *and* at every call site. Add a `default:` and
   the compiler stops helping, silently, and a fourth source ships with an empty label.
8. **English in the domain is deliberate and bounded.** D4 bans `package:intl` and `AppLocalizations`
   from `lib/domain/`, and `provenanceLabel` is one of exactly two documented exceptions (the other is
   `Disclaimers`). It is correct today because v1 ships `en` only (decision #108). If a second locale
   ever ships, the label moves to ARB and the exhaustive-switch test moves with it. Do not
   pre-emptively move it now.
9. **The paired `CHECK` you are designing for, even though you do not write it here.**
   `CHECK ((time_source = 'edited') = (original_effective IS NOT NULL))` makes *"edited but we lost
   what it was edited from"* unstorable. Your Dart must never be able to produce that pair: no public
   constructor, no `copyWith`, no way to clear `originalEffective`. That is why the generative
   constructor is private and there are exactly two factories.
10. **`entryLag` is `capturedAt.difference(effective)` — that order.** A deferred entry has a
    *positive* lag. It is a diagnostics measure only; `05` §4.3 forbids ever displaying it to the user
    as a judgement.
11. **This file has no clock.** `RecordedTime.capture(Instant now)` takes `now`; it does not read it.
    The single call site that reads is a repository calling `appNow()` **once per mutation**
    (`00-README` §8 step 3, item 10).

### 5.4 The full test set — `test/domain/time/recorded_time_test.dart`

Zone-agnostic — every `Instant` here is built from a `DateTime.utc` or from an integer, so the file
passes identically under `TZ=Pacific/Chatham`. No `@Tags`.

| Case | What it pins |
|---|---|
| `'provenanceLabel is exhaustive and never returns an empty string'` | **the anchor.** The `for (final s in TimeSource.values)` loop in §4 |
| `'capture sets effective == capturedAt and no original'` | `RecordedTime.capture(t0)` → `effective == capturedAt == t0`, `originalEffective == null`, `source == autoCaptured` |
| `'entered keeps the typed time and stamps the write separately'` | `entered(effective: t0320, now: t0700)` → `effective == t0320`, `capturedAt == t0700`, `originalEffective == null`, `isEdited == false` |
| `'editing preserves the ORIGINAL across many edits'` | `05` §4.4 verbatim: `entered(effective: t7am, now: t7am).editedTo(t0330).editedTo(t0320).editedTo(t0315)` → `effective == t0315`, `originalEffective == t7am` (**the first, not the previous**), `capturedAt == t7am`, `source == userEdited` |
| `'editing an auto-captured time keeps the captured instant'` | `capture(t0).editedTo(t1)` → `capturedAt == t0`, `originalEffective == t0`, `effective == t1` |
| `'editing back to the original value still reads as edited'` | `capture(t0).editedTo(t1).editedTo(t0)` → `isEdited` is true and `originalEffective == t0`. Undoing an edit is not the same as never having edited |
| `'time_source keys are FROZEN'` | `05` §4.4 verbatim: `['auto', 'entered', 'edited']`, with a `reason:` naming the exports that depend on it |
| `'fromKey round-trips every member and throws on anything else'` | all three keys round-trip; `fromKey('captured')`, `fromKey('corrected')`, `fromKey('')` all throw `FormatException` — the three most likely wrong spellings |
| `'entryLag is capturedAt minus effective'` | a deferred entry has a positive lag equal to the gap; an auto-captured one has `Duration.zero` |
| `'there is no way to clear originalEffective'` | source read of `recorded_time.dart`: no `copyWith`, no `set `, no second generative constructor, and exactly one `RecordedTime._(` per factory plus one in `editedTo` |
| `'provenanceLabel has no default arm'` | source read: the `switch (source)` block contains no `default:` and no `_ =>` |
| `'the labels are 07-screens.md's, verbatim'` | the three strings pinned literally, character for character |
| `'a time recorded in the ambiguous hour carries its provenance unchanged'` | build `capture` from `Instant(DateTime.utc(2026, 10, 25, 0, 30).millisecondsSinceEpoch)` and from `Instant(DateTime.utc(2026, 10, 25, 1, 30).millisecondsSinceEpoch)` — the two candidate instants of the repeated 01:00–01:59 hour. Both are `autoCaptured`, both have `entryLag == Duration.zero`, and they are **not equal**. Provenance is orthogonal to the ambiguity; the wall-clock form of the same hour is DST-2 in N04-T08 |

## 6. Constraints that bind this task

- **The five safety rules** — rule 5 (timestamps carry provenance), held at **unrepresentable**: `RecordedTime` cannot be constructed without a `TimeSource`, because the generative constructor is private and both factories set one. `05` §7.1 lists this as the mechanism for §12.5, and it is the shape the eight-table provenance quad in N07 is built to match. A public constructor here drops rule 5 to *documented*, which counts as deleted.
- **`layer.domain`** — `dart:*`, `package:meta`, `package:collection`, `lib/domain/` only. No `intl` — `provenanceLabel` is one of D4's two documented exceptions and it is a `const` English string, not a formatted one.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. Here specifically: **provenance**, never *audit*, never bare *source*, never *metadata* (CONVENTIONS §5.1).

## 7. Definition of Done

- [ ] `'provenanceLabel is exhaustive and never returns an empty string'` passes, and was seen to fail first for the stated reason
- [ ] a time cannot be constructed without a source
- [ ] `provenanceLabel` has no `default:` arm and no empty return
- [ ] the labels are the ones `07-screens.md` prints, not paraphrases
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/time/recorded_time_test.dart
fvm flutter test test/domain/time
TZ=Pacific/Chatham fvm flutter test test/domain/time
dart analyze lib/domain/time/recorded_time.dart
dart run tool/check_policy.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): RecordedTime and TimeSource — provenance in the value`
