# N17-T01 — `lambCardProvider` — one statement, rearing dam from the view

| | |
|---|---|
| **Epic** | [N17 — Lamb Card](epic.md) · `00-README` §9 step 6 (3 of 5) |
| **Task** | 1 of 5 |
| **Depends on** | N16-T09 |
| **Commit** | one commit · `feat(lamb_card): one statement, rearing dam from the view` |

## 1. Why this task exists

One statement producing `LambCardData`, with the **current rearing dam read from the
`lamb_rearing` view** rather than from a column — because the rearing dam is the latest foster event,
and storing it twice is how the two copies disagree.

Decision #33 rejects the column by name: a denormalised current-rearing-dam column is a dual write a
future code path gets wrong, producing a lamb whose history says *"fostered to 128"* while the list
screen says *"412"*. The birth dam is a column and is immutable in SQL; the rearing dam is a
projection of an append-only log. This task is where that distinction stops being prose.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§7.1** | `lambCardQuery`, and the exact `readsFrom:` set — *"`lamb_rearing` is a view, so its base tables are what the stream is keyed on"* |
| `docs/engineering/07-screens.md` | §7.2 | the six states, including the **two** null-rearing-dam states that are never merged |
| `docs/engineering/07-screens.md` | §1.2, §1.4 | the one-query rule stated exactly, and the state vocabulary |
| `docs/engineering/07-screens.md` | §4.1 | the Ewe Card union this screen's history is modelled on, with its seven identical columns |
| `docs/engineering/03-data-model-and-schema.md` | **§7** | the `lamb_birth_dam_is_immutable` trigger and the `lamb_rearing` view, both printed in full |
| `docs/engineering/03-data-model-and-schema.md` | §5.5, §5.8, §5.11 | `Lambs`' columns, `Treatments.lamb`, `Notes.lamb` |
| `docs/engineering/CONVENTIONS.md` | §3.2, §3.4, §1.1 rules 3 and 5, §4.6, R33 | `lambCardProvider`'s type and file, the closed controller list, the layer rules, view naming, ids across boundaries |
| `docs/engineering/02-state-di-navigation.md` | §5.1, §4.2, §8 | the `async*` read-provider shape, the auto-dispose policy, the push helper |
| `docs/design/indelible.md` | §8 screen 5, §7.3, §7.7 | the summary row, the two parentage rows, and `PERMANENT` as a boxed stamp |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-riverpod-providers` | one statement per screen and its rebuild scope |
| `shed-drift-schema` | the `lamb_rearing` view is the source of truth for the current dam |

`shed-screens-and-routing` is the next skill this pair names — the route helper and the screen shell
are its subject, and `CLAUDE.md` caps auto-firing at two per intent.

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/lamb_card_test.dart`
- **Test** — `'the rearing dam is read from lamb_rearing and changes when a foster event is appended'`
- **Why it is red today** — nothing reads a lamb back.

```bash
fvm flutter test test/features/lamb_card_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — one statement over the view, with an explicit `readsFrom:`.

Sharpen the assertion while you are writing it: pump the card, read the rendered rearing dam, insert
a `FosterEvent` **directly against the in-memory database**, pump again, and assert three things —
the rendered rearing dam moved, `lambs.birth_dam` did not, and `lambs.updated_at` did not. The third
is what proves the value is projected rather than copied.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 steps 3 (the read side of the write path), 4 (wiring), 5 (controller), 6 (UI + the
route helper + the ARB) and 7 (tests). **Step 1 is skipped and the commit message says so**: the
lambing cluster froze at N07-T04 and this task stores nothing. Step 2 is skipped: nothing here
computes.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `test/features/lamb_card_test.dart` | new | The anchor, written first |
| 2 | `lib/data/lambing_repository.dart` | edit | `LambCardData`, `LambHistoryRow`, `LambRearing`, and `Stream<LambCardData> watchLambCard(LambId lamb)` — the one `customSelect` with its explicit `readsFrom:`. The **only** file in this task that may say `customSelect` |
| 3 | `lib/features/lambing/lamb_card_controller.dart` | new | `lambCardProvider`, `LambCardState`, `LambCardController`, `lambCardControllerProvider`. No drift import, no SQL, no `BuildContext` |
| 4 | `lib/features/lambing/lamb_card_screen.dart` | new | `LambCardScreen`, the `headingLevel: 1` title, the summary row, the two parentage rows, the four action word-buttons, and the five reachable states from `07 §7.2` |
| 5 | `lib/routing/routes.dart` | edit | `Routes.lambCard(BuildContext, LambId)` — the second push helper in the app. `RouteNames.lambCard` already exists from N13-T01 |
| 6 | `lib/features/lambing/widgets/` (the lamb sub-row from N16-T03) | edit | The sub-row gains its tap. Same feature folder, one route deeper — not a sibling import |
| 7 | `lib/l10n/app_en.arb` | edit | Every string this screen renders, each with a `description`. `lambCardTitle`, `lambCardBirthDam`, `lambCardRearingDam`, `lambCardPermanent`, `lambCardNoEweBottle`, `lambCardNoEweNotRecorded`, `lambCardNothingElseRecorded`, `lambCardUntagged` |
| 8 | `test/support/harness.dart` | edit | Nothing yet. **T05** adds the `kPumpableVariants` row; adding it here makes T05 empty and hides the count assertion in a task that is not about it |

### 5.2 The statement

One `customSelect`, fanned in **in SQL**. `07 §7.1` fixes the dependency set; the `WITH` carries the
header onto every history row so there is one statement and one dependency list.

```sql
WITH card AS (
  SELECT lb.id  AS lamb_id,  lb.tag        AS tag,        lb.sex           AS sex,
         lb.birth_weight_g   AS birth_weight_g,           lb.status        AS status,
         lb.death_date       AS death_date,               lb.death_cause   AS death_cause,
         lb.pet_lamb         AS pet_lamb,                 lb.bottle_feeds  AS bottle_feeds,
         lb.struck           AS struck,                   lb.struck_at     AS struck_at,
         lb.lambing          AS lambing_id,
         lg.occurred_at      AS born_at,                  lg.local_date    AS born_local_date,
         lg.captured_at      AS born_captured_at,
         lg.original_effective AS born_original_effective,
         lg.time_source      AS born_time_source,
         lr.birth_dam        AS birth_dam,    bd.tag      AS birth_dam_tag,
         lr.rearing_dam      AS rearing_dam,  rd.tag      AS rearing_dam_tag,
         lr.was_fostered     AS was_fostered,
         (SELECT fe.outcome FROM foster_events fe
           WHERE fe.lamb = lb.id
           ORDER BY fe.effective_at DESC, fe.id DESC LIMIT 1) AS latest_outcome
    FROM lambs lb
    JOIN lambings     lg ON lg.id      = lb.lambing
    JOIN lamb_rearing lr ON lr.lamb_id = lb.id
    JOIN ewes         bd ON bd.id      = lb.birth_dam
    LEFT JOIN ewes    rd ON rd.id      = lr.rearing_dam
   WHERE lb.id = :lamb
)
SELECT c.*, 'born' AS kind, c.lambing_id AS ref, c.born_at AS at,
       c.born_captured_at AS captured_at,
       c.born_original_effective AS original_effective,
       c.born_time_source AS time_source
  FROM card c
UNION ALL
SELECT c.*, 'foster', f.id, f.effective_at, f.captured_at, f.original_effective, f.time_source
  FROM card c JOIN foster_events f ON f.lamb = c.lamb_id
UNION ALL
SELECT c.*, 'care', ce.id, ce.occurred_at, ce.captured_at, ce.original_effective, ce.time_source
  FROM card c JOIN care_events ce ON ce.lamb = c.lamb_id
UNION ALL
SELECT c.*, 'treatment', t.id, t.administered_at, t.captured_at, t.original_effective, t.time_source
  FROM card c JOIN treatments t ON t.lamb = c.lamb_id
 ORDER BY at DESC;
```

### 5.3 The signatures

```dart
// lib/data/lambing_repository.dart — declared here, not in the feature file. See §5.4 note 1.

/// One history row on the Lamb Card. `kind` is the union arm; the §12.5 triple
/// travels with every row so no arm can be rendered without its provenance.
final class LambHistoryRow {
  const LambHistoryRow({
    required this.kind,        // 'born' | 'foster' | 'care' | 'treatment'
    required this.ref,         // the source row's id, raw int — never leaves this layer
    required this.at,
    required this.capturedAt,
    required this.timeSource,
    this.originalEffective,
  });
  final String kind;
  final int ref;
  final Instant at;
  final Instant capturedAt;
  final Instant? originalEffective;
  final TimeSource timeSource;
}

/// Both dams, and the two different reasons the rearing dam can be absent.
/// `rearingDam == null` is NEVER rendered with one string (07 §7.2).
final class LambRearing {
  const LambRearing({
    required this.birthDam,
    required this.birthDamTag,
    required this.wasFostered,
    this.rearingDam,
    this.rearingDamTag,
    this.latestOutcome,        // 'to_ewe' | 'to_bottle' | 'removed_unknown' | null
  });
  final EweId birthDam;
  final String birthDamTag;
  final bool wasFostered;
  final EweId? rearingDam;
  final String? rearingDamTag;
  final String? latestOutcome;
}

final class LambCardData {
  const LambCardData({
    required this.lambId,
    required this.lambingId,
    required this.bornAt,
    required this.bornLocalDate,
    required this.bornTime,    // RecordedTime, rebuilt from the lambing's quad
    required this.rearing,
    required this.status,
    required this.petLamb,
    required this.bottleFeeds,
    required this.history,     // never empty: the 'born' arm always yields one row
    this.tag,
    this.sex,                  // Sex? — NULL is "not recorded", never Sex.unknown (R45)
    this.birthWeight,          // Grams?
    this.deathDate,            // LocalDate?
    this.deathCauseKey,        // a vocab_terms key, or null = unattributed
    this.struckAt,
  });
  // …
}

/// The ONE statement. `readsFrom` names the view's BASE tables, never the view.
Stream<LambCardData> watchLambCard(LambId lamb);
```

```dart
// lib/features/lambing/lamb_card_controller.dart
final lambCardProvider =
    StreamProvider.autoDispose.family<LambCardData, LambId>((ref, lambId) async* {
  final repo = await ref.watch(lambingRepositoryProvider.future);
  yield* repo.watchLambCard(lambId);
});

/// Screen state, never data (CONVENTIONS §4.4 rule 1): which inline cell is open.
final lambCardControllerProvider =
    NotifierProvider.autoDispose.family<LambCardController, LambCardState, LambId>(
        LambCardController.new);
```

```dart
// lib/routing/routes.dart
static Future<void> lambCard(BuildContext context, LambId id) =>
    Navigator.of(context).push(_route(
      RouteNames.lambCard,
      (_) => LambCardScreen(lambId: id),
    ));
```

### 5.4 The details that are easy to get wrong

1. **`LambCardData` belongs in `lib/data/`, not beside its provider.** `10 §9.1`'s Definition of Done
   puts `PenTile` / `PenTileStatus` in `lib/features/pens/pen_board_controller.dart`, and copying
   that placement here is the obvious move. It does not compile: `02 §5.1`'s read-provider shape has
   the **repository** return the stream, and layer rule 3 forbids `lib/data/` from importing
   `lib/features/`, so `lambing_repository.dart` could not name its own return type. The analyzer
   only tells you once both files exist and you have written the import. `CONVENTIONS §3.2` fixes the
   file for the **provider**; it says nothing about the type.
2. **`lamb_rearing` is a view, and it never appears in `readsFrom:`.** `07 §7.1` is explicit:
   *"`lamb_rearing` is a view, so its base tables are what the stream is keyed on, not the view
   name."* The set is exactly `{lambs, lambings, ewes, fosterEvents, careEvents, treatments}` —
   `db.lambs, db.lambings, db.ewes, db.fosterEvents, db.careEvents, db.treatments`. Get this wrong
   and the screen renders correctly once and then never updates again, which is the worst failure
   shape available: it passes every test that pumps a fixture and fails on a real phone in a shed.
3. **The header must not vanish when there is no history.** Joining the `card` CTE to the history
   arms means a lamb with nothing recorded returns **zero rows**, and the screen shows Empty for a
   lamb that plainly exists — which is also the commonest state in the first hour. The `'born'` arm
   fixes it: `lambs.lambing` is `NOT NULL`, so that arm always yields exactly one row. This is why
   `07 §7.2`'s empty copy is *"Nothing **else** recorded."* — the word *else* is load-bearing.
4. **The rearing dam is `NULL` for two different reasons and they are two different strings.**
   `07 §7.2` and `03 §7`: `foster_events.outcome = 'to_bottle'` → **"No ewe — bottle"**, null *by
   intent*; `outcome = 'removed_unknown'` → **"No ewe — not recorded"**, null *by omission*. Both
   belong to no ewe's reared count; only the first is a husbandry fact. That is why `latest_outcome`
   is in the statement — you cannot tell the two apart from `rearing_dam IS NULL` alone. Rendering
   them with one string is the app deciding they are the same, which is a §12.4 violation.
5. **A lamb with no foster events is reared by its birth dam, and that is a fact, not a guess.** The
   view's `COALESCE` falls through to `lb.birth_dam` **only when no foster event exists at all**; once
   one exists, `rearing_dam` is whatever the latest event says, including `NULL`. Do not "improve"
   this by defaulting to the birth dam whenever the latest event is null — that silently un-bottles
   every bottle lamb.
6. **The birth-dam cell has no target on it, and that is the guarantee.** Indelible §8 screen 6:
   *"The birth dam is a cell with no target on it; there is no path through the UI that changes it,
   which is a stronger guarantee than a warning dialog."* No `ShedTapTarget`, no `onTap`, no
   `GestureDetector` anywhere in that subtree. The SQL trigger `lamb_birth_dam_is_immutable` is the
   second line of defence, not the first.
7. **`ORDER BY at DESC` sorts on the event instant, never on the row id.** A lamb treated at 22:00
   and entered at 07:00 the next morning sorts by 22:00. `at` is `INTEGER` epoch millis, so the sort
   is absolute-time and needs no timezone.
8. **`ref` stays inside `lib/data/`.** R33: a bare `int` never crosses a repository, controller,
   route-helper or provider-family boundary. `LambHistoryRow.ref` is the source row's raw id and the
   one call site that needs it wraps it; the family key is `LambId`, never `int`.
9. **`lambCardProvider` is `.autoDispose.family`, and `lambCardControllerProvider` is too.**
   `CONVENTIONS §3.2` and §3.4: per-animal screens auto-dispose; only the three hub screens are
   keepAlive. A keepAlive family keyed on `LambId` leaks one stream per lamb the shepherd opens over
   a night.
10. **There is no `lambCardWriteControllerProvider`.** `CONVENTIONS §3.4` publishes the controller
    list and it is not in it — §4.4 rule 2 is one write controller per **feature**. T02–T04's writes
    go through `lambingWriteControllerProvider`, built at N16.
11. **The screen has one `headingLevel: 1` node and no level 2.** `10 §3.4` is explicit that Quick
    Entry, Lambing Entry, Lamb Card, Foster and note search *"deliberately get no level-2 headings:
    each is one task, and heading stops would add navigation to screens whose entire purpose is not
    having any."* `Semantics(header: true)` is a no-op on 3.44 and is a gate row (`a11y.header_bool`).
12. **Frame 1 is impossible on this screen and the brief says why.** `07 §7.2`: it is reached only
    from a loaded Lambing Entry, Ewe Card or pen tile, and the row is committed before any of those
    can offer the tap. Do not write a placeholder state for it — and never a spinner (`ui.spinner`).
13. **`notes` is not in `readsFrom:` and therefore has no arm.** If you add a notes arm, add `notes`
    to `readsFrom:` **in the same edit**. drift will not warn you; the arm will render once and then
    go stale.
14. **`treatments` and `care_events` reach a lamb by different columns.** `treatments` has a
    polymorphic subject (`CHECK ((ewe IS NOT NULL) + (lamb IS NOT NULL) = 1)`); `care_events` has
    `CHECK ((lambing IS NOT NULL) + (lamb IS NOT NULL) = 1)`. Joining `care_events` on `ce.lamb`
    alone is correct **here** — a lamb's own care events — and is exactly the join that would be
    wrong on the Lambing Entry, where the pre-lamb events hang off `lambing`.

### 5.5 The full test set

**`test/features/lamb_card_test.dart`** — new. Widget tests through `pumpApp` against
`NativeDatabase.memory()`; no mocks, no overridden repository (`02 §5.4`: override leaves, never
controllers).

| Case | What it pins |
|---|---|
| `'the rearing dam is read from lamb_rearing and changes when a foster event is appended'` | **the anchor.** Pump, read the cell, insert a `FosterEvent`, pump, assert the cell moved, `lambs.birth_dam` did not, and `lambs.updated_at` did not |
| `'a lamb with no foster event is reared by its birth dam'` | the view's `COALESCE` fall-through — both cells read the same tag, and `was_fostered` is `0` |
| `'to_bottle and removed_unknown render two different strings'` | two lambs, two outcomes, two ARB keys, and an assertion that neither string contains the other |
| `'a lamb with nothing recorded still renders its header and one history row'` | the `'born'` arm. The screen is **not** Empty; the empty copy is *"Nothing else recorded."* |
| `'the birth dam cell exposes no tap action'` | walk the subtree under `Key('lamb_card.birth_dam')`: no `SemanticsAction.tap`, no `GestureDetector`, no `ShedTapTarget` |
| `'an untagged lamb renders normally, not as an empty state'` | `07 §7.2`: identity is the row id; `tag` is nullable at every layer |
| `'the history sorts on the event instant, not the row id'` | insert a treatment with `administered_at` earlier than a care event inserted first; assert the render order |
| `'the screen carries exactly one headingLevel 1 node and no headingLevel 2'` | `10 §3.4` |
| `'no monetization widget renders at any entitlement state'` | the Lamb Card is one of the five shed screens (`11 §8`); this case is folded into `no_monetization_test.dart` at N30-T08 and asserted locally here |

**`test/data/lambing_repository_test.dart`** — extended. Repository tier, against
`NativeDatabase.memory()`.

| Case | What it pins |
|---|---|
| `'watchLambCard emits again when a foster event is appended'` | the `readsFrom:` set is right. Listen, insert, expect a second emission within the same test — this is the case that catches a missing table |
| `'watchLambCard emits again when the lamb row is updated'` | `lambs` is in the set |
| `'watchLambCard does not name the lamb_rearing view in readsFrom'` | source read of `lambing_repository.dart`: the `readsFrom:` literal contains the six table getters and no view |
| `'UPDATE lambs SET birth_dam throws'` | already green from N07-T04; re-asserted here because this is the screen that renders it |
| `'the statement returns one row for a lamb with no history'` | the `'born'` arm, at the data tier |

**`test/domain/uk_zone/lamb_card_ambiguous_hour_test.dart`** — new, `@Tags(['uk-zone'])`, run under
`TZ=Europe/London`. Every file in this tier carries `05 §2.9`'s `setUpAll` offset assertion — a
skipped safety test is a broken safety test.

| Case | What it pins |
|---|---|
| `'a lamb born at 01:30 on 25 October reports its wall time and its civil date unchanged'` | `LocalDate.of(bornAt)` is `2026-10-25` for either of the two candidate instants; the header prints `01:30`; no warning fires (the **ambiguous** hour is deliberately not warned about) |

## 6. Constraints that bind this task

- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Layer rules 3 and 5** — `lib/features/` may not import `package:drift` or `lib/core/db/`, and `lib/data/` may not import `lib/features/`. The statement lives in the repository; the provider watches the `Stream` it returns.
- **The one-query rule, stated exactly** (`07 §1.2`) — one *content* statement. `combineLatest` over drift streams is a build-breaking defect; fan-in happens in SQL.
- **`00-README` §8 step 1 skipped** — this task stores nothing and the commit message says so. No file under `drift_schemas/` or `lib/core/db/tables/` may appear in the diff.

## 7. Definition of Done

- [ ] `'the rearing dam is read from lamb_rearing and changes when a foster event is appended'` passes, and was seen to fail first for the stated reason
- [ ] the rearing dam comes from the view
- [ ] the birth dam is rendered beside it, always, and never replaced
- [ ] one statement, explicit `readsFrom:`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/features/lamb_card_test.dart
fvm flutter test test/data/lambing_repository_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
grep -rn "rearing_dam" lib/data/ lib/features/     # reads only — no assignment, no UPDATE
grep -rn "combineLatest" lib/features/lambing/     # expect: nothing
grep -rn "package:drift" lib/features/             # expect: nothing
dart tool/check_policy.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(lamb_card): one statement, rearing dam from the view`
