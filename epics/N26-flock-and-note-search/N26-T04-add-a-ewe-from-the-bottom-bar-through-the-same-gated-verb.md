# N26-T04 — Add a ewe from the bottom bar, through the same gated verb

| | |
|---|---|
| **Epic** | [N26 — Flock and Note Search](epic.md) · `00-README` §9 step 10 (1 of 4) |
| **Task** | 4 of 7 |
| **Depends on** | N26-T03 |
| **Commit** | one commit · `feat(flock): add a ewe through the same gated createEwe verb` |

## 1. Why this task exists

The same `createEwe` verb Quick Entry uses, with `EntryContext.calm` rather than
`liveEntry` — which is the one place the cap may honestly speak, because this is daylight work and
nobody is holding a lamb.

It also carries **ruling N3**, the contradiction `00-README` §10 has been carrying under *"known open
contradictions"* since the doc set shipped and that N14-T01 defers here by name: `07 §3.3` says the
`duplicateActiveTag` warning *"never blocks the create"*, and `03 §6`'s partial unique index
`ON ewes (tag) WHERE status = 'active'` makes a second **active** 412 physically unstorable. One of
those two sentences is wrong. **The `00-README` §10 row is deleted in this commit.**

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§3.3** (*"Add a ewe \| 1 to open + digits + 1 confirm \| `EntryContext.calm`. Over the cap this returns `BlockedByCap`…"*; and the `duplicateActiveTag` paragraph — one half of ruling N3) · §3.2 (the Over-cap row, and *"The price is never a literal in this codebase"*) · **§19.1–§19.4** (season-primary, the two surfaces, the two hard rules, and what the cap never does) · §15.5 (*"there is no draft state, so 'Cancel' is not a verb"*) · §20 (primary actions live in the bottom third) | where the create lives, which context it uses, and what the cap may say |
| `docs/engineering/03-data-model-and-schema.md` | **§6 (tag uniqueness — settled: the partial unique index; *"Culling is what releases a tag"*; the two pinned tests; the other half of ruling N3)** · §5.2 (`Ewes` — the CHECKs, `over_free_cap`, `status`) · §5.14 (`FlockRepository` owns `ewes` and `ewe_touches`) · §9.2 (the `ewes` → `search_docs` trigger and the `COALESCE` rule) | the index, the columns and the trigger the create fires |
| `docs/engineering/CONVENTIONS.md` | **§2.10 (`enum EntryContext { liveEntry, calm }`, `CapDecision`, `RefusalReason`, `FreeTierPolicy.decide`)** · §2.13 (`createEwe({required String tag, required EntryContext context})`, `setStatus(EweId, EweStatus)`) · §2.4 (`WriteOutcome` — non-generic, three variants) · §2.9 (enums that mirror stored keys) · §2.11 (`showCapRow`) · §4.4 (write controllers; every mutation through `guard()`) · §5.1 (*the free tier* / *the cap*, never *paywall*) · **R32, R33, R53, R69** | **BINDING** on the verb, its parameters and the two enum members |
| `docs/engineering/11-monetization-and-store.md` | §7.3 (the two gated verbs) · **§7.4 (the 22:00–06:00 degrade, and *"do not 'fix' it"*)** · §8.1 (the unlock transaction clears every `over_free_cap` marker; **`over_free_cap` is not a warning**) | what the cap does here and what it must never do |
| `docs/engineering/02-state-di-navigation.md` | **§7 (the double-tap-safe write controller and `guard()`)** · §7.1 (the four rules) · §4.3 (`ref.read` in callbacks, `ref.listen` in `build`) · §8.4 (navigation anti-patterns) | how the tap reaches the verb exactly once |
| `docs/design/indelible.md` | **§7.1 (the corner slab — 160 × 140, bottom-right, the largest target in the system)** · §8 Screen 1 (*"Quick-add is the corner slab, reading `+ EWE`"*) · §7.14 (the bottom sheet — the **only** overlay; no drag handle; an 88 × 64 `CLOSE`) · §7.12 (the text field: **there is never placeholder text inside a field**) · §4.5 (the thumb band, 0–320 px) | the slab, the sheet and the field the tag is typed into |
| `docs/engineering/06-design-system.md` | §6.1 (`tapHero` 88) · **§8.1–§8.2 (`ShedKeypad` — the only tag- and number-entry route, R70)** · §12 (`ShedKeypad`, `ShedConfirmBar` *"Labelled with the outcome ('Create 412')"*, `ShedBanner`) · §10.3 (the saved affordance) | the entry control, which is shared and must not be re-made |
| `docs/engineering/04-migrations-media-backup-restore.md` | **§4.6** (*"It does not write `on SqliteException catch (e)` … the exception arrives wrapped in a `DriftRemoteException` and a bare `on SqliteException` clause **never matches**"*) | how a unique-index violation must be caught |
| `docs/engineering/12-testing.md` | §3.1 (`testDatabase()`) · §4.2 (the seven fakes, including `FakePurchaseService`) · §5.2 (`setEntitlement`, `setEwesInCurrentSeason`) · §10.7 (nothing monetization-related reaches a shed screen) · §11.5 (`flock_15_at_cap.json`) | how the cap gets exercised |
| `docs/research/00-tech-decisions.md` | §5 only for versions · #55 (`tag_digits` is a projection, not a correction) · #88 (the entitlement row) · #90 (nothing on the shed path branches on `unlocked`) · #91 (the live-entry rule) · #92 (two static rows, never a modal) · §7.0 rulings **7** (tags unique among **active** animals only) and **8** (season-primary, ewe cap secondary) | the decisions the create applies |
| `CLAUDE.md` | **§12.4** (never silently correct a user's entry) · **§4** (every write commits immediately; the row is created on screen entry, not on exit) · P2 (there is no SnackBar) | the two rules ruling N3 sits between |
| `shed-book-spec.md` | §7.7 · §12.4 · §14 (one non-consumable unlock) | the product claims this task holds |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-write-path` | the shared verb, its context parameter and `guard()` |
| `shed-monetization` | this is where a cap refusal is legitimate, and how it must read |

`CLAUDE.md` caps auto-firing skills at two. §12.4 binds this task through ruling N3, and `CLAUDE.md`
carries the five safety rules to be *present, not consulted* — read the §12.4 row there rather than
loading a third skill.

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/flock_test.dart`
- **Test** — `'add a ewe uses createEwe with EntryContext.calm and can return BlockedByCap'`
- **Why it is red today** — there is no add path outside Quick Entry.

```bash
fvm flutter test test/features/flock_test.dart   # expect: failing, for the reason above
```

> **Correction to the anchor's name, and why it is a sharpening rather than a weakening.** The backlog
> spelled this test `EntryContext.deliberate`. **That member does not exist.** `CONVENTIONS` R69 and
> §2.10 declare `enum EntryContext { liveEntry, calm }`; `07 §3.3` spells the flock create
> `EntryContext.calm`; N14-T01's own tests use `calm`. A test naming a member that does not exist does
> not compile, so it can never be red *for the stated reason*. The file, the reason and the
> `BlockedByCap` assertion are unchanged. Note the correction in the commit message.

Sharpen the assertion so it proves the *sharing*, not just the behaviour. Restore
`flock_15_at_cap.json`, and assert three things:

1. With `withClock` fixed at **11:00** and the entitlement locked at the cap, tapping confirm produces
   `WriteRefused(RefusalReason.eweCap)` and **`SELECT COUNT(*) FROM ewes` is unchanged**. The refusal is
   the absence of a row, not a message about one.
2. With `withClock` fixed at **22:30**, the same tap produces `WriteCommitted` with `over_free_cap = 1`
   and the row is there afterwards. `07 §19.3` rule 2 and `11 §7.4`: *"do not 'fix' it."*
3. The verb called is `FlockRepository.createEwe` — the **same** symbol Quick Entry's write controller
   calls. Assert it by counting call sites: `grep -c "createEwe" lib/` is exactly the declaration plus
   two. One verb, two contexts (critique **S5**).

**Green.** The minimum code that passes, and nothing beyond it — the bottom-bar action, the same verb, the calm context, and the cap row.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Steps 1 and 3 are skipped and the commit message says so.** The table, the column and the verb all
exist: `03 §5.2`'s `Ewes` was frozen at N07, and `createEwe` landed at N14-T01 *already gated*. Step 2
is reached for the first time in this epic — `EweStatus` is a domain enum that mirrors a stored key.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/domain/ewe_status.dart` | **New.** `enum EweStatus { active('active'), sold('sold'), dead('dead'), culled('culled') }` + `fromKey`. Pure Dart, no imports beyond `meta`. It exists because `CONVENTIONS §2.13` types `setStatus(EweId, EweStatus)` and §2.9 carries no row for it — a signature naming a type nothing declares is a defect |
| 2 | `lib/data/flock_repository.dart` | **Edit.** Add `Future<WriteOutcome> setStatus(EweId id, EweStatus status)` — N14-T01 says in writing *"`setStatus` is N26's"*. `FlockRow.status` changes from `String` to `EweStatus` |
| 3 | `lib/features/flock/flock_write_controller.dart` | **New.** `FlockWriteController extends WriteController`, `flockWriteControllerProvider` (`NotifierProvider.autoDispose`, always). Two methods: `createEwe(String tag)` and `setStatus(EweId, EweStatus)`, each through `guard()` |
| 4 | `lib/features/flock/widgets/add_ewe_sheet.dart` | **New.** The bottom sheet: `ShedKeypad`, the live-ranked match list over `rankTagMatches`, the `duplicateActiveTag` strip, and the confirm bar labelled with the outcome |
| 5 | `lib/features/flock/flock_screen.dart` | **Edit.** The `+ EWE` corner slab in the bottom-right thumb band; `ref.listen` on the write controller for the outcome |
| 6 | `lib/l10n/app_en.arb` | **Edit.** The slab label, the sheet's field label, the confirm label (`Create {tag}`), the duplicate-tag warning sentence and the cap refusal line — each with a `description`. **No price, no currency symbol** |
| 7 | `docs/engineering/07-screens.md` §3.3 | **Edit — ruling N3.** Rewrite the `duplicateActiveTag` paragraph to say what actually happens |
| 8 | `docs/engineering/00-README.md` §10 | **Edit — ruling N3.** **Delete** the *"known open contradictions"* row naming `07 §3.3` versus `03 §6`. A doc set that still advertises a contradiction someone resolved is worse than one that never named it |
| 9 | `docs/engineering/CONVENTIONS.md` §2.9 **and §1** | **Edit.** Add the `EweStatus` row beside `Sex`, `BirthType` and `LambStatus`, **and** add `ewe_status.dart` to §1's `lib/domain/` tree in the same commit. §1 opens *"every path any of the seven documents names is either in this tree or is banned by a numbered ruling"* — a new domain file that is in neither state is a tree the next developer cannot trust |
| 10 | `test/data/flock_repository_test.dart` | **Edit.** `setStatus`, and the unique-index failure mapping |
| 11 | `test/features/flock_test.dart` | **Edit.** The anchor and the cap cases |
| 12 | `test/policy/cap_never_blocks_live_entry_test.dart` | **Edit.** Extend N14-T01's file with the calm-path arm. R57 and the critique's `[audit]` note: the doc-named file, extended, never a second copy |

### 5.2 The signatures

The domain enum, mirroring `ewes.status`'s CHECK byte for byte:

```dart
// lib/domain/ewe_status.dart
/// CONVENTIONS §2.9: "The Dart member and the stored key must be readable off
/// each other." The four keys are 03 §5.2's CHECK, and a stored enum key is
/// "snake_case, ASCII, frozen forever" (§4.6).
///
/// R41: `ewes.status` is a MUTABLE COLUMN. There is no ewe_status_events table
/// and `setStatus` has no undo verb, "because the previous value is recoverable
/// from the record's own context, not because a history row exists."
enum EweStatus {
  active('active'),
  sold('sold'),
  dead('dead'),
  culled('culled');

  const EweStatus(this.key);
  final String key;

  static EweStatus fromKey(String key) => …;   // throws on an unknown key
}
```

The write controller — every mutation through `guard()`, which is the double-tap defence:

```dart
// lib/features/flock/flock_write_controller.dart
/// CONVENTIONS §3.4: `<feature>WriteControllerProvider` is ALWAYS
/// `.autoDispose`. "Mutation" is a banned synonym (§5.2).
final flockWriteControllerProvider =
    NotifierProvider.autoDispose<FlockWriteController, WriteState>(
  FlockWriteController.new,
);

final class FlockWriteController extends WriteController {
  @override
  WriteState build() => const WriteIdle();

  /// 07 §3.3: EntryContext.calm. The SAME verb Quick Entry calls with
  /// EntryContext.liveEntry — one implementation, two contexts (critique S5).
  /// This is the ONE place in the app where the cap may honestly refuse.
  Future<void> createEwe(String tag) => guard(() async {
        final repo = await ref.read(flockRepositoryProvider.future);
        return repo.createEwe(tag: tag, context: EntryContext.calm);
      });

  /// R41. No undo verb; the previous value is in the record's own context.
  Future<void> setStatus(EweId ewe, EweStatus status) => guard(() async {
        final repo = await ref.read(flockRepositoryProvider.future);
        return repo.setStatus(ewe, status);
      });
}
```

The screen reacts through `ref.listen`, registered unconditionally at the top of `build`:

```dart
// lib/features/flock/flock_screen.dart
/// 02 §4.3: ref.listen is legal ONLY in build(), called unconditionally, and
/// never inside an `if`. Side effects — haptics, navigation, announcements —
/// live here and nowhere else.
///
/// The switch is exhaustive over a sealed type with NO `default:`. WriteOutcome
/// has three variants (CONVENTIONS §2.4); the day a fourth appears every switch
/// must fail to compile rather than swallow it.
ref.listen(flockWriteControllerProvider, (_, next) {
  if (next case WriteDone(:final outcome)) {
    switch (outcome) {
      case WriteCommitted(:final insertedId):
        // P2: the confirmation IS the committed row. The new ewe appears at the
        // head of the list because watchFlock() declares `ewes` in readsFrom.
        // There is no SnackBar (CLAUDE.md P2 supersedes CONVENTIONS §2.11).
        confirmSaved(context, _receiptFor(EweId(insertedId!)), const []);
      case WriteFailed(:final failure):
        showFailure(context, failure);
      case WriteRefused(:final reason):
        // A ROW, never a dialog. `showCapRow` is N14-T04's signature with its
        // two no-op guards; N30-T05 gives it a body. It never navigates from
        // here: Unlock is a SETTINGS SECTION, not one of the thirteen
        // RouteNames, and Settings is N29.
        showCapRow(context, reason);
    }
  }
});
```

Ruling **N3**, as the sheet's own logic:

```dart
// lib/features/flock/widgets/add_ewe_sheet.dart
/// RULING N3 — 07 §3.3 versus 03 §6, closed here.
///
/// The two documents describe the same moment differently. 03 §6 is the schema
/// and wins on what is storable: `CREATE UNIQUE INDEX idx_ewe_tag_active ON
/// ewes (tag) WHERE status = 'active'` makes a second ACTIVE 412 unstorable.
/// 07 §3.3 wins on what the shepherd sees: a collision is SHOWN, never
/// silently resolved (§12.4).
///
/// Both hold at once, because there is nothing to block:
///
///   * The match list ranks ACTIVE animals only (R26, tagIndexProvider).
///   * When an active 412 exists, the confirm bar reads "OPEN 412", not
///     "CREATE 412" — 06 §12: ShedConfirmBar is "labelled with the outcome".
///   * The 60 pt strip under the field states the collision in words:
///     "412 is already in use by an active ewe." That is the
///     WarningCode.duplicateActiveTag value, constructed HERE, by the
///     controller (R53), and never persisted — decision #54: there is no
///     `warnings` column and there is nowhere to persist one.
///   * So the warning "never blocks the create" (07 §3.3) is TRUE and vacuous:
///     no create is offered to block.
///
/// A tag held only by a culled, sold or dead animal raises nothing at all —
/// that tag is free (03 §6 item 4, and 07 §3.3's own last sentence).
///
/// The index may still fire, through a restore or a future un-cull. When it
/// does, the outcome is WriteFailed, mapped by shedFailureFrom — see §5.3.
```

### 5.3 The details that are easy to get wrong

- **`EntryContext.deliberate` does not exist.** The two members are `liveEntry` and `calm` (R69,
  `CONVENTIONS §2.10`). Every document that names this call site — `07 §3.3`, `11 §7.3`, `03 §6`'s two
  pinned tests, N14-T01 — spells it `calm`. If it appears anywhere in this diff, the file did not
  compile and something silenced the error.
- **Ruling N3's resolution must be *shown*, not asserted.** §12.4's hierarchy is *unrepresentable →
  unconstructible → unpersistable → source test → documented*, and a duplicate-tag warning that lives
  only in prose has dropped to the bottom. What holds it here is geometry: the confirm bar's **label**
  is derived from the match state, so *Create 412* is unreachable while an active 412 exists.
- **A bare `on SqliteException catch (e)` never matches.** `04 §4.6`: `drift_flutter` runs SQLite on a
  background isolate, so the exception arrives wrapped in a `DriftRemoteException`. Catch through
  `shedFailureFrom(Object)` in `lib/data/failure_mapping.dart` (R4 — there is **no**
  `ShedFailure.from`), which unwraps once and maps. `03 §6`'s second pinned test asserts the constraint
  *against the database*, not through the repository, *"because a repository-level assertion would also
  pass on a schema with no index."*
- **`createEwe` is one verb with two contexts, and there must never be a second implementation.**
  Critique **S5** moved `FreeTierPolicy` sixteen epics earlier for exactly this. If this task writes
  `_createEweFromFlock`, the gate is now in two places and one of them will drift.
- **`ewesInCurrentSeason` is the **post-write** count.** N14-T01's body passes
  `await _countEwesInCurrentSeason() + 1`. Do not re-derive it in the controller; do not pass the
  pre-write count and compare with `>`.
- **A calm refusal at 22:30 is `Allow`, permanently, and is not a bug.** `07 §19.3` rule 2 and
  `11 §7.4` say out loud: *"do not 'fix' it"* by deferring the refusal to the morning. Rule 1 of
  §19.4 is that the app never revokes: *"Rows over the cap are real rows."* Pin the behaviour with a
  test so nobody tries.
- **The refusal is a row, never a dialog, and never a navigation.** Decision #92 and `07 §19.2`: *"No
  modal, no interstitial, no self-appearing bottom sheet, no timed prompt, no badge, no colour change
  to red."* `ui.show_dialog` is a gate row. `07 §3.3` also says the over-cap create *"navigates to
  Unlock"* — **that half cannot land here**: Unlock is a Settings *section*, not a route, `RouteNames`
  has thirteen entries and none of them is `unlock`, and Settings is N29. State this in a comment
  naming N29/N30-T05 rather than inventing a fourteenth route.
- **`showCapRow` fires no haptic, deliberately** (`06 §10.1`), and renders nothing on a shed screen.
  N14-T04 landed its signature with two no-op guards; N30-T05 gives it a body. This task's job is that
  the call site exists and is correct.
- **Nothing on this screen may read `entitlementProvider`.** Decision #90: *"nothing on the shed path
  branches on `unlocked`."* The Flock screen is not one of the five shed screens, but the rule that
  matters here is narrower and stricter: the **verb** consults `FreeTierPolicy` inside the repository,
  so the widget never needs the entitlement at all. A widget that watches it is a paywall flash waiting
  to happen.
- **The price is never a literal.** `07 §3.2`, decision #92 and the `copy.currency_literal` gate row (a
  currency symbol followed by a digit under `lib/` or `assets/`). The refusal copy authored here names
  no figure; `ProductDetails.price` arrives at N30-T06.
- **`over_free_cap` is not a warning.** `11 §8.1`: no `WarningCode`, no badge, no colour, never in the
  receipt. If it renders anywhere in this diff, T03's row test should fail — and if it passes anyway,
  T03 is wrong.
- **The row is created on confirm, and there is no draft before it.** `CLAUDE.md` §4 and `07 §15.5`:
  *"there is no draft state, so 'Cancel' is not a verb."* The sheet's typed digits live in a private
  field on the notifier (`CONVENTIONS §4.4` rule 4), not in a half-written row. Closing the sheet
  without confirming writes nothing, and that is the *absence* of a draft, not the discarding of one.
- **`guard()` refuses to run concurrently, and that is the double-tap defence.** `00-README` §8 step 16
  calls it *"a UX safety feature wearing architecture's clothes."* The double-tap test is not optional
  — `00-README` §8 step 28 requires one for a destructive action, and `setStatus(culled)` is one.
- **`ShedKeypad` is the only tag-entry route, and it is a shared component.** R70 and `06 §8.1`:
  `lib/core/ui/components/shed_keypad.dart`, built at N13-T04. A `TextField` with a numeric keyboard
  here is a second entry model and a layer-6 temptation; `features/flock/widgets/big_keypad.dart` does
  not exist and must not be created.
- **There is never placeholder text inside the field.** Indelible §7.12: *"In the dark, a grey
  placeholder is indistinguishable from an entered value."* The hint lives in the label, above the
  line.
- **The sheet has no drag handle and closes with a word button.** Indelible §7.14: it is the **only**
  overlay in the app, `enableDrag: false`, `isDismissible: false`, `showDragHandle: false`
  (`06 §12`), and *"a handle that cannot be dragged is a lie."* Closing is an 88 × 64 `CLOSE`.
- **The slab is bottom-right and 160 × 140.** Indelible §7.1 and §4.5: it is the largest target in the
  system and it lives in the thumb band (0–320 px from the bottom). It mirrors to bottom-left when
  `app_settings.left_handed` is set (R40) — read it, do not re-derive it.
- **`setStatus` writes `updated_at` and nothing else, and the tag is released in the same statement.**
  `03 §6` item 4: *"`UPDATE ewes SET status = 'culled'` drops the row out of the partial index in the
  same statement. Nothing else needs to happen."* Do not clear the tag, do not write a history row,
  do not touch `ewe_touches`.

### 5.4 The full test set

| File | Case | What it asserts |
|---|---|---|
| features | `'add a ewe uses createEwe with EntryContext.calm and can return BlockedByCap'` | **The anchor.** At 11:00 and at the cap: `WriteRefused(RefusalReason.eweCap)` and `COUNT(*) FROM ewes` unchanged. At 22:30: `WriteCommitted`, `over_free_cap = 1`, the row present |
| features | `'the refusal renders as a row and never as a dialog'` | `find.byType(Dialog)` and `find.byType(AlertDialog)` are `findsNothing`; `ui.show_dialog` stays green |
| features | `'the refusal does not navigate'` | The Navigator depth is unchanged. `07 §3.3`'s *"navigates to Unlock"* half is N29/N30's, and there is no `RouteNames.unlock` |
| features | `'the refusal copy contains no currency symbol and no figure'` | `copy.currency_literal`. Rendered text matches no `[£$€]\s?\d` |
| features | `'typing an active tag labels the confirm bar OPEN 412, not CREATE 412'` | **Ruling N3.** The create is unreachable, so it cannot be blocked |
| features | `'typing an active tag renders the duplicate-tag sentence in words'` | The 60 pt strip, the ARB string, the `WarningCode.duplicateActiveTag` value constructed in the controller |
| features | `'typing a tag held only by a culled ewe offers CREATE and raises nothing'` | `03 §6` item 2 and `07 §3.3`'s last sentence — *that tag is free* |
| features | `'a double tap on confirm creates one ewe'` | `guard()` refuses to run concurrently. `tester.tap(); tester.tap();`, then `COUNT(*)` |
| features | `'a double tap on cull writes one status change'` | `00-README` §8 step 28: a destructive action gets a double-tap test |
| features | `'closing the sheet without confirming writes nothing'` | There is no draft. `COUNT(*) FROM ewes` unchanged; `07 §15.5` |
| features | `'the sheet has no drag handle and cannot be dismissed by a tap outside'` | Indelible §7.14, `06 §12`. `enableDrag: false`, `isDismissible: false` |
| features | `'the field renders no placeholder'` | Indelible §7.12. The `TextField`'s `decoration.hintText` is null; the hint is in the label |
| features | `'the slab is at least 160 by 140 and sits in the bottom 320 px'` | Indelible §7.1 and §4.5, at `Device.small` |
| features | `'the slab mirrors to bottom-left when left_handed is set'` | R40; `app_settings.left_handed`, read not re-derived |
| features | `'nothing in the flock feature watches entitlementProvider'` | Decision #90. `FakePurchaseService.calls` is empty through every pump in this file |
| data | `'setStatus culled drops the ewe out of the partial unique index'` | `03 §6` item 4. Cull, then create the same tag again: two rows, two uids, `newId != oldId` |
| data | `'setStatus writes updated_at and creates no history row'` | R41. No `ewe_status_events` table exists; assert the table list is unchanged |
| data | `'a duplicate active tag insert maps to WriteFailed, not an escaping exception'` | `04 §4.6`. Force the index through the database, and assert `shedFailureFrom` unwraps the `DriftRemoteException` — a bare `on SqliteException` clause must not be present in the diff |
| data | `'createEwe from the calm path fires the ewes → search_docs trigger'` | `03 §9.2` and the `COALESCE` rule: a ewe with no notes must not abort the insert with a `NOT NULL` failure |
| policy | `'startSeason returns WriteRefused at the cap and createEwe on the live-entry path does not'` | N14-T01's file, **extended** with the calm arm. The critique's `[audit]` note: the doc-named file, never a second copy (R57) |
| features · **`@Tags(['uk-zone'])`** | `'the quiet-hours degrade holds at 01:30 and at 01:30 again on the clocks-back night'` | `TZ=Europe/London`, `withClock` at **01:30**, twice across the repeated hour. 01:30 is inside 22:00–06:00 both times, so both taps must `Allow(overFreeCap: true)` — a naive UTC comparison flips one of them |
| features · **`@Tags(['uk-zone'])`** | `'a create at 22:00:00 exactly is inside the quiet window'` | The boundary. `11 §7.4`'s window is inclusive at 22:00 and exclusive at 06:00; assert both edges under `TZ=Europe/London` |

### 5.5 What this task deliberately does not build

- **The static over-cap upgrade row.** `07 §3.2` pins it to the top of this screen and `06 §12` makes
  `ShedBanner` its only component — both are **N30-T05's**. `showCapRow`'s body is N30-T05's too.
- **Unlock, Restore and the price.** N29 (the Settings section) and N30-T06 (`ProductDetails.price`).
- **An undo for `setStatus`.** R41: there is none, and the reason is that the previous value is
  recoverable from the record's own context.

## 6. Constraints that bind this task

- **Write path** — the row is created on confirm, not on exit. No draft, no Save button, no `commit()`, no optimistic UI; every write commits immediately and goes through `guard()`.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. Here specifically: **the free tier** / **the cap**, never *trial*, *freemium* or *paywall*; **unlock**, never *purchase*, *buy* or *subscribe*.
- **3am** — the slab is `tapHero`-class and the keypad keys are `tapPrimary`; no swipe, no drag, no drag handle, no long-press, no hold-to-repeat.
- **Safety rule §12.4, as a mechanism** — ruling N3 must leave the rule at *unconstructible*, not drop
  it to *documented*. What holds it is the confirm bar's derived label, and the test that reads it.

## 7. Definition of Done

- [ ] `'add a ewe uses createEwe with EntryContext.calm and can return BlockedByCap'` passes, and was seen to fail first for the stated reason
- [ ] one `createEwe` implementation, two contexts
- [ ] the cap may refuse here and says why
- [ ] the refusal is a row, never a dialog
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the commit message notes the `deliberate` → `calm` correction to the anchor's name
- [ ] **ruling N3 is closed by an amendment to `07 §3.3` in this commit, and `00-README` §10's *"known open contradictions"* row is deleted in the same commit** — or both are carried into the PR body as open with both sides cited
- [ ] `EntryContext.deliberate` appears nowhere in `lib/`, `test/` or `docs/`
- [ ] the confirm bar reads `OPEN 412` when an active 412 exists and `CREATE 412` when one does not
- [ ] a tag held only by a culled, sold or dead animal raises no warning at all
- [ ] a unique-index violation becomes `WriteFailed` through `shedFailureFrom`; no `on SqliteException` clause appears in the diff
- [ ] a double tap on confirm creates one ewe, and a double tap on cull writes one status change
- [ ] closing the sheet without confirming writes nothing
- [ ] `setStatus` creates no history row and clears no tag (R41, `03 §6` item 4)
- [ ] `EweStatus` has a row in `CONVENTIONS §2.9`, added in this commit, with keys byte-identical to `ewes.status`'s CHECK
- [ ] nothing in `lib/features/flock/` watches `entitlementProvider` or `purchaseServiceProvider`
- [ ] the refusal copy names no price and contains no currency symbol
- [ ] `drift_schemas/` is untouched

## 8. Verification

```bash
fvm flutter test test/features/flock_test.dart
make check
make test
```

```bash
fvm flutter test test/data/flock_repository_test.dart
fvm flutter test test/policy/cap_never_blocks_live_entry_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
```

```bash
grep -rn "EntryContext.deliberate" .                          # expect zero, everywhere
grep -rn "createEwe" lib/ | grep -v "^lib/data/flock_repository.dart"   # expect exactly two call sites
grep -rn "on SqliteException" lib/                            # expect zero (04 §4.6)
grep -rn "showDialog(\|AlertDialog" lib/features/flock/       # expect zero (ui.show_dialog)
grep -rEn "[£$€][[:space:]]?[0-9]" lib/ assets/               # expect zero (copy.currency_literal)
grep -rn "entitlementProvider\|purchaseServiceProvider" lib/features/   # expect zero
grep -rn "big_keypad" lib/                                    # expect zero (R70)
git diff main -- docs/engineering/00-README.md                # the deleted contradiction row
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(flock): add a ewe through the same gated createEwe verb`
