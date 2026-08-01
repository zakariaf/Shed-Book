# N16-T06 — The warning strip — a query mark that adjusts nothing

| | |
|---|---|
| **Epic** | [N16 — Lambing Entry and the P8 ruling](epic.md) · `00-README` §9 step 6 (2 of 5) |
| **Task** | 7 of 10 |
| **Depends on** | N16-T05 |
| **Commit** | one commit · `feat(lambing_entry): the warning strip that adjusts nothing` |

## 1. Why this task exists

A **declared** birth type that contradicts the strokes prints a query mark in the margin
and **adjusts nothing** — neither value moves in the database. This is the one writer of
`declared_birth_type`, and it exists so the shepherd can say *"I know it says two, it was a twin plus a
mummified"* without the app arguing.

`indelible.md` §6.2 gives the mark its meaning: *"a real auditor's mark. Means the record contradicts
itself and I am not going to fix it for you. Tapping it offers exactly two options and never a
third."* Before this task, `declared_birth_type` had **no writer anywhere in the plan** — a nullable
column, a `WarningCode` and an export column that nothing could ever populate. That is the second half
of critique defect S4.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | **§7.5 (rule 4 in full: `Warning`, `WarningCode`'s eleven members, `Reviewed<T>`, the four structural guarantees, the catalogue with its exact messages, `expectedLambCount`, and *"how it surfaces at 3am"*)** · §7.6 · §4 (`RecordedTime`) | the validator, its entry point, and every code that fires here |
| `docs/design/indelible.md` | **§6.2 mark 3 (the query mark: record face, 28 px, `--madder-ink`, in the margin)** · §2.2 (the contradiction row: word + mark + a 2 px underline under the offending cell) · **§7.9 (`CHANGE TYPE` is reachable only from the type cell or from a query mark)** · §9 screen 4's contradiction paragraph (`CHANGE THE BIRTH TYPE` / `LEAVE IT — TWO IS RIGHT` / `QUERIED · LEFT AS ENTERED 03:47`) | the mark, the two options, and what the app may never do |
| `docs/engineering/07-screens.md` | **§6.5 (the §12 disclosure matrix for this screen, and the six codes that fire)** · §6.3 (the contradiction row — see §5.3 on the conflict) · §6.4 (`declared_birth_type` 1..5 and why 5 is open-ended) | which warnings appear and how they behave |
| `docs/engineering/03-data-model-and-schema.md` | **§5.4 (`declared_birth_type` nullable, and the `lambing_consistency` view with BOTH guards)** · §2 (there is no `warnings` column, anywhere) | the column and the view |
| `docs/engineering/CONVENTIONS.md` | §2.6 (`Warning`, `WarningCode`, `Reviewed<T>`) · §2.9 (`BirthType`) · §2.13 (`setBirthType`) · **R53** (the controller populates `warnings`, never a repository) · R6 · R46 | the types and who may produce them |
| `docs/engineering/02-state-di-navigation.md` | §7 (the `ref.listen` switch, and `WriteCommitted(:final warnings)`) · §4.4 (`.select`) | where the warnings are computed and where they land |
| `docs/engineering/12-testing.md` | **§10.4 (a contradiction warns and does not mutate)** · §2.3 (the ambiguous hour is deliberately not warned about) | the property this task is measured by |
| `docs/engineering/06-design-system.md` | §12 (`ShedBottomSheet` — the only overlay, `enableDrag: false`, `isDismissible: false`) | what the query mark may open |
| `docs/research/00-tech-decisions.md` | §5 · #54 (warnings are pure functions; no `warnings` column; no `fix()`) · #14 (never red-on-yellow) · #106 (colour is never the only channel) | the decisions applied |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-marks-and-strikes` | the query mark is its mark and it never corrects |
| `shed-safety-rules` | §12.4 exactly: flag it, do not fix it |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/lambing_entry_test.dart`
- **Test** — `'a declared type contradicting the strokes prints a query mark and leaves both values unchanged in the database'`
- **Why it is red today** — nothing renders a warning, and `declared_birth_type` has no writer at all.

```bash
fvm flutter test test/features/lambing_entry_test.dart   # expect: failing, for the reason above
```

Sharpen the second clause until it cannot pass by accident. Capture `declared_birth_type` **and** the
lamb ids **before** the mark renders, pump, then re-read both from the database and compare. A test
that only asserts the mark appeared would still pass if the app quietly wrote a third lamb, and that
is precisely the failure §12.4 exists to prevent.

**Green.** The minimum code that passes, and nothing beyond it — the strip over `N06-T03`'s validators, the deliberate declaration path, and a database
read-back proving neither value moved.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step, and say so in the commit message.** `declared_birth_type` and `lambing_consistency`
froze at N07-T04, and there is no `warnings` column to add — that is decision #54's whole point.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/domain/validation/lambing_checks.dart` | **Unchanged, and that is the check.** `List<Warning> checkLambing(Lambing lambing, List<Lamb> lambs)` was written at N06-T03. If this file moves, a validator is being reinvented at the screen |
| 2 | `lib/data/lambing_repository.dart` | **Extended.** `Future<WriteOutcome> setBirthType(LambingId id, BirthType type)` — the **only** writer of `declared_birth_type` in the app. Returns `WriteCommitted()` with the default **empty** `warnings`: a repository is structurally incapable of producing one (R53) |
| 3 | `lib/features/lambing/lambing_entry_controller.dart` | **Extended.** `LambingEntryController` — the screen controller `CONVENTIONS §3.4` names — now has something to hold, and it is where `checkLambing` runs against the freshly-watched row. Also `LambingWriteController.setBirthType` through `guard()` |
| 4 | `lib/features/lambing/widgets/query_mark.dart` | **New.** The margin `?` — record face, 28 px, `--madder-ink` — and the 2 px madder underline under the offending cell. Its target is the whole `68 × 64` margin cell |
| 5 | `lib/features/lambing/widgets/declare_type_sheet.dart` | **New.** `ShedBottomSheet` with `CHANGE THE BIRTH TYPE` and `LEAVE IT`, and the five-value declaration behind the first. Reachable **only** from the type cell or from a query mark |
| 6 | `lib/features/lambing/lambing_entry_screen.dart` | **Extended.** Renders the marks against `Warning.fieldPath`, and scroll-to-field on tap |
| 7 | `lib/l10n/app_en.arb` | **Extended.** The two option labels, the acknowledgement line, and every `Warning.message` — see §5.3 on where the messages live |
| 8 | `docs/engineering/07-screens.md` §6.3 · `docs/engineering/05-domain-correctness.md` §7.5 | **Amended in this commit** if the rendering conflict in §5.3 is ruled, or cited in the PR body if it is carried |
| 9 | `test/features/lambing_entry_test.dart` | **The anchor**, plus the six codes and the two options |
| 10 | `test/policy/contradiction_does_not_mutate_test.dart` | **New.** `12 §10.4` as a property, named for the property (`CONVENTIONS §4.1`) |
| 11 | `test/data/schema_shape_test.dart` | **Extended.** No `warnings` column on any table |
| 12 | `test/domain/uk_zone/dst_test.dart` | **Extended** (created at N04). The two wall-time cases, one of which must produce **no** warning |

### 5.2 The signatures

The one writer, and the reason it can carry no warnings:

```dart
// lib/data/lambing_repository.dart
/// The ONLY writer of `lambings.declared_birth_type` in the app. Reached from
/// the type cell or from a query mark, never from a chooser on the page (P8).
///
/// Returns `WriteCommitted()` with the DEFAULT EMPTY warnings list. `lib/data/`
/// has no import path to `lib/domain/validation/` (layer rule
/// `layer.data_no_validation`, R53), so a repository is structurally incapable
/// of producing a Warning. The CONTROLLER runs the validators.
Future<WriteOutcome> setBirthType(LambingId id, BirthType type);
```

Where the warnings actually come from — the controller, over data it already has:

```dart
// lib/features/lambing/lambing_entry_controller.dart
/// Recomputed on every emission, never persisted. `03 §2`: there is no
/// `warnings` column anywhere in this schema and no `fix()` anywhere in the
/// codebase — a warning cannot be persisted because there is nowhere to put
/// it, and cannot mutate because it holds no writer (decision #54).
List<Warning> warningsFor(LambingEntryData data) =>
    checkLambing(data.lambing.asRow(), data.lambs.map((l) => l.asRow()).toList());
```

The two options, and the sentence that names what the app may not do:

```dart
// lib/features/lambing/widgets/declare_type_sheet.dart
/// EXACTLY two options and never a third (indelible.md §6.2 mark 3):
///   CHANGE THE BIRTH TYPE   -> setBirthType(...)
///   LEAVE IT — TWO IS RIGHT -> records the acknowledgement; the mark STAYS
/// Neither option edits the other value. THE APP NEVER PICKS.
///
/// ShedBottomSheet's required Cancel is the way OUT of the sheet, not a third
/// choice — `isDismissible: false` and `enableDrag: false` are why it has to
/// exist at all (06 §12).
```

### 5.3 The details that are easy to get wrong

- **Two documents describe two different marks, and the authority order settles it.** `07 §6.3` and
  `05 §7.5` both call for *"a persistent, tappable 60 pt amber strip under the field"*; `indelible.md`
  §2.2 and §6.2 call for a **query mark in the margin plus a 2 px madder underline under the offending
  cell**, and Indelible has **no status palette at all** — *"a colour-coded death reads wrong at 4am
  through a wet freezer bag."* `CLAUDE.md`'s authority order puts `docs/design/indelible.md` above the
  thirteen engineering documents, so the mark is the query mark and the underline; **amend `07 §6.3`
  and `05 §7.5`'s 3am paragraph in this commit**, per the amendment rule. If the amendment cannot be
  made here, carry the conflict into the PR body with both sides cited — never resolve it silently by
  building one and leaving the other written down.
- **Everything else in `07 §6.3`'s row survives verbatim.** *Never a dialog, never blocking, never
  twice for one field.* And `05 §7.5` guarantee 3 is absolute: **warnings never gate the write.** A
  blocked write produces a lost record, which is worse than a flagged one, and on this screen there is
  nothing to block anyway — every field committed the moment it was tapped.
- **The controller runs the validator; the repository structurally cannot.** R53 and `05 §7.5`
  guarantee 4: `lib/data/**` has no import path to `lib/domain/validation/**`, enforced as its own
  gate row `layer.data_no_validation`. Repositories return `WriteCommitted(insertedId: …)` with the
  default empty list. If a warning ever appears to come from a repository, an import was added — check
  the gate before the logic.
- **`expectedLambCount(BirthType.quintPlus)` returns `null`, and that is the whole large-litter
  story.** A declared "quad or more" is **open-ended**, so a contradiction is *undefined*, not false.
  Six lambs on a declared 5 must print **no** mark. Encoding `quintPlus` as 5 would put a false query
  mark on every set of sextuplets — the litters a shepherd is most likely to be looking at.
- **`declared_birth_type IS NULL` is not a contradiction either.** `03 §5.4`'s view guards it
  explicitly because `COUNT(…) <> NULL` is `NULL`, which would make `is_mismatched` three-valued for
  every in-progress lambing. The Dart side needs the same guard: no declaration, no query mark.
- **The compared count excludes struck lambs and the label already says so.** A `TWIN (COUNTED, 1
  STRUCK)` row has three `lambs` rows and two strokes; comparing against the raw row count puts a mark
  on a record the shepherd already corrected.
- **There are two mechanisms and they are not duplicates.** `lambing_consistency` (the view) drives
  the persistent badge on the flock list and the ewe card — *"a contradiction found at 3am is still
  findable at 9am"*. `checkLambing` (the pure function) drives the mark on **this** screen. Neither is
  the other's cache, and neither may write.
- **`QUERIED · LEFT AS ENTERED 03:47` is a printed line, so it has to live somewhere — and it may
  never be a `warnings` column.** Decision #54 closes that door permanently: warnings are recomputed
  on read and there is nowhere to persist one. The only append-only home that already exists is a
  `Notes` row against the lambing (`notes.lambing` is a nullable FK for exactly this shape, and
  `Notes` carries the full §12.5 quad after R37). **Take the decision here and state it**: either the
  acknowledgement is a note — recommended, because an ephemeral line vanishes on the next open while
  the mark stays, which reads as the app forgetting the shepherd's answer — or it is explicitly
  session-only and `07 §6.5` says so. Route it to 07 if it is contested; do not invent a column.
- **The mark never adjusts, and neither does the sheet.** Choosing `CHANGE THE BIRTH TYPE` writes the
  new declaration and **leaves the lambs alone**; choosing `LEAVE IT` writes nothing to either.
  `Warning` has no `fix()`, no `corrected` and no callback; `Reviewed<T>` has no `cleaned` getter. Read
  the negative space — the API surface for mutation does not exist, so no amount of call-site
  carelessness produces one.
- **`Warning.fieldPath` is for scroll-to-field, not for editing.** Tapping the mark scrolls to the
  cell. It does not focus it, does not open the keypad and does not pre-fill anything.
- **Never twice for one field.** Two codes can fire on the same cell — a header time can be both
  `lambingInFuture` and `lambingLongBeforeCapture`. Group by `fieldPath` and print one mark; the sheet
  lists what it found.
- **The ambiguous hour is deliberately NOT warned about.** `07 §6.5`, `05 §7.5` and `12 §2.3` DST-2 all
  say so: 01:00–01:59 on 25 October 2026 happens twice, the displayed time still matches what the user
  typed, nothing has been silently corrected from their point of view, and the 60 minutes of ambiguity
  are unambiguous in the exported UTC column anyway. The **spring-forward** hour is the opposite —
  01:30 on 29 March 2026 does not exist, Dart moves it forward with no exception, and
  `timeDoesNotExistLocally` fires with *"The clock skipped 01:30 that night (clocks went forward).
  Saved as 02:30."* Both cases belong in the suite; adding a warning to the first is the failure.
- **Never red-on-yellow, and colour is never the only channel** (decisions #14 and #106). The
  contradiction carries a word (the sentence in the sheet), a mark (the `?`) and geometry (the
  underline). `--madder-ink` is reinforcement, and it is 5.59:1 — it is not the signal.
- **`declared_birth_type` keeps its own value beside the counted one.** Both numbers are preserved
  verbatim (`03 §5.4`), so the type cell prints the declaration **and** `(COUNTED)` beside the
  strokes. Replacing one with the other is the correction §12.4 forbids, wearing a tidier layout.

### 5.4 The full test set

| File · case | What it asserts |
|---|---|
| `test/features/lambing_entry_test.dart` · `'a declared type contradicting the strokes prints a query mark and leaves both values unchanged in the database'` | **The anchor.** Both values captured before, re-read after, and compared |
| `test/features/lambing_entry_test.dart` · `'declaring quad-or-more with six lambs prints no query mark'` | `expectedLambCount` is null for `quintPlus`; a contradiction is undefined, not false |
| `test/features/lambing_entry_test.dart` · `'an undeclared type with three lambs prints no query mark'` | The `NULL` guard, the Dart half of `03 §5.4`'s view comment |
| `test/features/lambing_entry_test.dart` · `'a struck lamb is excluded from the compared count'` | `TWIN (COUNTED, 1 STRUCK)` with three rows prints no mark |
| `test/features/lambing_entry_test.dart` · `'the query mark offers exactly two options and neither edits the other value'` | Two actions in the sheet; `ShedBottomSheet`'s Cancel is not one of them |
| `test/features/lambing_entry_test.dart` · `'choosing LEAVE IT keeps the query mark and changes no stored value'` | The app never picks |
| `test/features/lambing_entry_test.dart` · `'choosing CHANGE THE BIRTH TYPE writes the declaration and touches no lamb row'` | The other option, held to the same standard |
| `test/features/lambing_entry_test.dart` · `'the type cell prints the declared type and the counted type together'` | Both numbers preserved verbatim |
| `test/features/lambing_entry_test.dart` · `'a warning never blocks a write and never opens a dialog'` | Every field still commits; `showDialog(` appears nowhere |
| `test/features/lambing_entry_test.dart` · `'two codes on one field print one mark'` | Grouped by `fieldPath` |
| `test/features/lambing_entry_test.dart` · `'tapping the mark scrolls to the field and does not focus or pre-fill it'` | `fieldPath` is for navigation only |
| `test/features/lambing_entry_test.dart` · `'the contradiction carries a word, a mark and geometry, and the colour is not the signal'` | Decision #106 |
| `test/policy/contradiction_does_not_mutate_test.dart` · `'no code path adjusts a declared type or a lamb count in response to a warning'` | `12 §10.4` as a property; source text over `lib/` for `fix(`, `corrected`, `cleaned` |
| `test/policy/contradiction_does_not_mutate_test.dart` · `'setBirthType is the only writer of declared_birth_type'` | One writer, named, provable by grep and by the gate |
| `test/data/schema_shape_test.dart` · `'no table has a warnings column'` | Decision #54, held at the schema |
| `test/domain/uk_zone/dst_test.dart` · `'a lambing typed at 01:30 on 25 October 2026 produces no warning'` | **`uk-zone`.** The ambiguous hour is deliberately not warned about |
| `test/domain/uk_zone/dst_test.dart` · `'a lambing typed at 01:30 on 29 March 2026 produces timeDoesNotExistLocally and says what it was saved as'` | **`uk-zone`.** The nonexistent hour is the opposite case, and Dart corrects it silently unless we surface it |

## 6. Constraints that bind this task

- **The five safety rules** — §12.4 is held at *unrepresentable* and *unpersistable*: `Warning` holds no writer, `Reviewed<T>` exposes no cleaned value, there is no `warnings` column, and `lib/data/` cannot import `lib/domain/validation/` at all. A rule that drops to merely *documented* has been deleted, whatever the prose says.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures. The query mark's target is the whole `68 × 64` margin cell, and the sheet does not drag or dismiss.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key. There is no later sweep; N33 only verifies.
- **Never a dialog** — `ui.show_dialog` is a gate row outside the two allowlisted destructive files, and this is not one of them.
- **Vocabulary** — one word per concept (`CLAUDE.md`). It is **warning**, never *flag*, *issue* or *validation error* (R71) — in prose and in code. The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'a declared type contradicting the strokes prints a query mark and leaves both values unchanged in the database'` passes, and was seen to fail first for the stated reason
- [ ] both values are unchanged after the warning renders
- [ ] the mark is a query mark, not an error
- [ ] the controller runs the validator — the repository still cannot import it
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `setBirthType` is the **only** writer of `declared_birth_type`, and a test names it
- [ ] a declared `quintPlus` with six lambs prints no mark, and an undeclared type prints no mark
- [ ] struck lambs are excluded from the compared count
- [ ] the sheet offers exactly two options, neither of which edits the other value
- [ ] the type cell prints the declared type and the counted type together
- [ ] no `warnings` column exists on any table, and `fix(`, `corrected` and `cleaned` appear nowhere under `lib/`
- [ ] the rendering conflict between `indelible.md` and `07 §6.3` / `05 §7.5` is either amended in this commit or carried into the PR body with both sides cited
- [ ] where the `LEFT AS ENTERED` acknowledgement lives is decided and written down — and it is not a column
- [ ] both DST cases exist and are tagged `uk-zone`: no warning in the ambiguous hour, `timeDoesNotExistLocally` in the nonexistent one

## 8. Verification

```bash
fvm flutter test test/features/lambing_entry_test.dart
fvm flutter test test/policy/contradiction_does_not_mutate_test.dart
fvm flutter test test/data/schema_shape_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

```bash
grep -rn "domain/validation" lib/data/        # expect zero — the R53 mechanism
grep -rn "fix(\|corrected\|cleaned" lib/      # expect zero
grep -rn "declared_birth_type\|declaredBirthType" lib/data/   # expect one writer only
grep -rn "showDialog(" lib/features/lambing/  # expect zero
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(lambing_entry): the warning strip that adjusts nothing`
