# N16-T05 — Care events as `EXISTS`

| | |
|---|---|
| **Epic** | [N16 — Lambing Entry and the P8 ruling](epic.md) · `00-README` §9 step 6 (2 of 5) |
| **Task** | 6 of 10 |
| **Depends on** | N16-T04 |
| **Commit** | one commit · `feat(lambing_entry): care events as EXISTS rows, never booleans` |

## 1. Why this task exists

Colostrum (with volume and method), navel dip, stomach tube, warmed — stored as **rows**,
so *not recorded* and *no* stay different facts. A checkbox that defaults to false is a claim the app
made on the shepherd's behalf.

`indelible.md` §7.10 puts the same argument in one sentence: *"There is no checkbox glyph, because a
tick is a state and this system does not record states — it records events. Ticking `colostrum given`
at 03:24 records that you ticked it at 03:24, which is a materially better record and costs nothing."*
It is also what gives the colostrum reminder something to be completed **from** at N24 — completing
the reminder writes the `CareEvent`; it is the same tap.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | **§5.6 (`CareEvents`: the four-value closed `CHECK` on `kind`, the exactly-one subject `CHECK`, `volume_ml BETWEEN 1 AND 2000`, `method IN ('teat','tube','bottle')`, and the full §12.5 quad)** · §2.1 (P1's `struck` / `struck_at`) | every column and constraint |
| `docs/design/indelible.md` | **§7.10 (the check control: unset / done / pressed / undone / never disabled, `DONE 03:24`, `D̶O̶N̶E̶ ̶0̶3̶:̶2̶4̶ · UNDONE 03:31`)** · §7.7 (`DONE` is an unboxed stamp) · §7.12 (no placeholder in a field) · §9 screen 4 (*"the four care checks are 64 px lines that stamp a time when pressed"*) | how a care line prints, in all five states |
| `docs/engineering/07-screens.md` | **§6.2 (*"care checkbox state is `EXISTS` over these rows, never a boolean column"*)** · §6.4 (the care tap costs; colostrum volume and method are 2 more, skippable) · §15.1 (`addCare` and `removeCare`, and their undo) | where the state comes from and what it costs |
| `docs/engineering/CONVENTIONS.md` | §2.13 (`addCare` / `removeCare` return `WriteOutcome`) · §2.9 (**a Dart member and its stored key must be readable off each other**) · §2.1 (`CareEventId`) · §4.6 (`occurred_at` and the provenance trio) · R37 · R53 | the verbs and the types |
| `docs/engineering/05-domain-correctness.md` | §4.1–§4.2 (`RecordedTime` and the quad — `CareEvents` carries it) · §7.3 (**the origination line: never originate a number that is a clinical decision**) | the time, and the volume rule |
| `epics/N00-…/N00-T05` | the P1 ruling | which tables carry `struck` / `struck_at`, and therefore whether `removeCare` strikes or deletes |
| `docs/research/00-tech-decisions.md` | §5 · #43 (care state is `EXISTS`, never a boolean) · #65 (the notification channel ids, frozen at release) · #31 (no `DEFAULT` on a column that could encode advice) | the decisions applied |
| `shed-book-spec.md` | §7.2 (*"care checkboxes: colostrum given (with volume/method), navel dipped, stomach tubed, warmed"*) · §12.2 · §12.4 | the four kinds and the two rules |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | each care event is an append-only row written immediately |
| `shed-safety-rules` | a false default is the app originating a fact — §12.4 |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/lambing_entry_test.dart`
- **Test** — `'an unrecorded care event renders as not recorded, never as no'`
- **Why it is red today** — nothing records care events, and the obvious implementation is four booleans.

```bash
fvm flutter test test/features/lambing_entry_test.dart   # expect: failing, for the reason above
```

Sharpen it in two directions. On the **screen**: assert the unset line renders its own words and that
the strings `No`, `Not given` and `0` appear nowhere on a care line — the failure mode is not a missing
label, it is a plausible wrong one. In the **schema**: assert no table anywhere has a column matching
`colostrum`, `navel`, `tube` or `warmed`, so the boolean cannot come back through a migration either.

**Green.** The minimum code that passes, and nothing beyond it — the `EXISTS` reads, the write verbs, and the three-state rendering.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step, and say so in the commit message.** `CareEvents` froze at N07-T04. This task writes
rows into a table that already forbids the alternative.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/domain/care_kind.dart` | **New.** `enum CareKind` and `enum ColostrumMethod`, each member carrying its stored key, plus the sealed `CareSubject`. §2.9's rule is that a Dart member and its stored key are readable off each other; a bare `String kind` crossing the repository boundary is exactly what that rule exists to prevent |
| 2 | `docs/engineering/CONVENTIONS.md` §1, §2.9, §6 | **Extended, in this commit.** One tree line, three rows in the stored-key table, one numbered ruling. The next free number after T04's is **R77** |
| 3 | `lib/data/lambing_repository.dart` | **Extended.** `addCare` and `removeCare`. One `db.transaction` each, `appNow()` once, `RecordedTime.capture(now)` written into the quad, `newUid()`, and `season` copied from the parent lambing |
| 4 | `lib/features/lambing/lambing_entry_controller.dart` | **Extended.** `LambingWriteController.addCare` and `.removeCare` through `guard()` |
| 5 | `lib/features/lambing/widgets/care_line.dart` | **New.** The 64 px ruled line: label left, a `64 × 64` target right, and the five states from `indelible.md` §7.10. **No checkbox glyph** |
| 6 | `lib/features/lambing/widgets/colostrum_detail.dart` | **New.** Volume and method, both skippable, both without a placeholder and without a default. Volume goes through `ShedKeypad` (decision #57 — the only numeric entry route in the app) |
| 7 | `lib/features/lambing/lambing_entry_screen.dart` | **Extended.** Mounts the four lines under the ease row |
| 8 | `lib/l10n/app_en.arb` | **Extended.** The four care labels, `DONE`, `UNDONE`, the *not recorded* label, the volume and method labels and every `semanticLabel` — each with a `description`. **No message may say `No`** for an unrecorded care event |
| 9 | `docs/engineering/07-screens.md` §15.1 | **Amended only if P1 says so** — see §5.3 on `removeCare` |
| 10 | `test/features/lambing_entry_test.dart` | **The anchor**, plus the five states and the volume cases |
| 11 | `test/data/lambing_repository_test.dart` | **Extended.** The two verbs, the constraints and the subject rule |
| 12 | `test/data/schema_shape_test.dart` | **Extended** (created at N07). No boolean care column, on any table |
| 13 | `test/data/lambing_ambiguous_hour_test.dart` | **Extended.** Colostrum recorded inside the repeated hour |

### 5.2 The signatures

The three closed sets, each member carrying the string the schema stores:

```dart
// lib/domain/care_kind.dart — R77
/// `kind` is a CLOSED CHECK, not a vocabulary FK: these four are the ones spec
/// §7.2 names and each is wired to an Android notification channel id that is
/// byte-identical to the key and frozen at release (decision #65, R49). Adding
/// a fifth is a schema migration AND a channel decision — the correct amount
/// of friction.
enum CareKind {
  colostrum('colostrum'),
  navelDip('navel_dip'),
  stomachTube('stomach_tube'),
  warmed('warmed');
  const CareKind(this.key);
  final String key;
}

enum ColostrumMethod { teat('teat'), tube('tube'), bottle('bottle'); … }

/// `care_events` has `CHECK ((lambing IS NOT NULL) + (lamb IS NOT NULL) = 1)`
/// — EXACTLY one. Two nullable id parameters make the unstorable combination
/// CONSTRUCTIBLE, and the CHECK then fires as a WriteFailed at 03:20 instead
/// of as a compile error at 09:00.
sealed class CareSubject { const CareSubject(); }
final class CareForLamb    extends CareSubject { const CareForLamb(this.lamb); final LambId lamb; }
final class CareForLambing extends CareSubject { const CareForLambing(this.lambing); final LambingId lambing; }
```

The verbs, filling in `CONVENTIONS §2.13`'s ellipsis:

```dart
// lib/data/lambing_repository.dart
Future<WriteOutcome> addCare(
  CareSubject subject, {
  required CareKind kind,
  int? volumeMl,               // NO default. Never suggested. §12.2.
  ColostrumMethod? method,     // NO default.
});

Future<WriteOutcome> removeCare(CareEventId id);
```

### 5.3 The details that are easy to get wrong

- **There are two states on a care line, not three, and the missing one is deliberate.** *Not
  recorded* and *done* exist; **there is no way to record "no"**. A shepherd who did not dip a navel
  has recorded nothing, and the app must not turn that into a claim. `07 §6.2` and decision #43 are
  why the state is `EXISTS` over rows: *"that keeps 'colostrum given at 03:22' recoverable."* A
  boolean column would delete both facts at once.
- **The `EXISTS` is derived from the one statement, not from a second query.** T01's statement already
  returns the care rows joined to their lamb. The presence check is
  `lamb.care.any((c) => c.kind == CareKind.navelDip.key)` in Dart, over data already in hand. Adding an
  `EXISTS` subquery would be a second content stream and `07 §1.2` forbids it; the word `EXISTS` in
  that sentence names the **shape of the state**, not a SQL construct to go and write.
- **`removeCare` should strike, not delete — and P1 is what decides it.** `07 §15.1` predates P1 and
  says the undo of `removeCare` is *"re-insert with the original `RecordedTime`"*, which implies the
  row was deleted. But `indelible.md` §7.10's **Undone** state prints
  `D̶O̶N̶E̶ ̶0̶3̶:̶2̶4̶ · UNDONE 03:31` — a struck stamp beside a new one — and that is unrenderable if the row
  is gone. P1 (ruled at N00-T05) puts `struck` / `struck_at` on every table it names through
  `mixin Identified`. **Read N00-T05's table list; do not infer it from the mixin.** If `care_events`
  is on it, `removeCare` sets `struck` / `struck_at`, the line renders `indelible.md`'s Undone state,
  and `07 §15.1`'s row is amended in this commit per the amendment rule. Indelible rule 1 — *"if a
  proposal makes information disappear from the page, it is wrong"* — is binding, not advisory.
- **`volume_ml BETWEEN 1 AND 2000` is a unit-slip guard and never a dose.** `03 §5.6` says so in the
  schema comment and `05 §7.3` gives the line that settles every case like it: *the app may
  arithmetic-transform a number the user supplied; it may never originate a number that is a clinical
  decision.* No default volume, no suggested volume, no "typical" figure in a hint, no last-value
  autofill. The field is empty until the shepherd types, exactly like the withdrawal-days field.
- **No placeholder text inside the volume field** (`indelible.md` §7.12). *"In the dark, a grey
  placeholder is indistinguishable from an entered value."* The label goes **above** the line, in the
  control voice; the value sits on the rule.
- **A rejected volume is a failure, never a correction.** 3000 ml trips the `CHECK`; the write returns
  `WriteFailed` and the screen shows `failure.userMessage`. It must not clamp to 2000, must not round,
  and must not silently drop the column — all three are §12.4 with a helpful face on.
- **Volume goes through `ShedKeypad`** (decision #57, R70). It is the only number-entry route in the
  app, it lives in `lib/core/ui/components/`, and a `TextField` with a numeric keyboard is the thing
  it exists to replace.
- **The subject is exactly one of lambing or lamb, and the type should make the other unbuildable.**
  On this screen every care event is written against a **lamb**; the lambing arm exists for care taken
  before any lamb is attached, and T01's `LEFT JOIN` second arm is what reads those back. Two nullable
  parameters compile and then fail at 3am.
- **`season` is copied from the parent lambing inside the transaction.** `care_events.season` is
  `NOT NULL` with `ON DELETE CASCADE`; reading it from the screen's copy is one frame stale, and
  getting it wrong scopes the row into the wrong season's statistics forever.
- **`CareEvents` carries the full provenance quad, and that permits an edit verb — it does not
  require one.** The standing rule runs one way only: *a table without the quad has no edit verb*
  (`05 §4.2`). `07 §6.4` gives this screen exactly one time-editing action and it is the **lambing's**
  header time (T07). Do not add a per-care-event time picker here.
- **The four kinds are frozen and each is a channel id.** R49: there is one set of strings, `03`'s,
  and the Android channel id is byte-identical to the kind. `turnout`, `dose` and `withdrawal` are
  banned channel ids for the same reason. Channel ids are frozen at release, so a fifth care kind is
  two decisions, not one.
- **N24 writes the colostrum and navel reminder rows inside `addCare`'s transaction.** Critique defect
  S10. Leave the boundary commented so the next epic extends it rather than opening a second one, and
  so that completing a reminder and writing the care event stay the same tap (`03 §5.6`).
- **Never disabled** (`indelible.md` §7.10). A care line is always pressable. A dead control under a
  cold thumb is indistinguishable from a missed tap.
- **A double-fired press writes one row.** `guard()`, and the test has no pump between the taps.

### 5.4 The full test set

| File · case | What it asserts |
|---|---|
| `test/features/lambing_entry_test.dart` · `'an unrecorded care event renders as not recorded, never as no'` | **The anchor.** The unset line's own words, and `No`, `Not given` and `0` appear on no care line |
| `test/features/lambing_entry_test.dart` · `'recording colostrum prints DONE with the time it was pressed'` | The stamp is unboxed, the time is tabular, and the row exists in `care_events` |
| `test/features/lambing_entry_test.dart` · `'removing a care event leaves DONE struck and prints UNDONE with its own time'` | `indelible.md` §7.10's Undone state; the line does not revert to unset |
| `test/features/lambing_entry_test.dart` · `'no care line renders a checkbox glyph and no care line is ever disabled'` | Source text and widget state |
| `test/features/lambing_entry_test.dart` · `'colostrum volume and method are empty until typed, with no placeholder inside the field'` | `indelible.md` §7.12 and §12.2 together |
| `test/features/lambing_entry_test.dart` · `'volume is entered on ShedKeypad and no TextField with a numeric keyboard exists'` | Decision #57 |
| `test/features/lambing_entry_test.dart` · `'a double-fired care press writes one row'` | `guard()`, no pump between the taps |
| `test/data/lambing_repository_test.dart` · `'addCare writes the full provenance quad and copies season from the lambing'` | Four columns and the scope, read back |
| `test/data/lambing_repository_test.dart` · `'a volume of 3000 is refused and surfaces as WriteFailed, never clamped'` | The `CHECK` fires; nothing rounds, nothing drops the column |
| `test/data/lambing_repository_test.dart` · `'addCare cannot be called with both a lambing and a lamb'` | The sealed subject: the unstorable combination does not compile |
| `test/data/lambing_repository_test.dart` · `'a care event recorded before the first lamb attaches to the lambing'` | The other arm, and T01's `LEFT JOIN` reads it back |
| `test/data/lambing_repository_test.dart` · `'CareKind and ColostrumMethod keys match the schema CHECKs exactly'` | Four kinds, three methods, byte-identical, frozen |
| `test/data/schema_shape_test.dart` · `'no table has a boolean column for a care event'` | Scans every table for `colostrum`, `navel`, `tube`, `warmed`. The boolean cannot return through a migration either |
| `test/data/lambing_ambiguous_hour_test.dart` · `'colostrum recorded at 01:30 in the repeated hour keeps its own occurred_at through a reopen'` | **`uk-zone`.** A care event's time is its own, not the lambing's, and it survives the file |

## 6. Constraints that bind this task

- **The five safety rules** — §12.4 is held at *unpersistable* here: there is no boolean column to default, so *not recorded* cannot become *no*. §12.2 is held at the volume field: no default, no suggestion, no clamp. A rule that drops to merely *documented* has been deleted, whatever the prose says.
- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **3am** — every interactive element ≥ 64 × 64, 18 px text floor, dark only, no banned gesture. A care line is **never** disabled, and volume is entered on the app's own keypad.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key. There is no later sweep; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'an unrecorded care event renders as not recorded, never as no'` passes, and was seen to fail first for the stated reason
- [ ] no boolean column anywhere for a care event
- [ ] *not recorded* renders as its own words
- [ ] colostrum carries volume and method when they are given, and neither is defaulted
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] there is no way on this screen to record *no* — only *done* and *not recorded* exist
- [ ] the presence check is derived from the one statement; no second query and no `EXISTS` subquery appears
- [ ] `removeCare`'s shape follows N00-T05's P1 table, and `07 §15.1` is amended in this commit if it does
- [ ] a rejected volume surfaces as a failure and is never clamped, rounded or dropped
- [ ] volume is entered on `ShedKeypad`, with no placeholder inside the field
- [ ] `addCare` cannot be called with both a lambing and a lamb
- [ ] `CareKind` and `ColostrumMethod` are added to `CONVENTIONS §1` and §2.9 under one numbered ruling, in this commit
- [ ] `addCare` writes the full provenance quad and copies `season` from the parent lambing
- [ ] no care line carries a checkbox glyph and none is ever disabled
- [ ] the ambiguous-hour case exists and is tagged `uk-zone`

## 8. Verification

```bash
fvm flutter test test/features/lambing_entry_test.dart
fvm flutter test test/data/lambing_repository_test.dart
fvm flutter test test/data/schema_shape_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

```bash
grep -rn "colostrumGiven\|navelDipped\|stomachTubed\|isWarmed" lib/   # expect zero — no booleans
grep -rn "TextField\|TextFormField" lib/features/lambing/              # expect zero on the volume path
grep -rn "hintText\|placeholder" lib/features/lambing/                 # expect zero
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(lambing_entry): care events as EXISTS rows, never booleans`
