# N13-T02 — `tagIndexProvider` — active animals only, ranked in memory

| | |
|---|---|
| **Epic** | [N13 — Quick Entry: the deck and the keypad](epic.md) · `00-README` §9 step 5 (1 of 2) |
| **Task** | 2 of 7 |
| **Depends on** | N13-T01 |
| **Commit** | one commit · `feat(quick_entry): tagIndexProvider over active animals, ranked in memory` |

## 1. Why this task exists

The in-memory tag index over **active animals only** — the owner's uniqueness ruling made
into a query — feeding `rankTagMatches` so that typing a digit reorders the list **in the same frame**,
with no SQL round trip. A database query per keystroke at 3am is a visible stutter.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/02-state-di-navigation.md` | §4.2 (hub reads are keepAlive) · §4.4 (`.select` and the stored-field rule) · §4.5 (the exhaustive `AsyncValue` switch) · §4.6 (where providers are declared) · **§10.1–§10.3** (the rebuild table, `QuickEntryController` printed in full, the nine rules and the debounce ban) | the provider shape, the controller, and what may not rebuild |
| `docs/engineering/03-data-model-and-schema.md` | §5.2 (`Ewes`: `tag`, `tagDigits`, `status`, `idx_ewe_tagdigits`, `idx_ewe_status`) · **§6** (tag uniqueness settled — the partial unique index and its four consequences) · **§9.1** (`rankTagMatches` printed in full; why FTS5, `LIKE` and any debounce are banned on this path) · `EweTouches` | the statement, the ranking and the index sizing |
| `docs/engineering/CONVENTIONS.md` | §2.14 (`TagIndexEntry`, `rankTagMatches`) · §3.1 + §3.2 (`tagIndexProvider` is in `lib/data/providers.dart`, keepAlive) · §3.4 (`quickEntryControllerProvider`) · §4.3 (the five documented provider-name exceptions include `tagIndexProvider`) · §4.4 (controllers hold typed state in a private field) · **R19** (twelve repositories, closed) · **R26** (`flockTagCacheProvider` is banned) · **R27** (`tag_match.dart`'s home) · R33 | **BINDING** on every name, file and signature |
| `docs/engineering/07-screens.md` | **§5.2** (the keypad is fed by `tagIndexProvider`, an app-level singleton, not a screen query; the 16 KB figure) · §5.3 (the `412 →` window and the one extra tap) · §1.2 (the one-query rule and what an app-level singleton is allowed to be) | why this is not the screen's content statement |
| `docs/research/00-tech-decisions.md` | #35 (in-memory ranking for tags; FTS5 for notes) · §7.0 **ruling 7** (tags unique among ACTIVE animals only) · §5 for versions | the ruling this task turns into a `WHERE` clause |
| `shed-book-spec.md` | §7.1 (partial tag matching: typing `12` surfaces 412, 128, 12; create-on-the-fly) | the behaviour being held |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-riverpod-providers` | the index's scope, its invalidation and the same-frame requirement |
| `shed-drift-schema` | the watched statement, `.distinct()` and the two indexes it must use |

*(`shed-screens-and-routing` is deliberately **not** loaded here: `07 §5.2` is explicit that the tag
index is an app-level singleton and **not** a screen query, so the one-drift-statement-per-screen skill
owns the deck in T03, not this file.)*

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/quick_entry_test.dart`
- **Test** — `'typing 12 reorders the match list in the same frame with no database read'`
- **Why it is red today** — nothing indexes tags, so the keypad would query per keystroke.

```bash
fvm flutter test test/features/quick_entry_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion into two halves that fail independently:

1. **Same frame.** Seed `412`, `128`, `12`; let the index resolve; then call
   `appendDigit('1')`, `appendDigit('2')` and read `state.matches` **without** an intervening
   `await tester.pump()`. The order must already be `12`, `128`, `412` — exact, then prefix, then
   suffix, then infix (`03 §9.1`). If the implementation is asynchronous, `matches` is still the old
   list at the moment of the read and the case fails on the order, which is the right failure.
2. **No database read.** Count statements. Wrap the connection with a counting
   `QueryExecutor`/`QueryInterceptor` installed by the test, snapshot the count after the index
   resolves, perform both keystrokes, and assert the delta is **exactly zero**. Counting is what makes
   the claim mechanical: a `LIKE '%12%'` implementation passes half of the case (the order is right)
   and fails this half, which is precisely the implementation `03 §9.1` rules out.

**Green.** The minimum code that passes, and nothing beyond it — one statement building the index, held in memory, ranked by N06-T07's pure function.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**No schema and no domain** — `ewes` and `ewe_touches` were frozen in N07 and `rankTagMatches` /
`TagIndexEntry` were built in **N06-T07**. This task is data (step 3, read side), wiring (step 4) and
controller (step 5). Say so in the commit message: nothing is stored by this commit.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/flock_repository.dart` | **New file, read verbs only.** `final class FlockRepository` taking `AppDatabase`, with `Stream<List<TagIndexEntry>> watchTagIndex()`. `CONVENTIONS` §2.13 gives this repository `ewes` and `ewe_touches`, and R19 closes the set at twelve — **do not create a `QuickEntryRepository` or a `TagRepository`**. Its first *write* verb, `createEwe`, is N14-T01; a repository with no write verb yet is fine and the header comment should say which task adds it |
| 2 | `lib/data/providers.dart` | **Edit.** Add `flockRepositoryProvider` (`FutureProvider<FlockRepository>`, keepAlive, derived from `databaseProvider`) if N12-T01 did not already declare it, and `tagIndexProvider` (`StreamProvider<List<TagIndexEntry>>`, keepAlive) |
| 3 | `lib/features/quick_entry/quick_entry_controller.dart` | **New.** `QuickEntryState`, `QuickEntryController`, `quickEntryControllerProvider`. `02 §10.2` prints all three; type them as printed |
| 4 | `test/support/seeds.dart` | **Edit.** Extend `seedEwe` (N12-T05) so a test can seed a tag, a `tag_digits` projection, a `status` and an optional `ewe_touches` row in one call. Every later screen epic uses it |
| 5 | `test/features/quick_entry_test.dart` | **New.** The anchor plus the cases in §5.4. T03, T05 and T06 add to this same file |

`lib/l10n/app_en.arb` is **not** touched: this task renders nothing. T04 authors the first keypad
string and T05 the first screen strings.

### 5.2 The signatures

`TagIndexEntry` and `rankTagMatches` already exist — do **not** redeclare them, and do not write a
second ranking. `CONVENTIONS` §2.14:

```dart
// lib/domain/tag_match.dart — N06-T07. Shown for reference only.
// TagIndexEntry: {EweId eweId, String tag, String digits, Instant? lastTouched}
List<TagIndexEntry> rankTagMatches(List<TagIndexEntry> all, String query);
```

The read verb, on the repository, because `lib/features/` may not import `package:drift` (layer rule 5)
and `lib/data/` is the only layer that may:

```dart
// lib/data/flock_repository.dart
/// Reads only, today. `createEwe` — the one verb the free-tier cap can refuse —
/// is N14-T01 and lands on this same class with `EntryContext` in its signature
/// from its first commit (critique S5). R19: the repository set is twelve and
/// closed; there is no QuickEntryRepository.
final class FlockRepository {
  FlockRepository(this._db);
  final AppDatabase _db;

  /// The whole active flock's tags, held in memory and ranked in Dart.
  /// ~400 entries × ~40 bytes ≈ 16 KB (03 §9.1). ACTIVE animals only —
  /// decision-record §7.0 ruling 7.
  Stream<List<TagIndexEntry>> watchTagIndex() { /* §5.3 */ }
}
```

The two providers, spelled exactly as `CONVENTIONS` §3.1/§3.2 spell them. `tagIndexProvider` is one of
the five documented exceptions to the `<typeNameLowerCamel>Provider` rule (§4.3), so the name is
`tagIndexProvider` and not `tagIndexEntriesProvider`:

```dart
// lib/data/providers.dart
final tagIndexProvider = StreamProvider<List<TagIndexEntry>>((ref) async* {
  final repo = await ref.watch(flockRepositoryProvider.future);
  yield* repo.watchTagIndex();
});
```

The controller, from `02 §10.2`. Two things make it correct rather than merely fast — the filter runs
**once per keystroke in the controller**, and the query lives in a **private field** so a `build()`
re-run cannot wipe it:

```dart
// lib/features/quick_entry/quick_entry_controller.dart
@immutable
final class QuickEntryState {
  const QuickEntryState._({
    required this.query,
    required this.index,
    required this.matches,
    required this.selected,
  });

  factory QuickEntryState({
    String query = '',
    List<TagIndexEntry> index = const [],
    EweId? selected,
  }) =>
      QuickEntryState._(
        query: query,
        index: index,
        selected: selected,
        // Stored, not a getter. Computed once per state transition.
        matches: rankTagMatches(index, query),   // pure, lib/domain/tag_match.dart
      );

  final String query;
  final List<TagIndexEntry> index;
  final List<TagIndexEntry> matches;
  final EweId? selected;
}

final class QuickEntryController extends Notifier<QuickEntryState> {
  // NOT in `state`. The notifier instance is preserved across `build()` re-runs;
  // `state` is not. Without this field, a flock change while the shepherd is
  // mid-tag wipes the digits they just typed.
  String _query = '';
  EweId? _selected;

  @override
  QuickEntryState build() {
    final index = switch (ref.watch(tagIndexProvider)) {
      AsyncData(:final value) => value,
      _ => const <TagIndexEntry>[],
    };
    return QuickEntryState(query: _query, index: index, selected: _selected);
  }

  void appendDigit(String digit) { … }
  void backspace() { … }
  void clearSelection() { … }
}

final quickEntryControllerProvider =
    NotifierProvider<QuickEntryController, QuickEntryState>(
  QuickEntryController.new,     // keepAlive: this is the hub screen
);
```

The statement itself is one `select` over `ewes` left-joined to `ewe_touches`, filtered to
`status = 'active'`, mapped to `TagIndexEntry`, `.distinct()` in the repository:

```sql
SELECT e.id, e.tag, e.tag_digits, t.touched_at
  FROM ewes e
  LEFT JOIN ewe_touches t ON t.ewe = e.id
 WHERE e.status = 'active';
```

### 5.3 The details that are easy to get wrong

- **`flockTagCacheProvider` is a banned spelling** (R26). `07` uses it in two places and lost: *"'cache'
  names the implementation while 'index' names the value."* The name is `tagIndexProvider`, in
  `lib/data/providers.dart`, `StreamProvider<List<TagIndexEntry>>`, **keepAlive**.
- **`keepAlive`, not `autoDispose`, and the reason is 3am.** `02 §4.2`: hub reads are re-entered
  constantly through a night, and *"disposing and re-querying on every pop is exactly the wrong trade
  at 3am."* An `autoDispose` index means the `412 →` window (`07 §5.3`) re-opens every time the
  shepherd pops back from a screen.
- **ACTIVE animals only, and that is not a filter for tidiness.** Decision-record §7.0 ruling 7 makes
  tags unique among active animals, held by the partial index
  `CREATE UNIQUE INDEX idx_ewe_tag_active ON ewes (tag) WHERE status = 'active'`. Follow it through
  (`03 §6`, `02 §10.2`):
  1. the index and the create-on-the-fly match are the **same** active-only set, so typing `412` can
     never surface two live candidates and never needs a disambiguation dialog at 03:20;
  2. a culled `412` is **absent** — correct, and not silent: her record surfaces later, in daylight, on
     the new 412's ewe card via `earlierAnimalsWithTag` (N27's);
  3. the index is rebuilt by drift's `watch()` when an animal is culled or created. **Nothing in the
     controller invalidates it** — `ref.invalidate` on a drift-backed provider is a defect (`02 §4.2`),
     and the one legitimate invalidate in the whole codebase is `minuteTickProvider` on resume.
- **`tag_digits` ranks; `tag` decides identity.** `03 §6` rule 1: uniqueness is on `tag` **as typed**,
  never on `tag_digits`, because a unique `tag_digits` would refuse `0412` while `412` exists — the app
  deciding two tags are the same animal. `rankTagMatches` strips non-digits from the *query*
  (`query.replaceAll(RegExp(r'\D'), '')`) and compares against `e.digits`. Never normalise the stored
  tag, and never render `tag_digits`: it is a projection and is never shown.
- **A `TagIndexEntry` whose `digits` is empty must still be in the index.** `ewes.tag_digits` is
  `withLength(min: 0, …)`, so a tag like `RED` projects to `''`. `rankTagMatches` returns `const []`
  for an empty *query*, but an entry with empty digits simply never scores — it is unreachable by
  keypad, which is correct, and it must not crash `score()` or be filtered out of the index (the Flock
  screen's search box reuses the same index at N26 and does show it).
- **No debounce, anywhere on this path.** `02 §10.3` rule 8: *"debouncing a sub-millisecond operation
  is cargo cult, and it puts a visible lag between the thumb and the digit."* The two debounces in the
  app are 200 ms on full-text note search (its own screen) and 400 ms on free-text fields. A third is a
  defect.
- **No FTS5, no trigram tokenizer, no `LIKE` on this path** (`03 §9.1`). FTS5's trigram tokenizer
  documents that *"substrings consisting of fewer than 3 unicode characters do not match any rows"* —
  and the spec's own example is the two-character `12`. `LIKE '%12%'` works and cannot use an index.
  Both are banned by name.
- **Do not quote a latency number.** `02 §10.1` and `03 §9.1` are careful here: a substring scan over
  400 short strings is *sub-millisecond*, and that is the claim decision #35 rests on. The sharper
  figures that circulate (~40 µs) are desktop estimates and **nothing in the doc set depends on them**.
  Do not put one in a comment; decision #126 says the only numbers that count come from profile mode on
  two real devices with the 400-ewe fixture.
- **`matches` is a stored field, never a getter.** `02 §4.4` prints the banned form and says why: a
  getter that allocates a new `List` runs the filter once per equality check *and* once per build,
  which is strictly worse than no `.select` at all. The CI heuristic in `02 §2.4` catches the common
  spelling; the general case is a review item, so make it obvious.
- **And be honest about what `.select((s) => s.matches)` buys.** A stored `List` field still has
  identity `==`, so it deduplicates **nothing** — `_MatchList` rebuilds on every notifier emission,
  which for this screen is once per keystroke and is exactly right. What the stored field removes is
  the *recomputation*. Never reach for `listEquals` to close the gap: over 400 rows it costs more than
  the rebuild it prevents.
- **`_query` lives on the notifier, not in `state`.** The notifier instance survives `build()` re-runs;
  `state` does not. Without the private field, a flock change (another ewe created, one culled) while
  the shepherd is mid-tag wipes the digits they just typed. This is `CONVENTIONS` §4.4 rule 4 —
  *"anything the user typed lives in a private field on the notifier"* — and it is the single most
  load-bearing line in the controller.
- **The `AsyncValue` arm for "not resolved yet" is an empty list, not a throw and not a spinner.**
  `02 §4.5`: the only permitted form is an exhaustive `switch`, no accessors. `AsyncValue.valueOrNull`
  is on the Riverpod-3 ban list (`00-tech-decisions` §5.1) and does not exist to you. While the index
  is unresolved the confirm key reads `412 →` and makes **no existence claim** (`07 §5.3`) — that is
  T04/T05's rendering, but the empty-list arm here is what makes it possible.
- **`lib/features/` may not import `package:drift`.** The statement is on the repository; the controller
  watches a provider. If you find yourself writing `db.select(db.ewes)` in
  `quick_entry_controller.dart`, the `layer.features` gate row will fail — but only after the layout
  already depends on it, which is the expensive time to find out.
- **`FlockRepository` may not import `lib/domain/validation/`** (layer rule 3, `layer.data_no_validation`,
  R53). It is a §12.4 structural mechanism, not an oversight: a repository is made *incapable* of
  producing or persisting a warning.

### 5.4 The full test set

`test/features/quick_entry_test.dart` for the controller and the provider; `test/data/` for the
statement against `NativeDatabase.memory()`, never a mock (decision #111).

| Case | File | What it asserts |
|---|---|---|
| `'typing 12 reorders the match list in the same frame with no database read'` | features | **The anchor.** Order `12`, `128`, `412` synchronously; statement delta exactly zero across both keystrokes |
| `'rankTagMatches is called, not a second implementation'` | features | Source text over `lib/features/` and `lib/data/`: zero occurrences of `startsWith(`, `endsWith(`, `contains(` on a tag, and one import of `lib/domain/tag_match.dart` |
| `'the index excludes culled, sold and dead animals'` | data | Seed one ewe per `status` value from `03 §5.2`'s CHECK (`active`, `sold`, `dead`, `culled`); assert the stream yields exactly the active one |
| `'culling an animal removes her from the index without any invalidate'` | data | Update `status` to `culled` in a transaction; the same subscription re-emits. Proves `watch()` tracking, and that no `ref.invalidate` is needed |
| `'creating an active animal adds her to the index'` | data | The other direction, same subscription |
| `'a tag with no digits is in the index and is unreachable by keypad'` | data + features | `tag: 'RED'`, `tag_digits: ''`. Present in the index; `rankTagMatches` never returns it for any numeric query |
| `'0412 and 412 are two entries and neither is normalised'` | data | The typed value round-trips verbatim (`03 §6` rule 1) |
| `'the index yields an empty list before the database opens, and the controller does not throw'` | features | The `AsyncLoading` arm. This is the `412 →` window (`07 §5.3`) |
| `'backspace on an empty query is a no-op and does not emit'` | features | Guards a rebuild storm on a cold thumb |
| `'a flock change mid-tag does not wipe the typed digits'` | features | Type `41`, insert a new ewe, let the index re-emit, assert `state.query == '41'`. **The private-field case** — the one that fails if `_query` moves into `state` |
| `'matches is a stored field, not a getter'` | features | Source text over `quick_entry_controller.dart`. `02 §4.4`'s banned form, named |
| `'ties break by most-recently-touched, then by shorter tag'` | features | Two entries with the same score: one with `lastTouched` set, one null; then two with neither. `03 §9.1`'s comparator, exactly |
| `'there is no debounce on this path'` | features | Source text: no `Timer(`, no `Future.delayed` and no `debounce` in `quick_entry_controller.dart` |
| `'FTS5, MATCH and LIKE appear nowhere in the tag path'` | data | Source text over `flock_repository.dart` |
| `'lastTouched ordering is stable across the ambiguous DST hour'` · **`@Tags(['uk-zone'])`** | data | `TZ=Europe/London`. Two ewes touched at **01:30 BST** and **01:30 GMT** — the same wall-clock time, an hour apart in physical time. `ewe_touches.touched_at` is epoch millis through `InstantConverter`, so the later-in-real-time ewe must rank first. An implementation that ever formats or parses a local wall time on this path inverts the order here, and nowhere else |

The DST case is the only time-shaped assertion in this task. It is worth having even though the index
never *displays* a time: `lastTouched` is a sort key, and a sort key derived from a wall clock is a
bug that only shows up for one hour a year.

## 6. Constraints that bind this task

- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **This task renders nothing**, so the ARB row binds it negatively: if a string appears in this diff,
  it is in the wrong commit. `tag` is the word (never *ear tag*, *number* or *ID*), and *the deck* is
  the collective noun for the two strips — never *picker* or *chooser*.
- **Same frame or it does not ship.** The structural rule, not a performance target: the filter runs in
  Dart on the UI isolate, with no `await` between a digit and a redraw. A drift round trip through the
  background isolate lands one or two frames late.
- **Nothing here watches `entitlementProvider`** (decision #90). The index does not know what a cap is.

## 7. Definition of Done

- [ ] `'typing 12 reorders the match list in the same frame with no database read'` passes, and was seen to fail first for the stated reason
- [ ] active animals only
- [ ] no database read on a keystroke — asserted by counting statements
- [ ] the ranking is `rankTagMatches`, not a second implementation
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `tagIndexProvider` is `StreamProvider<List<TagIndexEntry>>`, keepAlive, declared in `lib/data/providers.dart`
- [ ] `flockTagCacheProvider` appears nowhere (R26)
- [ ] `_query` is a private field on the notifier and a flock change mid-tag does not wipe it
- [ ] `matches` is a stored field computed in the factory, never a getter
- [ ] no `Timer`, no `Future.delayed`, no debounce, no `FTS5`, no `MATCH` and no `LIKE` on this path
- [ ] `ref.invalidate(tagIndexProvider)` appears nowhere
- [ ] `lib/features/quick_entry/` imports no `package:drift` and no `lib/core/db/`
- [ ] `FlockRepository` is one of `CONVENTIONS` §2.13's twelve; no new repository class was created (R19)
- [ ] the `uk-zone` `lastTouched` case exists and fails when the `TZ=Europe/London` leg is removed

## 8. Verification

```bash
fvm flutter test test/features/quick_entry_test.dart
fvm flutter test test/data/flock_repository_test.dart
make check
make test
```

```bash
TZ=Europe/London fvm flutter test --tags uk-zone
```

```bash
grep -rn "flockTagCacheProvider\|tagIndexEntriesProvider" lib/ test/       # expect zero
grep -rn "package:drift" lib/features/                                     # expect zero
grep -rn "ref.invalidate" lib/features/quick_entry/                        # expect zero
grep -rn "debounce\|Future.delayed\|Timer(" lib/features/quick_entry/      # expect zero
grep -rn "MATCH\|LIKE\|fts" lib/data/flock_repository.dart                 # expect zero
grep -n "get matches" lib/features/quick_entry/quick_entry_controller.dart # expect zero
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(quick_entry): tagIndexProvider over active animals, ranked in memory`
