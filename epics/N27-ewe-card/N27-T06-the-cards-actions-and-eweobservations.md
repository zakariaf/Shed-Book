# N27-T06 — The card's actions and `EweObservations`

| | |
|---|---|
| **Epic** | [N27 — Ewe Card](epic.md) · `00-README` §9 step 10 (2 of 4) |
| **Task** | 6 of 7 |
| **Depends on** | N27-T05 |
| **Commit** | one commit · `feat(ewe_card): actions and EweObservations from the seeded vocabulary` |

## 1. Why this task exists

The actions a shepherd takes from the card, and `EweObservations` written from the
**seeded vocabulary** — prolapse, mastitis, poor mothering, lameness — all editable, none of them a
diagnosis and none of them advice.

It is also the task that discovers the card cannot reach any other feature's write controller. Every
action here is a verb some other epic already built, fired from a folder that
**layer rule 6 forbids from importing any of them** — and the resolution is the one N14-T03 already
found for Quick Entry.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§4.3 (every action and its tap cost: record a lambing, treat her, pen her, record an observation, add a note, edit a timestamp, change status, record her as barren — with R41 and R42 already applied)** · §4.1 (the `EweObservations` paragraph: the six vocabulary keys, and *"the app records what the shepherd observed and never infers it"*) · §15.1 (undo per verb) · §15.5 (there is no draft, so "Cancel" is not a verb) · §6.1 (the write-then-push shape, as amended by N14-T03) | which actions exist and what each costs |
| `docs/engineering/03-data-model-and-schema.md` | **§5.7 (`EweObservations` — `ewe`, `season`, nullable `lambing`, `kind` as an FK to `vocab_terms(key)` with `ON DELETE RESTRICT`, the §12.5 quad, the nullable `note`, and the doc-comment §12.2 boundary)** · §10.1 (the six seeded `ewe_observation` keys and the keys/labels split) · convention 6 (a user-editable vocabulary is an FK, never a `CHECK`) · §5.14 (`LambingRepository` owns `ewe_observations`; `SeasonRepository` owns `ewe_seasons`) · §5.13 (`ewe_touches` — *"'Touched' includes looking at a ewe card without writing anything"*) | the table, the vocabulary and who may write them |
| `docs/engineering/CONVENTIONS.md` | **§1 layer rules 5 and 6** · §2.4 (`WriteOutcome`), §2.13 (`beginLambing` throws and returns an id — R32; `setStatus`; the closed writer list), §3.4 (**`flockWriteControllerProvider` exists; `eweCardWriteControllerProvider` does not**), §4.4 (one write controller per **feature**; controllers hold no `BuildContext` and never navigate), §4.5 (widget keys), §5.1 (*barren*, *record*, *event*), R32, R33, R42, R53 | **BINDING** on which controller these verbs live on |
| `docs/engineering/02-state-di-navigation.md` | §7 (`WriteController`, `guard()`, and the `ref.listen` switch over the three `WriteOutcome` variants), §7.1 (the four rules — `guard()` prevents concurrency, not repetition), §8.1 (`Routes.*`), §8.3 (`PopScope` with `canPop: true` and `flushPending` on the ewe card — the screen that owns a free-text field) | the write path and the note field's flush |
| `epics/N14-quick-entry-the-write-path/N14-T03-quick-entry-write-controller-through-guard.md` | §5.2–§5.3 (the `beginLambing`-inside-`guard()` adaptation, and the `layer.sibling` finding) | the precedent this task reuses verbatim |
| `docs/skills/02-build-manifest.md` | **§4.1 (P2 — there is no SnackBar; the confirmation is the committed row, in ink, one line above; undo is a time-boxed strike whose window is stated in seconds)** · §4.4 defect 2 | what happens after each write |
| `docs/design/indelible.md` | §8 screen 2 (*"The four actions sit as in-stream word buttons on one 64 px line inside the thumb band: `RECORD EVENT · TREAT · MOVE PEN · ADD NOTE`. The slab reads `+ NOTE`"*) · §6.1 (every action is a **word**, there is no icon set) · §7.13 (the word button) · §7.14 (the bottom sheet — no drag handle, an 88 × 64 `CLOSE`) · §4.5 (the thumb band: nothing above 560 px from the bottom is required to complete an event) | what the actions look like and where they sit |
| `docs/engineering/06-design-system.md` | §12 (`ShedBottomSheet` — `showDragHandle: false`, `enableDrag: false`, `isDismissible: false`, explicit Cancel; `ShedChoiceRow` — `Wrap`, not `Row`), §6.1 (`tapMin` 60 / `tapPrimary` 72 / `tapHero` 88) | the sheet and the picker |
| `docs/engineering/05-domain-correctness.md` | **§7.3 (the origination line, and the forbidden column — *"These losses indicate a nutritional deficiency"*)** · §7.5 (a repository cannot produce a `Warning`) · §4.1 (`RecordedTime.capture`) | the safety rule that bounds every observation |
| `docs/engineering/10-accessibility-and-i18n.md` | §8.5 (the terminology placeholder), §8.6 / R66 (the forty vocabulary labels are ARB messages; `label IS NULL` means render the shipped default), §3.2 (labels) | how a vocabulary key becomes a word on screen |
| `docs/engineering/12-testing.md` | §3.1–§3.3 (repository tests against `NativeDatabase.memory()`), §5.1 (`pumpApp`), §11 (the double-tap test) | the tiers this task's tests live in |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | each observation is an immediate committed write |
| `shed-safety-rules` | an observation is a record of what was seen, never a diagnosis |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/ewe_card_test.dart`
- **Test** — `'an observation writes immediately from the seeded vocabulary and adds no advice'`
- **Why it is red today** — the card is read-only, and spec §7.7 names these observations explicitly.

```bash
fvm flutter test test/features/ewe_card_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it holds all three claims the test name makes:

1. **from the seeded vocabulary** — the picker's options are exactly the keys returned by
   `SELECT key FROM vocab_terms WHERE list = 'ewe_observation' AND hidden_at IS NULL`, asserted by
   hiding one seeded term and adding one `origin = 'user'` term and re-pumping; a hard-coded list
   passes the naive version of this test and fails this one;
2. **writes immediately** — the `ewe_observations` row exists after the pick, with no confirm step,
   no Save button and no second tap;
3. **adds no advice** — every rendered string on the sheet and the row is run through
   `ContentPolicy.bannedInUserFacingText` and none matches.

**Green.** The minimum code that passes, and nothing beyond it — the actions, the observation write, and the vocabulary lookup.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 3 (two repository verbs), step 5 (the write controller), step 6 (the widgets and the route
helpers), step 6 item 22 (the ARB) and step 7 (tests).** No schema, no domain. Say the skipped layers
in the commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/lambing_repository.dart` | **Edit, additive.** `recordObservation(...)` — `ewe_observations` is this repository's (§2.13). One transaction: one `appNow()`, `RecordedTime.capture(now)` into the quad, `newUid()`, and the T03 summary write in the same transaction, because an observation moves `last_observation_season` |
| 2 | `lib/data/settings_repository.dart` | **Edit, additive.** `observationVocabulary()` → `Future<List<VocabTerm>>` — a **one-shot** read of the non-hidden `ewe_observation` keys. `SettingsRepository` owns `vocab_terms` (§2.13); the read is one-shot, not a stream, for the reason in §5.3 item 3 |
| 3 | `lib/data/flock_repository.dart` | **Edit, additive.** `touch(EweId)` — the `ewe_touches` upsert (decision #68), if N26 did not already land it. Primary key is `ewe`, so it is idempotent |
| 4 | `lib/features/flock/flock_write_controller.dart` | **Edit.** `recordObservation`, `beginLambing`, `recordBarren`, `setStatus`, `touch` — all through `guard()`. This is the flock **feature's** one write controller (§4.4 rule 2) and it already exists from N26-T04 |
| 5 | `lib/features/flock/widgets/observation_sheet.dart` | **New.** `ShedBottomSheet` + `ShedChoiceRow` over the vocabulary, plus the optional free-text note. Keys `ewe_card.observe`, `ewe_card.observe.<key>` |
| 6 | `lib/features/flock/widgets/ewe_card_actions.dart` | **New.** The four in-stream word buttons on one 64 px line in the thumb band, plus the status and barren verbs |
| 7 | `lib/features/flock/ewe_card_screen.dart` | **Edit.** The actions row; `ref.listen` over the write controller; `PopScope(canPop: true, …)` flushing the note field |
| 8 | `lib/routing/routes.dart` | **Edit.** Nothing new — `Routes.lambingEntry`, `Routes.treatments`, `Routes.penBoard` already exist. This is where the card reaches them **without** importing a sibling feature |
| 9 | `lib/l10n/app_en.arb` | **Edit.** The action labels, the sheet title, the note field label, and the six `ewe_observation` default labels if R66's seeding did not already land them |
| 10 | `test/data/ewe_observations_test.dart` · `test/features/ewe_card_test.dart` | **New / edit.** §5.4's cases |

### 5.2 The signatures

```dart
// lib/data/lambing_repository.dart — ADDITIVE.

/// An observation is a RECORD OF WHAT WAS SEEN. 03 §5.7's doc comment is the
/// rule and it belongs in this method's doc comment too: the app never infers
/// `obs_poor_mothering` from a lamb death, never infers `obs_no_milk` from a
/// bottle-fed lamb, and never writes a row on the user's behalf.
///
/// `kind` is a vocab_terms key, validated by the FK (ON DELETE RESTRICT), and
/// scoped to list = 'ewe_observation' by test/data/vocab_list_scope_test.dart.
Future<WriteOutcome> recordObservation(
  EweId ewe, {
  required String kind,
  LambingId? lambing,
  String? note,
});
```

```dart
// lib/features/flock/flock_write_controller.dart — the card's verbs live HERE.
// Layer rule 6 forbids lib/features/flock/ from importing lib/features/lambing/
// or lib/features/pens/, so lambingWriteControllerProvider and
// penWriteControllerProvider are unreachable from this screen. CONVENTIONS §4.4
// rule 2 — one write controller per FEATURE — is what makes that fine: the Ewe
// Card and the Flock screen are one feature folder. N14-T03 hit the identical
// wall on Quick Entry; this is its resolution, unchanged.

final class FlockWriteController extends WriteController {
  // …createEwe, from N26-T04, unchanged.

  Future<void> recordObservation(EweId ewe, {required String kind, String? note}) =>
      guard(() async {
        final repo = await ref.read(lambingRepositoryProvider.future);
        return repo.recordObservation(ewe, kind: kind, note: note);
      });

  /// R32: beginLambing returns an id and THROWS. It is adapted to guard()'s
  /// Future<WriteOutcome> exactly as N14-T03 adapted it — the id travels back
  /// as WriteCommitted.insertedId, R33's single permitted call site, and a
  /// throw surfaces as WriteFailed(UnexpectedFailure) rather than as silence.
  Future<void> beginLambing(EweId ewe) => guard(() async {
        final repo = await ref.read(lambingRepositoryProvider.future);
        final LambingId id = await repo.beginLambing(ewe);
        return WriteCommitted(insertedId: id.value);
      });

  /// R42: barren is a SEASON PARTICIPATION OUTCOME — ewe_seasons.status —
  /// owned by SeasonRepository. It is not a status change and it is not an
  /// observation; the ewe_observation vocabulary has no barren key and must
  /// not gain one.
  Future<void> recordBarren(EweId ewe) => guard(() async {
        final repo = await ref.read(seasonRepositoryProvider.future);
        return repo.setEweSeasonStatus(ewe, EweSeasonStatus.barren);
      });
}
```

And the navigation, which is the screen's, never the controller's (§4.4 rule 3):

```dart
// lib/features/flock/ewe_card_screen.dart
ref.listen(flockWriteControllerProvider, (previous, next) {
  if (next case WriteDone(:final outcome)) {
    switch (outcome) {                       // sealed, three variants, no default:
      case WriteCommitted(:final insertedId, :final warnings):
        // P2: the confirmation IS the committed row. No SnackBar, anywhere.
        if (pendingLambing && insertedId != null) {
          Routes.lambingEntry(context, LambingId(insertedId));   // R33's wrap site
        }
      case WriteFailed(:final failure):
        showFailure(context, failure);
      case WriteRefused(:final reason):
        showCapRow(context, reason);         // unreachable here — see §5.3 item 9
    }
  }
});
```

### 5.3 The details that are easy to get wrong

1. **The card cannot import another feature's write controller, and the gate will tell you so.**
   *"Record a lambing"* wants `lambingWriteControllerProvider`; *"Pen her"* wants
   `penWriteControllerProvider`; *"Treat her"* wants `treatmentWriteControllerProvider`. All three
   live under sibling folders and `layer.sibling` (rule 6) fails the build. The resolution is not to
   relax the rule: `CONVENTIONS §4.4` rule 2 gives one write controller **per feature**, the Ewe Card
   and the Flock screen are the same feature (`lib/features/flock/`), and reaching repositories through
   `lib/data/` is what rule 5 permits. Navigation goes through `lib/routing/routes.dart`, which
   `lib/features/` may import in both directions by design (01 §3's note).
2. **There is no `eweCardWriteControllerProvider` and adding one is a naming change.**
   `CONVENTIONS §3.4` prints the closed list; `flockWriteControllerProvider` is on it and an
   ewe-card-specific one is not. If it turns out one is genuinely needed, that is a ruling in
   `CONVENTIONS §6`, not a file.
3. **The vocabulary is read once when the sheet opens, not watched on the card.** The card's content
   statement is the timeline (07 §1.2), and the list of things a screen may *additionally* watch is
   closed: a single-row lookup, or one of `settingsProvider` / `entitlementProvider` /
   `tagIndexProvider` / `minuteTickProvider`. A vocabulary stream is none of those. Read it in the
   sheet's own `FutureProvider`, scoped to the sheet, and the one-query rule stays intact.
4. **The vocabulary is not an enum, and hard-coding six keys passes the wrong test.** 03 convention 6:
   a user-editable vocabulary is an FK to `vocab_terms(key)`; the user may add a term
   (`origin = 'user'`, a generated key, a mandatory label) and may hide a seeded one (`hidden_at`,
   never a `DELETE`, because the term is the target of an `ON DELETE RESTRICT` FK). And
   `test/data/vocab_list_scope_test.dart` asserts per column that every stored key belongs to that
   column's list — writing `dc_starvation` into `ewe_observations.kind` is not stopped by SQL and is
   stopped by that test.
5. **A key is not a label.** R66: the **keys** are seeded in `lib/core/db/seed/first_run.dart` with
   `label = NULL`; the **labels** are ARB messages; `label IS NULL` means *render the shipped default
   for this key*. Resolve at the presentation edge — `lib/domain/` and `lib/data/` are forbidden from
   importing `AppLocalizations`, which is the whole reason for the split. A user's edit writes
   `vocab_terms.label`, and **no locale change and no app update ever overwrites it**.
6. **The §12.2 boundary is the point of this task, and it has a specific shape.** 05 §7.3's origination
   line: the app may arithmetic-transform a number the shepherd supplied; it may never originate one
   that is a clinical decision. Concretely, here: never pre-select a kind, never suggest one from a
   lamb death or a bottle-fed lamb, never render a consequence (*"prolapse risk"*, *"watch her next
   season"*, *"you should"*), and never seed a `DEFAULT` on `kind`. 03 §5.7's doc comment says it and
   the method's doc comment says it again, because that is where the next contributor reads it.
7. **Barren is not an observation and not a status.** R42 is explicit: barren is
   `ewe_seasons.status = 'barren'` for the **current season**, owned by `SeasonRepository`; the
   §7.7 flock filter joins `ewe_seasons`. `ewes.status`'s `CHECK` is
   `('active','sold','dead','culled')` and the `ewe_observation` vocabulary is
   `obs_prolapse`, `obs_mastitis`, `obs_poor_mothering`, `obs_good_mothering`, `obs_no_milk`,
   `obs_other` — six keys, no barren. Adding a seventh is a seed change **and** a schema-adjacent
   conversation.
8. **`setStatus` has no undo verb, and that is a ruling, not an omission.** R41 and 07 §15.1:
   `ewes.status` is a mutable column, there is no status-history table, and the previous value is
   recoverable from the record's own context. Do not build an undo affordance for it, and do not
   write copy implying one.
9. **`WriteRefused` is unreachable on this screen and the arm still exists.** 07 §19.2: nothing
   monetization-related renders on the Ewe Card, and free-tier history is never hidden, blurred or
   made read-only. The `switch` over `WriteOutcome` is exhaustive with **no `default:`** so that the
   day a fourth variant appears every switch fails to compile rather than swallowing it (01 §5.2).
10. **P2: the confirmation is the committed row.** `showSnackBar(` is banned everywhere, including
    `feedback.dart` (build-manifest §4.1, superseding `CONVENTIONS §2.11`). After an observation the
    row is simply *there*, in the timeline, one line above — which on this screen is literal, because
    the timeline is the page. Undo is a time-boxed strike in that row's margin and its window is
    **stated in seconds**, never *"until the SnackBar is dismissed"*.
11. **`guard()` prevents concurrency, not repetition** (02 §7.1 rule 1). Two taps on *Observe* after
    the first write returns produce two observations, and that is correct — a ewe can prolapse twice.
    A cooldown here would break the legitimate case. What `guard()` holds is the double-tap during the
    write, and `00-README` §8 step 28 requires a `tester.tap(); tester.tap();` test for it.
12. **`ewe_touches` belongs on card entry, not on the Flock row's tap — and the documents disagree.**
    07 §3.3 puts the write on the Flock action; 03 §5.13's doc comment says *"'Touched' includes
    **looking at a ewe card** without writing anything, so it is an observation and is not derivable"*.
    If the write lives only on the Flock tap, opening 412 from the pen board, a treatment row or the
    reused-tag disclosure never touches her and the recents strip quietly goes stale. Put it on card
    entry; the upsert is on the primary key `ewe`, so a Flock tap that also touches is harmless. Route
    the wording fix to 07 §3.3 rather than deleting either sentence.
13. **The note field is the one free-text field on this screen, and `PopScope` flushes it.** 02 §8.3:
    `canPop` is **always** `true` — back is never blocked, there is no "discard changes?" dialog
    anywhere in this app — and `onPopInvokedWithResult` calls
    `ref.read(eweCardControllerProvider(eweId).notifier).flushPending()`. The typed text lives in a
    **private field on the notifier**, not only in `state`, or a `build()` re-run wipes it mid-sentence
    (02 §3.1's lifecycle note; a real 3am bug, not a theoretical one).
14. **Every action is a word, and the sheet has no drag.** Indelible §6.1: there is no icon set —
    `RECORD EVENT · TREAT · MOVE PEN · ADD NOTE`. §7.14 and 06 §12: `showDragHandle: false`,
    `enableDrag: false`, `isDismissible: false`, an explicit 88 × 64 `CLOSE`. And N10-T07's
    `one_overlay_test` asserts `showModalBottomSheet(` appears nowhere outside
    `shed_bottom_sheet.dart` — so the sheet is built through the component, never called directly.
15. **The actions sit in the thumb band.** Indelible §4.5: nothing above 560 px from the bottom is ever
    required to complete an event, and §8 screen 2 puts the four word buttons on one 64 px line inside
    it. An action row at the top of a scrolling card is unreachable one-handed on a large phone, and
    06's DoD line — *"No action anywhere is reachable only by scrolling"* — is a gate the matrix
    checks.

### 5.4 The full test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/features/ewe_card_test.dart` | `'an observation writes immediately from the seeded vocabulary and adds no advice'` | **The anchor**, all three claims: the options come from `vocab_terms`, the row exists after one pick, and every string passes `ContentPolicy` |
| | `'hiding a seeded term removes it from the picker'` | `hidden_at`, never a `DELETE` |
| | `'a user-added term appears in the picker with its own label'` | `origin = 'user'` with a mandatory label |
| | `'no observation kind is pre-selected'` | §12.2 and decision #31 — no default on a column that could encode a clinical value |
| | `'recording a lambing from the card pushes Lambing Entry after the row exists'` | R32 and decision #11: the write happens, then the route. The id arrives as `WriteCommitted.insertedId` |
| | `'a double tap on Record a lambing creates one lambing while the write is running'` | `guard()`'s concurrency defence, `00-README` §8 step 28 |
| | `'a second tap after the first write returns creates a second observation'` | 02 §7.1 rule 1 — the case a cooldown would break |
| | `'recording her as barren writes ewe_seasons and not ewe_observations'` | **R42.** The single most likely misplacement in this task |
| | `'no ewe_observation vocabulary key is barren'` | The other half of R42, as a seed assertion |
| | `'changing status offers no undo affordance'` | R41, 07 §15.1 |
| | `'opening the card writes an ewe_touches row'` | Decision #68 and item 12 |
| | `'opening the card twice leaves one ewe_touches row with the later time'` | The upsert on the primary key |
| | `'no SnackBar is shown after any write on this screen'` | P2. Assert `find.byType(SnackBar)` is empty after each of the five verbs |
| | `'popping the card with unsent note text flushes it'` | 02 §8.3, `canPop: true` and `flushPending` |
| | `'every action target measures at least 64 by 64 at Device.small'` | The 3am floor, geometric |
| | `'every action is reachable without scrolling at textScale 2.0'` | Indelible §4.5 and 06's DoD |
| | `'no action on this screen is bound to a swipe, drag, long-press or pinch'` | The gesture ban, in the tier a developer runs first |
| `test/data/ewe_observations_test.dart` | `'recordObservation writes the whole provenance quad in one transaction'` | §12.5: `occurred_at == captured_at`, `original_effective IS NULL`, `time_source = 'auto'` |
| | `'recordObservation moves last_observation_season in the same transaction'` | The T03 contract, from the other side |
| | `'a kind outside the ewe_observation list is refused by the vocabulary scope test'` | 03 convention 6; the FK constrains the key, the test constrains the list |
| | `'an observation attached to a lambing keeps the lambing FK; deleting the lambing sets it null'` | `ON DELETE SET NULL` on the nullable `lambing` column |
| | `'recordObservation returns WriteCommitted with empty warnings'` | R53 — a repository is structurally incapable of producing a `Warning` |
| `test/policy/` | `'no user-facing string on the ewe card originates a clinical claim'` | 05 §7.3, over this screen's ARB messages and the six vocabulary labels |

## 6. Constraints that bind this task

- **§12.2, held at *caught by a gate*.** `EweObservations` are written from the seeded vocabulary — prolapse, mastitis, poor mothering, lameness — every one editable, none of them a diagnosis and none of them a recommendation. The moment an observation acquires a suggested action or a product name, `copy.vet_advice` is what has to catch it, because there is no widget test that can assert the absence of advice. §12.5 rides on every action: each writes an event with its provenance, never a mutation in place.
- **Write path** — the row is created on screen entry, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **Layer rules 5 and 6** — the card reaches repositories through `lib/data/` and other screens through
  `lib/routing/`, and imports no sibling feature in either direction.
- **P2** — there is no SnackBar. The confirmation is the committed row; undo is a time-boxed strike
  whose window is stated in seconds.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'an observation writes immediately from the seeded vocabulary and adds no advice'` passes, and was seen to fail first for the stated reason
- [ ] the vocabulary is the seeded, user-editable one
- [ ] no observation text originates a clinical claim
- [ ] each write commits immediately
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] every verb goes through `flockWriteControllerProvider` and `guard()`; no sibling-feature import exists in either direction, proved by `gate` rather than by inspection
- [ ] `beginLambing` runs **inside** `guard()` and its id reaches the screen as `WriteCommitted.insertedId`
- [ ] barren writes `ewe_seasons.status`, and the `ewe_observation` vocabulary still has exactly six seeded keys, none of them barren
- [ ] no observation kind is pre-selected and no `DEFAULT` was added to `ewe_observations.kind`
- [ ] `showSnackBar(` appears nowhere; `find.byType(SnackBar)` is empty after every verb
- [ ] the `ewe_touches` write is on card entry, and the discrepancy with 07 §3.3 is named in the PR body
- [ ] the note field's text lives in a private field on the notifier and survives a `build()` re-run
- [ ] every action target is ≥ 64 × 64 and reachable without scrolling at textScale 2.0

## 8. Verification

```bash
# 1. Red first, for the stated reason.
fvm flutter test test/features/ewe_card_test.dart

# 2. Green, plus the data tier this task adds and the two it re-opens.
fvm flutter test test/data/ewe_observations_test.dart \
                test/data/ewe_summaries_test.dart \
                test/data/vocab_list_scope_test.dart \
                test/features/ewe_card_test.dart

# 3. The content-policy guard, both directions.
fvm flutter test test/policy/

# 4. Both gates.
make check
make test
```

```bash
grep -rn "features/lambing\|features/pens\|features/treatments" lib/features/flock/  # expect: nothing
grep -rn "showSnackBar(" lib/                          # expect: nothing (P2)
grep -rn "obs_barren\|'barren'" lib/core/db/seed/      # expect: nothing in ewe_observation
grep -rn "showModalBottomSheet(" lib/features/         # expect: nothing (N10-T07)
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ewe_card): actions and EweObservations from the seeded vocabulary`
