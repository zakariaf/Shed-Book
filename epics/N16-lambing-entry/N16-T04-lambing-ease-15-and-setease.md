# N16-T04 — Lambing ease 1–5 and `setEase`

| | |
|---|---|
| **Epic** | [N16 — Lambing Entry and the P8 ruling](epic.md) · `00-README` §9 step 6 (2 of 5) |
| **Task** | 5 of 10 |
| **Depends on** | N16-T03 |
| **Commit** | one commit · `feat(lambing_entry): lambing ease 1-5, the one surviving segmented choice` |

## 1. Why this task exists

The **one surviving segmented choice** in the product, over `ShedChoiceRow`. Five values,
the ordinal ruled in N00-T04, each with its authored description from `assets/content/`.

Ease is one of the two fields spec §7.2 says actually matter, and it is the ordinal every later
assisted-rate statistic is computed from — so a scale that changes after data exists is a migration on
somebody else's phone.

**Correction to the line above, and it matters:** the descriptions do **not** come from
`assets/content/`. R66 gives them three homes with no overlap — the keys `ease_1`…`ease_5` are seeded
into `vocab_terms`, the labels are ARB messages in `lib/l10n/app_en.arb`, and `assets/content/` holds
only prose too long to be a UI string plus one provenance line per list. That split is what makes the
scale **user-editable without ever being overwritten** by an app update.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/design/indelible.md` | **§7.9 (segmented choice: five `64 × 64` buttons, 8 px gaps, `64 × 5 + 8 × 4 = 352` inside 361; selected = `--slab` fill + 2 px `--ink-full` border + a 2 px `--madder-rule` underline the full button width + `EASE 3 · SOME ASSISTANCE` printed to the right; unset = a dotted rule under the whole group)** · §3.6 (**the one documented component wrap: 3 + 2 at `116 × 80`, at ≥ 150%**) · §5.1 (a press is a fill change, 40 ms) · §7.7 (stamps) | every pixel and state of the row |
| `docs/engineering/06-design-system.md` | §12 (`ShedChoiceRow`: `Wrap`, not `Row`; **ease-only after T02a**) · §6 (tap targets) | the component contract |
| `docs/engineering/03-data-model-and-schema.md` | §5.4 (`lambings.ease` — nullable, no default, `CHECK (ease IS NULL OR ease BETWEEN 1 AND 5)`) · §5.12 (`VocabTerms`: `key` unique, `label` nullable, `origin`, `hidden_at`) · **§10.1 (the six lists, the forty keys, and the two constraints on the writing)** | the column, the vocabulary and its provenance rule |
| `docs/engineering/CONVENTIONS.md` | §2.9 (**`LambingEase` carries an ordinal, not descriptions**) · §2.13 (`setEase` returns `WriteOutcome`) · §3.1 (the DI root — where a new app-level provider goes) · §4.5 (keys) · **R44** · **R66** | the type, the verb and where the labels live |
| `epics/N00-…/N00-T04` | the ease ruling | *lambing ease 5 vs 6* was **ruled before the freeze**; the scale is five and 5 covers elective caesarean |
| `docs/engineering/05-domain-correctness.md` | §6.7 (the assisted rate) · §7.5 (never originate a value) | why a blank score must stay blank |
| `docs/engineering/07-screens.md` | §6.4 (*"a blank score means not scored and is excluded from the assisted rate on both sides; it is never inferred as 1 — unassisted"*) · §1.2 (an app-level singleton is a legitimate second watch) · §15.1 (`setEase` has no undo verb) | the behaviour and the second watch |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.2 (labels carry no state word — use `selected:`) · §8 (every message has a `description`) | the row's semantics |
| `docs/research/00-tech-decisions.md` | §5 · #59 (a blank ease is not zero) · #61 (terminology is a user-owned overlay) | the decisions applied |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-controls` | the choice row is its component and this is its only legitimate use |
| `shed-write-path` | the choice is its own committed write |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/lambing_entry_test.dart`
- **Test** — `'selecting ease 3 commits immediately and renders its authored description'`
- **Why it is red today** — nothing records ease, which spec §7.2 names as one of the two fields that matter.

```bash
fvm flutter test test/features/lambing_entry_test.dart   # expect: failing, for the reason above
```

Sharpen both clauses. **Commits immediately** — read `lambings.ease` back out of the database in the
same test, with no Save button pressed and no route popped. **Its authored description** — seed a
`vocab_terms` row for `ease_3` with a **user label**, assert that string renders, then clear the label
and assert the ARB default renders instead. A test that matches a hard-coded English sentence passes
just as happily against a Dart literal, which is the one implementation this task must refuse.

**Green.** The minimum code that passes, and nothing beyond it — the row, the verb, and the description lookup from the seeded vocabulary.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema step, and say so in the commit message.** `lambings.ease` and the `vocab_terms` seed froze
at N07. This task reads them.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/providers.dart` | **Extended.** `vocabProvider` — `StreamProvider<List<VocabTerm>>`, keepAlive, all forty rows. Forty rows is nothing and four screens need them (ease here, malpresentation in T08, death cause in N17-T03, treatment route in N20). `07 §1.2` permits an **app-level singleton** as a screen's second watch, which is exactly what this is |
| 2 | `lib/core/ui/vocab_label.dart` | **New.** `String vocabLabel(String key, String? userLabel, AppLocalizations l10n)` — two lines, `userLabel ?? l10n.<key>`. It takes **primitives, never a `VocabTerm`**: layer rule 7 forbids `lib/core/ui/` from importing `lib/data/`, and a drift row class in this signature makes the file unbuildable |
| 3 | `docs/engineering/CONVENTIONS.md` §1, §3.1, §6 | **Extended, in this commit.** One tree line for `vocab_label.dart`, one row in the DI-root table for `vocabProvider`, and **one numbered ruling** recording both. §3 claims to list *every provider in the app*; a provider that exists and is not in it makes the catalogue wrong for everyone after. The next free number after T02's is **R76** |
| 4 | `lib/data/lambing_repository.dart` | **Extended.** `Future<WriteOutcome> setEase(LambingId id, LambingEase ease)` — one `db.transaction`, `appNow()` once, `updated_at` moved, `WriteCommitted()` with the default empty `warnings` (R53) |
| 5 | `lib/features/lambing/lambing_entry_controller.dart` | **Extended.** `LambingWriteController.setEase(LambingId, LambingEase)` through `guard()` |
| 6 | `lib/features/lambing/widgets/ease_row.dart` | **New.** `ShedChoiceRow` with five values, the madder underline on the selected one, the description to its right, and the dotted-rule unset state for the whole group |
| 7 | `lib/features/lambing/lambing_entry_screen.dart` | **Extended.** Mounts the row under the lambs list |
| 8 | `lib/l10n/app_en.arb` | **Extended.** `ease_1`…`ease_5`, written in the app's own words (see §5.3), the group heading, the unset label and the row's `semanticLabel` — each with a `description` |
| 9 | `assets/content/` | **Extended.** One provenance line for the `lambing_ease` list stating it was authored. Not the labels — R66 |
| 10 | `test/features/lambing_entry_test.dart` | **The anchor**, plus the five-value, unset, wrap and override cases |
| 11 | `test/policy/vocab_labels_are_complete_test.dart` | **Extended** (created at N07-T07). The five ease keys now have real consumers |
| 12 | `test/data/lambing_ambiguous_hour_test.dart` | **Extended.** Scoring an ease inside the repeated hour |

### 5.2 The signatures

The domain type is an ordinal and carries nothing else — R44, and the reason is structural:

```dart
// lib/domain/lambing_ease.dart — created at N06-T01, UNCHANGED here.
/// 1..5, validated. NO descriptions: a domain file cannot hold ARB text
/// (layer rule 1 bans `intl` and `AppLocalizations`), and the five labels are
/// `vocab_terms` keys `ease_1`..`ease_5` resolved at the presentation edge.
extension type const LambingEase(int code) { … }
```

The verb and the provider:

```dart
// lib/data/lambing_repository.dart
Future<WriteOutcome> setEase(LambingId id, LambingEase ease);

// lib/data/providers.dart — R76
/// All forty seeded terms plus any the user added. keepAlive: it is an
/// app-level singleton, which `07 §1.2` allows a screen to watch alongside its
/// one content statement. It is NOT a second content stream.
final vocabProvider = StreamProvider<List<VocabTerm>>((ref) async* { … });
```

The row, with the geometry that is not negotiable:

```dart
// lib/features/lambing/widgets/ease_row.dart
/// Five 64 x 64 buttons, 8 px gaps — 64 * 5 + 8 * 4 = 352 inside the 361 px
/// available. Keys `lambing_entry.ease.1` .. `lambing_entry.ease.5`.
///
/// This is the LAST segmented control in the product. P8 abolished the
/// birth-type chooser; `06 §12`'s row lists ease and death cause only.
/// Selected: `--slab` fill, 2 px `--ink-full` border, and a 2 px madder
/// underline the full 64 px width, with `EASE 3 · SOME ASSISTANCE` to the
/// right. Unset: all five plain, a 2 px DOTTED rule under the whole group,
/// labelled `EASE — NOT RECORDED · SKIPPABLE`.
```

### 5.3 The details that are easy to get wrong

- **The descriptions are not in `assets/content/`, not in the domain, and not in a Dart literal.**
  Three homes, no overlap (R66): keys in `lib/core/db/seed/first_run.dart` with `origin = 'seeded'`
  and `label = NULL`; labels in `lib/l10n/app_en.arb`, one message per key; `assets/content/` holds
  only long prose and one provenance line per list. R44 removes them from `lambing_ease.dart`
  outright, because `lib/domain/` may not import `intl` or `AppLocalizations`. The `01` tree comment
  that said otherwise is the artefact R44 corrected.
- **`label IS NULL` means *render the shipped default*, and it is not the same as an empty label.**
  A user who renames ease 3 writes `vocab_terms.label`; no locale change and no app update touches it.
  Resolve as `userLabel ?? l10n.<key>` and nothing cleverer — a `label?.isEmpty ?? true` check would
  let an accidental blank silently fall back, hiding the user's own edit.
- **A blank ease is *not scored*, and it is never `1`.** `lambings.ease` is nullable with **no
  default** — `03 §5.4` says so in the column comment and decision #59 is why. `05 §6.7`'s assisted
  rate excludes an unscored lambing **from both the numerator and the denominator**; inferring
  "1 — unassisted" would inflate the unassisted count and deflate the rate, invisibly, for years.
  There is nothing to render as zero, either: the group prints its dotted rule and its label.
- **The scale is five and it was ruled before the freeze.** *Lambing ease 1–5 vs SRUC's 6* was
  decision-record §7.1 item 15 and **N00-T04 ruled it**; `lambings.ease` carries
  `CHECK (ease IS NULL OR ease BETWEEN 1 AND 5)` in a frozen schema, and `03 §10.1` notes that 5
  covers elective caesarean. A sixth button is a migration on somebody else's phone, not a widget
  change. This task implements the ruling; it does not re-open it.
- **Write the five sentences in the app's own words.** `03 §10.1` overturns the *"adopt them
  verbatim"* instruction: the SRUC technical note is image-based and its licence terms could not be
  verified. The *concept* of a five-point assistance scale is not ownable; the sentences are. The
  no-verbatim-third-party-copy CI check scans **both** `assets/content/` and `lib/l10n/` (R66), so
  pasting into either fails the build.
- **There is no *clear* affordance and `setEase` takes a non-nullable `LambingEase`.** A mis-tap is
  corrected by tapping the right value — correction forward, both values never both present, because
  `07 §15.1` gives this verb **no undo**. Adding a sixth "not scored" button to clear it would put a
  chooser back on the screen for the absence of a value, and `NULL` is already how absence is stored.
  If clearing turns out to be needed it is a screens decision, not a local one.
- **`ShedChoiceRow` is a `Wrap`, not a `Row`** (`06 §12`), and this is the **one documented component
  wrap in the system**: at ≥ 150% text scale the five buttons re-lay as 3 + 2 at `116 × 80`
  (`indelible.md` §3.6). The page structure does not change; one component re-lays. Do not clamp the
  text scale to avoid it — `textScaleFactor`, `TextScaler.clamp` and `withClampedTextScaling` are
  banned outright (decision #99) and defeat Android 14+'s own non-linear curve.
- **The selected state is four channels, not a colour.** Fill goes `--page` → `--slab`, the border
  goes 2 px `--ink-full`, a 2 px madder underline runs the full button width, and the description
  prints to the right. `10 §5.2`: colour is never one of the three channels on its own, and the
  night-shift palettes destroy the hue channel deliberately.
- **The label carries no state word.** `10 §3.2` rule 2: use `selected:` on the `Semantics` node, never
  `'Ease 3, selected'` in the label — a screen reader announces the state itself and the doubled
  announcement is what users report as noise.
- **`vocabProvider` is a second *watch*, not a second content statement.** `07 §1.2` is precise: a
  screen has exactly one content statement plus, if needed, single-row lookups and app-level
  singletons. The ease description is not computed from two drift streams — the ordinal comes from the
  content statement and the label is a lookup. Fanning the vocabulary into `lambingEntryQuery` would
  join forty rows onto every lamb row for no gain.
- **The write moves `updated_at` and nothing else.** Read the whole row back and assert
  `occurred_at`, `captured_at`, `time_source` and `declared_birth_type` are untouched. A `copyWith`
  that rewrites the provenance quad on an unrelated edit is the kind of bug that only shows up in an
  export months later.
- **A double-fired tap commits one value** (decision #22). `guard()` refuses to run concurrently, and
  the test has **no pump between the two taps**.

### 5.4 The full test set

| File · case | What it asserts |
|---|---|
| `test/features/lambing_entry_test.dart` · `'selecting ease 3 commits immediately and renders its authored description'` | **The anchor.** `lambings.ease` is 3 in the database with no Save button pressed; the description renders from `vocab_terms` |
| `test/features/lambing_entry_test.dart` · `'a user label on ease_3 overrides the shipped default and survives'` | Seed `vocab_terms.label`, assert it renders; clear it, assert the ARB default returns |
| `test/features/lambing_entry_test.dart` · `'the row offers exactly five values and no sixth'` | The N00-T04 ruling, held as a widget property |
| `test/features/lambing_entry_test.dart` · `'an unscored ease prints a dotted rule and NOT RECORDED, and never 1'` | Decision #59. No zero, no blank, no inferred unassisted |
| `test/features/lambing_entry_test.dart` · `'selecting ease writes only ease and updated_at'` | The provenance quad and `declared_birth_type` are byte-identical afterwards |
| `test/features/lambing_entry_test.dart` · `'re-tapping a different value corrects forward and leaves no second value'` | There is no clear affordance and no undo verb |
| `test/features/lambing_entry_test.dart` · `'a double-fired ease tap commits one value'` | `guard()`, with no pump between the taps |
| `test/features/lambing_entry_test.dart` · `'the selected button carries the madder underline and three non-colour channels'` | Fill, border, underline, description — colour is never alone |
| `test/features/lambing_entry_test.dart` · `'the group wraps to 3 + 2 at textScaler 1.5 and every button stays at least 64 by 64'` | `indelible.md` §3.6's one documented wrap, and the floor survives it |
| `test/features/lambing_entry_test.dart` · `'the ease semantics node carries selected and no state word in its label'` | Opens `tester.ensureSemantics()`; `10 §3.2` rule 2 |
| `test/features/lambing_entry_test.dart` · `'no ease description appears as a Dart literal under lib/'` | Source text. The one implementation this task must refuse |
| `test/policy/vocab_labels_are_complete_test.dart` · `'every seeded vocab_terms key has exactly one ARB message'` | Extended from N07-T07; the five ease keys now have a consumer that would notice |
| `test/data/lambing_ambiguous_hour_test.dart` · `'scoring an ease at 01:30 in the repeated hour moves updated_at and not occurred_at'` | **`uk-zone`.** `atFixed(DateTime(2026, 10, 25, 1, 30), …)`; the event time is the lambing's and an unrelated edit never touches it |

## 6. Constraints that bind this task

- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider. Ease is five buttons and **never a slider** — `indelible.md` §7.8: *"a slider with a cold finger is a random number generator."*
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Never originate a value** — an unscored ease stays unscored. Inferring `1` is §12.4 in the one place a statistic reads it.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'selecting ease 3 commits immediately and renders its authored description'` passes, and was seen to fail first for the stated reason
- [ ] five values, matching the N00-T04 ruling
- [ ] the write commits on tap, with no confirmation step
- [ ] the descriptions come from `vocab_terms`, not from a Dart literal
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] a user label overrides the shipped default, and clearing it restores the default
- [ ] an unscored ease renders its dotted rule and its label, never `0` and never `1`
- [ ] the write touches `ease` and `updated_at` and nothing else
- [ ] the group wraps to 3 + 2 at ≥ 150% and every button stays ≥ 64 × 64; nothing clamps the text scale
- [ ] `vocabProvider` and `vocab_label.dart` are added to `CONVENTIONS §1` and §3.1 under one numbered ruling, in this commit
- [ ] `vocabLabel` takes primitives, never a drift row class
- [ ] the five sentences are written in the app's own words, and the no-verbatim check is green over `assets/content/` and `lib/l10n/`
- [ ] the ambiguous-hour case exists and is tagged `uk-zone`

## 8. Verification

```bash
fvm flutter test test/features/lambing_entry_test.dart
fvm flutter test test/policy/vocab_labels_are_complete_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
make check
make test
```

```bash
grep -rn "ease_1\|ease_5" lib/ assets/content/     # keys only; no sentence outside lib/l10n/
grep -rn "TextScaler.clamp\|textScaleFactor\|withClampedTextScaling" lib/   # expect zero
grep -rn "Slider\|CupertinoSlider" lib/features/lambing/                    # expect zero
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(lambing_entry): lambing ease 1-5, the one surviving segmented choice`
