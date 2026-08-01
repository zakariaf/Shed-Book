# N18-T02 — The one-tap reassignment

| | |
|---|---|
| **Epic** | [N18 — Foster](epic.md) · `00-README` §9 step 6 (4 of 5) |
| **Task** | 2 of 5 |
| **Depends on** | N18-T01 |
| **Commit** | one commit · `feat(foster): one-tap reassignment over the Quick Entry deck` |

## 1. Why this task exists

Reassignment in **one tap**, reusing Quick Entry's deck query rather than inventing a
second one — because two queries for *which ewes are available* is two answers, and the one the
shepherd sees at 3am should be the one they already know.

Reusing it is not a matter of taste: **layer rule 6 forbids `lib/features/lambing/` from importing
`lib/features/quick_entry/`**, so `quickEntryDeckProvider` in its published location is unreachable
from this screen. This task rules that placement — on R27's precedent, which named this exact screen
— before it writes a line of UI.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §8 | Foster |
| `shed-book-spec.md` | §7.3 | birth dam and rearing dam as separate fields, reassignment in two taps or fewer |
| `docs/engineering/03-data-model-and-schema.md` | §5 | `foster_events`, the trigger and the `lamb_rearing` view |
| `docs/engineering/07-screens.md` | §8.1–§8.3, §8.5, §1.3, §20 | one tap with no confirmation step; the deck reused; the two no-ewe targets; the tap table; primary actions in the bottom third and back as a bottom-bar button |
| `docs/engineering/07-screens.md` | §5.2 | the deck statement itself — two buckets, one stream, `readsFrom:` and `.distinct()` in the repository |
| `docs/engineering/CONVENTIONS.md` | §1.1 **layer rules 5 and 6**, §3.2, §3.4, §4.1–§4.5, R26, R27, R28, R30, R31, R33 | why the provider must move, what the controllers are called, and how a widget key is spelled |
| `docs/engineering/02-state-di-navigation.md` | §4–§6 | provider shapes, `WriteController.guard()`, the navigator key and the typed push helper |
| `docs/engineering/12-testing.md` | §5.1, §10.1 | `pumpApp`, and the published body of the 1-tap test |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.2, §3.3, §3.4, §8.4, §8.5 | label rules, `spellOutTag`, one level-1 heading and no level-2, and the terminology placeholder |
| `docs/design/indelible.md` | §7.13–§7.16, §8 screen 6, §4.4, §4.5 | the word button, the recents line, the ruled record row, and *"the birth dam is a cell with no target on it"* |
| `epics/00-PLAN-CRITIQUE.md` | S2, S3 | each screen epic adds its own route helper; the fixtures do not exist until N23 |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-screens-and-routing` | the screen, its route and its tap cost |
| `indelible-page-and-screens` | the page composition and the target geometry |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/tap_budget_test.dart`
- **Test** — `'foster reassignment from the Foster screen costs 1 tap'`
- **Assertion, spelled out** — seed a lamb and two ewes; capture `birthDamBefore` from the lamb row;
  `pumpApp(FosterScreen(lambId: lamb))`; `countedTap(find.byKey(const Key('foster.target.128')), c)`;
  then `expect(c.taps, 1)`, `expect(c.textEntries, 0)`, the single `foster_events` row reads
  `outcome == 'to_ewe'`, and `readLamb(db, lamb).birthDam == birthDamBefore`. The count is **1**, not
  *at most 1*: this is the budget CI holds and a screen that got cheaper would mean a target moved.
- **Why it is red today** — there is no Foster screen, and spec §7.3 says this is the flow most likely to be abandoned if it takes five taps.

```bash
fvm flutter test test/features/tap_budget_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the screen over the existing deck provider, one tap to commit.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 steps 4, 5, 6 and 7. Step 1 is skipped (the schema is frozen; N07-T08) and step 3 is
T01's — this task adds no repository method. Say both in the commit message.

### 5.1 The files, in order

| # | File | What changes, and why |
|---|---|---|
| 1 | `docs/engineering/CONVENTIONS.md` §3.2 + §6 | **The ruling.** `quickEntryDeckProvider`'s file column becomes `lib/data/providers.dart`, recorded as a numbered ruling in §6 with its *"files that must change"* line. Read §6 to find the next free number — R74 is the highest as compiled and N00-T05 takes R75 |
| 2 | `docs/engineering/02-state-di-navigation.md` §4 · `07-screens.md` §5.2, §8.2, §8.5 | The same-commit amendments the ruling forces (`00-README` §10): the provider's home, and the three new widget keys 07 owns |
| 3 | `lib/data/providers.dart` | Move the `quickEntryDeckProvider` declaration here, beside `tagIndexProvider`, keepAlive, unchanged in name and type. `QuickEntryDeck` and `DeckEntry` move with it — a feature file cannot be imported by another feature, and that is the whole reason |
| 4 | `lib/features/quick_entry/quick_entry_controller.dart` | Edit: delete the declaration, import it. Quick Entry's two strips keep reading it with `.select((d) => d.penned)` / `.select((d) => d.recents)` — R28 is unchanged, only the file is |
| 5 | `lib/features/lambing/foster_controller.dart` | **New.** `fosterControllerProvider` — `NotifierProvider.autoDispose.family<FosterController, FosterState, LambId>`. Screen state only: the typed digits and the match list. No `BuildContext`, no drift, no navigation |
| 6 | `lib/features/lambing/foster_write_controller.dart` | **New.** `fosterWriteControllerProvider` — `NotifierProvider.autoDispose<FosterWriteController, WriteState>`, extending `WriteController`. Every commit goes through `guard()` |
| 7 | `lib/features/lambing/foster_screen.dart` | **New.** `FosterScreen`, the widget `12 §6.2` names and T05 pumps |
| 8 | `lib/features/lambing/widgets/foster_no_ewe_targets.dart` | **New.** The two 72 pt targets. A widget, not a chooser: they commit, they do not open anything |
| 9 | `lib/routing/routes.dart` | Edit: `RouteNames.foster` already exists (N13-T01); add the `onGenerateRoute` case and the typed push helper. Critique S2: each screen epic adds its own |
| 10 | `lib/l10n/app_en.arb` | The screen's strings, each with a `description`, each domain noun a `{term}` placeholder |
| 11 | `test/features/tap_budget_test.dart` | **Extend** (N14-T06 created it). The anchor |
| 12 | `test/features/foster_test.dart` | **New.** The screen's own cases, §5.4 |
| 13 | `test/features/routing_test.dart` | **Extend.** The route name reaches `RouteSettings`, which is what the diagnostics log is allowed to record |
| 14 | `test/features/foster_dst_test.dart` | **New**, `@Tags(['uk-zone'])`. The widget tier of `12 §2.4` |

### 5.2 The signatures

```dart
// lib/features/lambing/foster_screen.dart
class FosterScreen extends ConsumerWidget {
  const FosterScreen({super.key, required this.lambId});
  final LambId lambId;                      // an extension-type id, never a bare int (R33)
}

// lib/features/lambing/foster_controller.dart — CONVENTIONS §3.4
final fosterControllerProvider =
    NotifierProvider.autoDispose.family<FosterController, FosterState, LambId>(
        FosterController.new);

// lib/features/lambing/foster_write_controller.dart
final fosterWriteControllerProvider =
    NotifierProvider.autoDispose<FosterWriteController, WriteState>(
        FosterWriteController.new);

final class FosterWriteController extends WriteController {
  Future<void> reassign(LambId lamb, FosterOutcome outcome) =>
      guard(() async {
        final repo = await ref.read(fosterRepositoryProvider.future);
        return repo.recordFoster(lamb, outcome);   // T01's verb, unchanged
      });
}

// lib/routing/routes.dart — the twelfth helper, added by the epic that owns the screen (S2)
static Future<void> foster(BuildContext context, LambId id) =>
    Navigator.of(context).push(_route(
      RouteNames.foster,                       // 'foster' — declared in N13-T01
      (_) => FosterScreen(lambId: id),
    ));
```

The three widget keys this task introduces, spelled per `CONVENTIONS` §4.5
(`<screen>.<element>[.<qualifier>]`, every segment `lower_snake`) and recorded in `07-screens.md`
§8.5 in this commit, because **a key is a test contract and renaming one is a breaking change**
(R59):

| Key | What it is |
|---|---|
| `foster.target.<tag>` | one per deck tile — the doc-named key, from `12 §10.1` |
| `foster.target.bottle` | *"No ewe — bottle"* → `ToBottle()` |
| `foster.target.not_recorded` | *"No ewe — not recorded"* → `RemovedUnknown()` |

And the ARB messages, with the rule that catches everybody once — **no domain noun is ever a literal**
(10 §8.5), so *ewe* arrives as `{term}` from `terminologyProvider` and a shepherd who renamed her
sees *"No gimmer — bottle"*:

```json
"fosterNoEweBottle": "No {term} — bottle",
"@fosterNoEweBottle": {
  "description": "Foster screen, one of TWO no-ewe targets. Writes outcome to_bottle: null BY INTENT. It is not the same fact as 'not recorded' and the two are never merged (07 §8.4 rule 1). {term} is user-editable — never hard-code 'ewe'.",
  "placeholders": { "term": { "type": "String", "example": "gimmer" } }
},
"fosterBirthDamPermanent": "Fostering does not change the birth dam.",
"@fosterBirthDamPermanent": {
  "description": "Permanent 18 pt line on the Foster screen (07 §8.4 rule 2). States a structural guarantee, not a warning: no parameter of recordFoster can name a birth dam and a SQL trigger refuses it. Do not soften to 'usually'."
}
```

### 5.3 The details that are easy to get wrong

1. **The ruling, first, before any UI.** `quickEntryDeckProvider` is declared in
   `lib/features/quick_entry/quick_entry_controller.dart` (`CONVENTIONS` §3.2) and **layer rule 6
   (`layer.sibling`) forbids `lib/features/lambing/` from importing any other feature folder.** The
   gate fails the build before `analyze` sees it. R27 already ruled this exact shape, in these words:
   *"The Flock search box and the Foster screen both call it, and layer rule 6 forbids one feature
   importing another, so the feature-folder placement is not merely inconsistent — it is
   unbuildable."* Rule it the same way: the **declaration** moves to `lib/data/providers.dart`,
   beside `tagIndexProvider`, which is the existing app-level read provider with exactly this
   problem. Nothing else moves — the statement is already a repository method with its `readsFrom:`
   and its `.distinct()` (07 §5.2), the name does not change, the type does not change, and R28's
   one-statement-two-buckets rule is untouched. What you may **not** do is declare a second provider
   over the same statement: *"two queries for which ewes are available is two answers."*
2. **A feature may not import `lib/core/db/` or `package:drift` at all** (layer rule 5). If the move
   tempts you to put the statement in the screen, stop: the data layer is the only writer *and* the
   only place drift is spelled.
3. **The tap that opens this screen is not counted** (07 §1.3). The budget is **1 tap measured from
   the Foster screen's first painted frame**; the whole journey is 2 from the Lamb Card, 3 from the
   Pen Board and 4 from Quick Entry, and only the 1 is held by CI.
4. **There is no confirmation step and no dialog.** 07 §8.1: a confirm dialog would put the flow at
   three taps and a modal on a shed screen. The tile *is* the commit. `showDialog(` is allowlisted for
   exactly two destructive files and this is not one of them.
5. **Two no-ewe targets, never one.** `'to_bottle'` is null by intent and `'removed_unknown'` is null
   by omission; the rearing-credit numbers differ. A single "No ewe" target is the UI form of the
   banned `setRearingDam(lambId, eweId?)` signature.
6. **The lamb's current rearing dam is not excluded from the deck** (07 §8.2). Fostering onto her is a
   *warning* (T04), not an exclusion — a shepherd may be correcting an earlier mistaken foster.
7. **Create-on-the-fly crosses two repositories, and 07 §8.5's phrase "in the same transaction" is
   not implementable as written.** `createEwe` is `FlockRepository`'s and `recordFoster` is
   `FosterRepository`'s; each opens its own `_db.transaction()`, and drift gives you no way to share
   one across two concrete classes without inventing a thirteenth repository (R19 closes that set).
   Take the two-write shape: both calls inside **one** `guard()`, ewe first, foster second, and if
   the second fails the ewe still exists — which is a true record, not a draft, and exactly what
   spec §7.1's *"never block an entry to make the user go and set something up first"* asks for.
   Record the deviation against 07 §8.5 in the commit message per the amendment rule; do not quietly
   leave two documents describing a transaction that cannot exist.
8. **`EntryContext.liveEntry` on that create**, always. Decision #91: the live-entry path is
   structurally incapable of returning `BlockedByCap`. Over the cap the row is created and marked
   `over_free_cap`; nothing is said and nothing is shown.
9. **Nothing monetization-related renders here at any entitlement state or hour** — Foster is one of
   the five shed screens (06 §12, decision #90). No banner, no counter, no colour change.
10. **The receipt is the committed row** (P2 — there is no SnackBar, including in `feedback.dart`).
    Build a `SaveReceipt` whose `summary` names what changed (`'fostered to 305'`), because the live
    region only re-announces on a changed label and `at` is `HH:mm` — two writes inside one minute
    share it (10 §3.8). `undoLabel` is a **field**, not a constant: it becomes `'CORRECT THIS'` in
    T03. In this task pass `undo: null` and let T03 wire the action; do not ship an `'UNDO'` label
    that a later commit has to unsay.
11. **Two providers, but no displayed value computed from two drift streams.** The deck is the
    screen's one content statement; the two dams come from `lambCardProvider(lambId)`, a single-row
    lookup, which 07 §1.2 permits explicitly. `combineLatest` over drift streams is a build-breaking
    defect. `lamb_card_controller.dart` is in **this** feature folder, so reading it is not a
    sibling import.
12. **The birth dam is a cell with no target on it** (`indelible.md` §8 screen 6). Not a disabled
    control, not a control with a warning — no `ShedTapTarget` in that subtree at all. That is a
    stronger guarantee than any dialog, and it is what the semantics gate will read.
13. **Order the targets by the two neutral facts the deck already has** — longest penned, then most
    recently touched. 07 §8.6: *"no screen in the app is more tempting to make helpful."* No "has
    capacity", no "has milk", no reordering by anything a vet would recognise.
14. **`restoreFixture` and `kSeedLamb` do not exist yet.** `12 §10.1`'s published body of this very
    test calls both; the fixture is generated in N23-T04 and committed and switched to in N23-T05 (critique S3). Seed
    with `test/support/seeds.dart` helpers and use the ids they return.
15. **Back is a bottom-bar button, not only the AppBar chevron** (07 §20.2), and every target is
    ≥ 64 × 64 with the ruled separation, from `context.tokens` — a magic size is a build-breaking
    defect and `72 pt` typed as `72` is a magic size.
16. **One level-1 heading, no level-2** (10 §3.4). Foster is one task; heading stops would add
    navigation to a screen whose purpose is not having any. Use `headingLevel:`; `Semantics(header:
    true)` is a no-op since 3.44 and is banned in review.
17. **Tags are spelled out, and only the tag** (10 §3.3): `attributedLabel: spellOutTag('gimmer 412',
    '412')`, never `label:`. "Four one two" is what is printed on the tag; "four hundred and twelve"
    is a number that appears nowhere in the shed.

### 5.4 The full test set

| File | Cases |
|---|---|
| `test/features/tap_budget_test.dart` | **anchor:** `'foster reassignment from the Foster screen costs 1 tap'` — and the two neighbours stay green, because this file holds all three budgets |
| `test/features/foster_test.dart` | `'both dams render before and after the reassignment, and the birth dam carries no tap target'` · `'the penned targets come first, ordered longest penned, then the recents'` · `'the no-ewe bottle target writes to_bottle and the not-recorded target writes removed_unknown'` · `'a double-fired target commits exactly one foster event'` — `tester.tap(); tester.tap();` with no pump between them (decision #22); `guard()` is the defence · `'creating a ewe from the keypad commits the ewe and then the foster, and the ewe survives a failed foster'` · `'the cap never speaks: no monetization widget renders at unlocked false, 99 ewes, at 03:20 and at 14:00'` · `'the deck the Foster screen reads is quickEntryDeckProvider itself'` — override it once in the container and assert the tiles change · `'a read failure shows the standard panel and the two no-ewe targets keep working'` |
| `test/features/routing_test.dart` | `'Routes.foster pushes FosterScreen with RouteSettings(name: foster)'` — the route name is one of the few fields decision #124 permits in the diagnostics log |
| `test/features/foster_dst_test.dart` `@Tags(['uk-zone'])` | `'a foster committed at 01:30 in the repeated hour renders 01:30 with its provenance label'` — through `atFixed(DateTime(2026, 10, 25, 1, 30), …)`; the label is `RecordedTime.provenanceLabel`, an exhaustive switch that can never be empty · `'two fosters inside the repeated hour produce receipts whose labels differ'` — both read `01:30`, so uniqueness has to come from `summary`, which is the whole point of 10 §3.8 |

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **The amendment rule** — the provider ruling edits `CONVENTIONS` §3.2/§6, `02` §4 and `07` §5.2 **in this commit**. A ruling that lands in code and not in the naming authority is a ruling the next reader reverses.
- **Fostering is not a drag** (`indelible.md` §9): *"Fostering is two taps on a cell chooser, not a drag between ewes."* `Draggable` and `Dismissible` are `check_policy` rows.

## 7. Definition of Done

- [ ] `'foster reassignment from the Foster screen costs 1 tap'` passes, and was seen to fail first for the stated reason
- [ ] one tap, asserted on keyed finders
- [ ] the deck query is the same provider Quick Entry reads
- [ ] both dams are visible before and after
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `lib/features/lambing/` imports no other feature folder, proved by `layer.sibling` and not by inspection
- [ ] the three new widget keys and every new ARB message are recorded in `07-screens.md` §8.5 in this commit

## 8. Verification

```bash
fvm flutter test test/features/tap_budget_test.dart
fvm flutter test test/features/foster_test.dart test/features/routing_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
grep -rn "features/quick_entry" lib/features/lambing/
grep -rn "quickEntryDeckProvider" lib/ --include=*.dart
make check
make test
```

The first grep must print nothing — that is layer rule 6, read with your own eyes before the gate
reads it. The second must show **one** declaration, in `lib/data/providers.dart`, and only `ref.watch`
call sites elsewhere.

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(foster): one-tap reassignment over the Quick Entry deck`
