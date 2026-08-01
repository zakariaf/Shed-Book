# N26-T05 — `noteSearchProvider` — FTS5 with a 200 ms debounce

| | |
|---|---|
| **Epic** | [N26 — Flock and Note Search](epic.md) · `00-README` §9 step 10 (1 of 4) |
| **Task** | 5 of 7 |
| **Depends on** | N26-T04 |
| **Commit** | one commit · `feat(flock): noteSearchProvider over FTS5, debounced` |

## 1. Why this task exists

The thirteenth route: an `autoDispose` family over FTS5 with a 200 ms debounce. Type
`watery` and every note that ever said it comes back, offline, in under a second — against the 400-ewe
fixture, not against six rows.

**This is the first task in the project that puts a row in `search_docs` and reads it back.**
`00-README` §9 step 3 put FTS5 into the v1 schema *"with FTS5 present in v1 and zero real rows"* so
that `SchemaVerifier` met the shadow tables in week one. Nineteen epics later, this task is where the
index stops being a shape in a migration test and becomes a feature.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | **§9.2 — the whole section.** `search_docs`'s DDL · the `search_fts` virtual table (`content='search_docs'`, `content_rowid='id'`, `tokenize='porter unicode61 remove_diacritics 2'`, `prefix='2 3'`) · the three external-content sync triggers · the five source-table trigger trios and the `COALESCE` rule · **the `searchAll` query, printed** · **the two spelling traps** (the alias trap and `rank` versus `rank_score`) · the `recursive_triggers` consequence and the season-delete sweep · **the two week-one prototypes: drift#3322 and the FTS5 shadow tables** · why `watry` returns zero rows · §9.1 (**FTS5 is banned on the keypad path**) · §5.11 (`Notes` — `body`, `occurred_at`, the provenance quad) · §5.14 (nobody writes `search_docs`; SQL triggers do) | every line of the index and every trap in it |
| `docs/engineering/CONVENTIONS.md` | **§3.2** (`noteSearchProvider` — `StreamProvider.autoDispose.family<List<SearchHit>, String>` in `lib/features/flock/note_search_controller.dart`, **autoDispose — 200 ms debounce**) · §3.4 (`noteSearchControllerProvider`) · §3.5 (family arguments) · §1.1 layer rules 3, 5, 8 · §2.13/R19 (the repository set is closed at twelve) · §2.14 · §4.4 (controllers hold typed text in a private field) · R22 (the `.drift` files sit directly in `lib/core/db/`) | **BINDING** on the provider, its file, its type and its dispose policy |
| `docs/engineering/02-state-di-navigation.md` | **§10.3 rule 8** (*"Exactly two debounces exist in `lib/`: 200 ms on note search, 400 ms on free-text fields. A third is a defect"*) · §4.2 (auto-dispose policy; the family-argument rule) · §4.1 (`StreamProvider` over one drift `watch()`) · §4.5 (never a spinner) · §2.1–§2.3 (the Riverpod-3 ban list) · §7.1 rule 3 (the 400 ms ceiling and why it is not this one) | the provider shape and the debounce budget |
| `docs/engineering/07-screens.md` | **§18** (the two-surface split; *"FTS5 over the `search_docs` fan-in table, kept in sync by SQL triggers, **200 ms debounce**, `bm25()` ordering, `snippet()` for the excerpt"*; *"FTS5 availability is a **startup assertion**, not a runtime capability probe… There is no `LIKE` fallback branch to maintain"*) · §3.3 (*"Search notes (FTS5) \| 1 to open the search screen \| 200 ms debounce lives there, never here"*) | which mechanism, on which surface, with which debounce |
| `docs/engineering/12-testing.md` | **§2.2 (`fakeAsync`, and the trap decision #113 exists to close)** · §2.3 (the ambiguous hour) · §3.1–§3.2 (the drift harness; the host `sqlite3` floor and why `flutter test` needs `libsqlite3-dev`) · §5.2 (fixtures for shape at volume) · **§11.6 (banned in tests: `Future.delayed`, wall-clock assertions)** · §11.5 (`flock_400_3seasons.json` carries *"unicode notes"*) | how a 200 ms debounce is asserted without a wall clock |
| `docs/engineering/04-migrations-media-backup-restore.md` | the `search_docs` exclusion from the JSON backup and its repopulation on restore · `configureConnection`'s `recursive_triggers` | why the index is never in a backup |
| `docs/engineering/01-architecture.md` | §4 (the write path; a repository may not import `lib/domain/validation/`) · §5.3 (`_write()`) | where the read verb belongs |
| `docs/research/00-tech-decisions.md` | §5 only for versions — `sqlite3` **3.5.0** *"bundles SQLite via Dart build hooks; guarantees FTS5 + STRICT on every device"*; `drift` **2.34.2** with **open #3338** (torn `combineLatest`) and **#3295** (no `distinct()`) · #25/#26 (drift over `package:sqlite3`; no `sqlite3_flutter_libs`) · **#35/#36 (FTS5 for notes, in-memory ranking for tags, FTS5 as a startup assertion)** · #12 (drift `watch()`) · #71 (never a spinner) · #113 (`Clock.fixed` freezes time) | the decisions the index applies, and the exact package versions |
| `shed-book-spec.md` | **§7.7** (*"Full-text offline search across every note, tag, and treatment"*) | the claim, and the five subject kinds it implies |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-riverpod-providers` | the autoDispose family, the debounce and the disposal |
| `shed-drift-schema` | the FTS5 query and its `readsFrom:` |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/note_search_test.dart`
- **Test** — `'a 200 ms debounced query for watery returns every note that contains it'`
- **Why it is red today** — nothing searches notes, and FTS5 has sat empty since N07-T07.

```bash
fvm flutter test test/features/note_search_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it holds the debounce as well as the result. Restore
`flock_400_3seasons.json`, write three notes through `NoteRepository.addNote` whose bodies contain
*watery mouth* (which is `dc_watery_mouth`'s label — a phrase this flock actually uses), and, inside
`fakeAsync`, assert four things:

1. Typing `w`, `a`, `t`, `e`, `r`, `y` with 30 ms between keystrokes and then advancing 200 ms issues
   **exactly one** statement. Count it off `db.executedStatements`, not off a stopwatch.
2. The three notes come back and no fourth row does.
3. Advancing only 190 ms after the last keystroke issues **zero** statements. A debounce asserted only
   in the passing direction passes on no debounce at all.
4. **`FakeAsync.elapse` drives it, never `Future.delayed`.** `12 §11.6` bans `Future.delayed` in tests
   outright, and `12 §2.2` names the trap decision #113 exists to close: a timer created outside the
   `fakeAsync` zone never fires inside it, so the test hangs and then fails opaquely.

**Green.** The minimum code that passes, and nothing beyond it — the family, the debounce, and the query against the fixture.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Steps 1–3 are skipped and the commit message says so** — with one caveat at step 1 that is the whole
of this task's risk. `search.drift` already declares `search_docs`, `search_fts` and all eighteen
triggers (N07's search cluster). **This task adds no table and no column, so `drift_schemas/` must not
move.** If the ruling below sends a statement out of `search.drift`, `database.g.dart` moves with it
and that regeneration is in the same commit.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/core/db/search.drift` | **Edit, only if `searchAll` is not already declared.** `03 §9.2` prints it. R22 puts the `.drift` files directly in `lib/core/db/`, and layer rule 8 makes this the only place a `customStatement(` may live |
| 2 | `lib/data/note_repository.dart` | **Edit.** Add `SearchHit` and `Stream<List<SearchHit>> watchSearch(String query, {int limit})` — the FTS5 tokenising, the call to `searchAll`, and the mapping. It goes on `NoteRepository` and not on a thirteenth repository because R19 closes the set at twelve, and on `NoteRepository` rather than `FlockRepository` because `notes` is its table |
| 3 | `lib/data/fts_query.dart` | **New, or a private top-level function in `note_repository.dart`.** `String toMatchExpression(String raw)` — the tokeniser. Prefer the private function: `CONVENTIONS §4.1` bans `utils.dart`, and a one-function file in flat `lib/data/` (R18) needs a reason |
| 4 | `lib/features/flock/note_search_controller.dart` | **New.** `noteSearchProvider` (the `.autoDispose.family`) **and** `NoteSearchController` / `noteSearchControllerProvider` — the raw text in a private field, the `Timer`, and the settled query in `state`. `CONVENTIONS §3.2` and §3.4 name both and put them here |
| 5 | `lib/routing/routes.dart` | **Edit.** Add the `Routes.noteSearch` push helper. `RouteNames.noteSearch` already exists (N13-T01) |
| 6 | `docs/engineering/CONVENTIONS.md` §2.14 | **Edit.** Add the `SearchHit` row |
| 7 | `docs/engineering/03-data-model-and-schema.md` §9.2 **and** `docs/engineering/04-…md` | **Edit, if a fallback shipped.** §9.2's two week-one prototypes end *"record which one shipped, here and in doc 04"*. If drift's analyser refuses the special INSERTs, record Fallback A or B, in this commit |
| 8 | `test/support/seeds.dart` | **Edit.** Add `seedNote(db, {ewe, lamb, lambing, season, body, occurredAt})` — a thin wrapper over `NoteRepository.addNote`, so the trigger path is exercised rather than bypassed |
| 9 | `test/data/note_repository_test.dart` | **Edit.** The tokeniser, the query, the trigger propagation and the operator cases |
| 10 | `test/features/note_search_test.dart` | **New.** The anchor, the debounce cases and the disposal case |

### 5.2 The signatures

```dart
// lib/data/note_repository.dart

/// One FTS5 result row. 03 §9.2's `searchAll` column list, typed.
///
/// `subjectKind` is one of the five 03 §9.2 tabulates — 'ewe', 'lambing',
/// 'lamb', 'treatment', 'note' — and it is a STORED KEY, frozen forever
/// (CONVENTIONS §4.6). `subjectId` is a raw int here and is wrapped into the
/// right extension-type id by the ONE call site that navigates (T06); this is
/// the same allowance R33 makes for `WriteCommitted.insertedId`.
@immutable
final class SearchHit {
  const SearchHit({
    required this.subjectKind,
    required this.subjectId,
    required this.eweId,
    required this.title,
    required this.excerpt,
    required this.occurredAt,
    required this.rankScore,
  });

  final String subjectKind;
  final int subjectId;
  final EweId? eweId;      // search_docs.ewe_id — nullable; a season note has none
  final String title;      // NOT NULL in search_docs; a trigger COALESCEs it to ''
  final String excerpt;    // snippet(f, 1, '[', ']', '…', 12)
  final Instant occurredAt;
  final double rankScore;  // bm25(), NEGATIVE, smaller is better

  @override
  bool operator ==(Object other) => …;
  @override
  int get hashCode => …;
}
```

The tokeniser. `03 §9.2`: *"never build FTS5 syntax by string concatenation without tokenising first,
because a note containing the word `OR` is an FTS5 operator and throws a syntax error at 3am"*:

```dart
/// Turns raw user text into a safe FTS5 MATCH expression.
///
/// Every token is wrapped in DOUBLE QUOTES, which is FTS5's own string syntax
/// and neutralises OR, NOT, AND, NEAR, ^, * and (). An embedded double quote is
/// escaped by DOUBLING it — "" — which is SQL string escaping, not backslash
/// escaping; a backslash is a literal character to FTS5.
///
/// The LAST token gets a trailing `*`, outside its quotes, so a half-typed word
/// still matches. That is 03 §9.2's first stated mitigation for the fact that
/// FTS5 has no fuzzy matching and `spellfix1` is not in the bundled build:
/// `watry` returns zero rows and always will.
///
/// Returns null when the raw text tokenises to nothing — do NOT issue a MATCH
/// against an empty expression; FTS5 raises a syntax error for it.
String? toMatchExpression(String raw);
```

The read verb, wrapping `03 §9.2`'s `searchAll`:

```dart
  /// 03 §9.2's `searchAll`, from lib/core/db/search.drift. `bm25()` returns a
  /// NEGATIVE score where smaller is better, so ascending `ORDER BY rank_score`
  /// is correct. `title` is weighted 2.0 so a ewe's own records sit above a
  /// passing mention in someone else's note.
  ///
  /// `limit` is bounded because the UI is a list a thumb scrolls, not a report.
  Stream<List<SearchHit>> watchSearch(String query, {int limit = 50});
```

The provider and its controller. The debounce lives in the **controller**, and this is the point of the
task:

```dart
// lib/features/flock/note_search_controller.dart

/// CONVENTIONS §3.2: this file, this name, this type, autoDispose.
///
/// The family argument is the SETTLED query, never the raw text. A family
/// instantiates one provider per distinct argument, so keying it on every
/// keystroke would create six providers and six drift subscriptions for the
/// word "watery" — and a debounce INSIDE the provider would not help, because
/// it debounces the SQL and not the instantiation.
final noteSearchProvider =
    StreamProvider.autoDispose.family<List<SearchHit>, String>((ref, query) async* {
  if (query.isEmpty) {
    yield const [];
    return;
  }
  final repo = await ref.watch(noteRepositoryProvider.future);
  yield* repo.watchSearch(query);
});

/// The 200 ms debounce, and one of only TWO debounces permitted in lib/
/// (02 §10.3 rule 8; the other is the 400 ms free-text ceiling). A third is a
/// defect.
///
/// 02 §4.4 and CONVENTIONS §4.4 rule 4: "anything the user typed lives in a
/// private field on the notifier, not only in state."
final class NoteSearchController extends Notifier<String> {
  Timer? _debounce;
  String _raw = '';                    // what the thumb has typed, undebounced

  @override
  String build() {
    // 2.6.1 spelling. Without this the timer outlives the screen and fires into
    // a disposed notifier — which throws inside a zone nobody is watching.
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  void type(String raw) {
    _raw = raw;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () => state = _raw);
  }

  void clear() {
    _debounce?.cancel();
    _raw = '';
    state = '';
  }
}

final noteSearchControllerProvider =
    NotifierProvider.autoDispose<NoteSearchController, String>(
  NoteSearchController.new,
);
```

### 5.3 The details that are easy to get wrong

- **A trigger-written table is invisible to drift's stream invalidation, and this is the sharpest trap
  in the epic.** `03 §5.14`: nobody writes `search_docs` — *SQL triggers* do. drift re-runs a `watch()`
  when a write **it issued** touches a table in the query's dependency set; it never saw the trigger
  fire. So a search stream keyed on `search_fts`/`search_docs` can sit open while a note is added and
  never re-emit. **Assert it, do not assume it:** open the stream, `addNote`, expect a second emission.
  If that fails, the read moves to a `customSelect` whose `readsFrom:` names the five **source** tables
  — `notes`, `ewes`, `lambs`, `lambings`, `treatments` — because those are the writes drift *can* see.
  Write the outcome and the reason into the file.
- **Once the virtual table is aliased, only the alias is in scope.** `03 §9.2` spelling trap 1:
  `WHERE search_fts MATCH …`, `snippet(search_fts, …)` and `bm25(search_fts, …)` alongside
  `FROM search_fts f` all fail at **runtime** with *no such column: search_fts*. Use `f` in all three
  places, or drop the alias and use the table name in all three. **Never mix.**
- **`rank` is FTS5's own auto-generated column.** Spelling trap 2: `… AS rank` shadows it and
  `ORDER BY rank` becomes ambiguous to a reader. The result column is `rank_score` for that reason
  alone. Do not "tidy" it.
- **`bm25()` is negative and smaller is better.** Ascending `ORDER BY rank_score` is correct. Sorting
  descending puts the worst match first and looks plausible on three rows.
- **An empty MATCH expression is a syntax error, not an empty result.** Guard it in
  `toMatchExpression` and return null; the provider yields `const []`. This is also the *"no query
  yet"* state's data path (T06).
- **Quote every token; escape an embedded `"` by doubling it.** A note about a ewe *"marked OR"*, or a
  shepherd typing `NEAR`, `AND`, `*` or `^`, otherwise throws. Backslash escaping does nothing — FTS5
  reads a backslash as a literal character.
- **The trailing `*` goes outside the quotes.** `"water"*` is a prefix query; `"water*"` searches for a
  literal asterisk inside a phrase. The index declares `prefix='2 3'`, so 2- and 3-character prefixes
  are indexed and cheap; longer ones still work, just without the prefix index.
- **`watry` returns zero rows, and no amount of tokenising changes that.** `03 §9.2`: FTS5 has no fuzzy
  matching and `spellfix1` is not in the bundled build. The mitigations, **in the stated order**:
  prefix-match the last token (covers truncation — the common cold-fingers error), porter stemming
  (covers inflection, already in the tokenizer), and a bounded Dart-side pass over `search_docs.body`
  offering *"Did you mean…"* when FTS returns nothing. **Do not add a second trigram index for typos.**
- **No debounce, ever, on the keypad path.** `03 §9.1` and `02 §10.3` rule 8: *"Banned on the keypad
  path: FTS5, the trigram tokenizer, `LIKE`, and any debounce. The 200 ms debounce belongs to note
  search and nowhere else."* If this task's `Timer` pattern gets lifted into `flock_controller.dart`'s
  search box, T01's *"typing a query issues no additional statement"* test goes red — which is the
  point of it.
- **The family argument is a `String`, and that is legal.** `CONVENTIONS §3.5` bans a bare `int`, a
  `List` and a hand-written class without verified `==`; `String` has structural equality and is a
  correct cache key. What it does *not* excuse is keying it on undebounced text.
- **`ref.onDispose` cancels the timer, and Riverpod 2.6.1 makes you write it.** `02 §2` — there is no
  `ProviderContainer.test()` and no `WidgetTester.container`; those are Riverpod 3. A timer that
  outlives its notifier sets `state` on a disposed object.
- **`autoDispose` must actually dispose, and it is worth asserting.** The screen is pushed and popped;
  if anything keeps a listener — a stray `ref.listen` in a parent, a `ref.keepAlive()` someone reached
  for — the family accumulates one live drift subscription per query for the life of the app.
  `02 §4.2`: *"`ref.keepAlive()` is used nowhere. If you reach for it, you have put `.autoDispose` on a
  hub provider."*
- **`search_docs` is excluded from the JSON backup and repopulates itself.** `03 §9.2` and `04`. Do not
  add it to an export, do not seed it directly, and do not write a Dart-side *"also update the index"*
  call — that is the exact failure mode triggers were chosen to prevent: *"a restore bulk-inserts
  thousands of rows through whatever path is fastest, and that is precisely where a Dart-side call gets
  skipped and the user's five seasons come back unsearchable."*
- **Seed notes through `NoteRepository.addNote`, never with a direct insert.** The trigger trio is the
  thing under test. `03 §9.2`'s `COALESCE` rule is not optional — *"miss it once and creating a ewe with
  no notes aborts the insert with a `NOT NULL` failure, at 03:20, from a trigger nobody was looking
  at."*
- **FTS5 availability is a startup assertion, not a runtime probe.** `07 §18` and decision #36:
  `configureConnection` runs `_assertEngineCapabilities(db)` and fails loudly. **There is no `LIKE`
  fallback branch to maintain**, and adding one here is adding a second search implementation that
  nobody will ever test.
- **`flutter test` runs on the host, so the host must supply sqlite3.** `12 §3.2` and `13 §4.3`:
  `sqlite3_flutter_libs` is a plugin — and an EOL no-op shim anyway (decision-record §5.3) — so it is
  never applied in a host test. CI installs `libsqlite3-dev`. A developer whose FTS5 tests all fail to
  open a database should install it locally rather than mock the database (decision #111).
- **`Future.delayed` is banned in tests and `fakeAsync` is the replacement.** `12 §11.6` and §2.2.
  Create the timer **inside** the `fakeAsync` zone or it never fires; `12 §2.2` calls this out as the
  trap decision #113 exists to close.
- **Loading is not a spinner, here least of all.** Decision #71 and `ui.spinner`. Between the last
  keystroke and the result there is a debounce window, which is precisely when a developer reaches for
  a `CircularProgressIndicator`. The result box keeps its height and its content until the new result
  lands.

### 5.4 The full test set

| File | Case | What it asserts |
|---|---|---|
| features | `'a 200 ms debounced query for watery returns every note that contains it'` | **The anchor.** Six keystrokes 30 ms apart plus 200 ms inside `fakeAsync`: exactly **one** statement, the three seeded notes, no fourth row |
| features | `'190 ms after the last keystroke, no statement has been issued'` | The debounce in the failing direction. Without this, no debounce at all passes |
| features | `'each keystroke restarts the window rather than extending it'` | Ten keystrokes at 150 ms: still one statement, issued 200 ms after the last |
| features | `'clearing the field cancels the pending timer and issues nothing'` | `clear()` before the window closes; `db.executedStatements` unchanged |
| features | `'the provider disposes with its last listener'` | Push, type, pop. The family instance is gone and the container's listener count for it is zero. `ref.keepAlive` appears nowhere in the diff |
| features | `'no spinner renders during the debounce window'` | Decision #71, `ui.spinner`. `find.byType(CircularProgressIndicator)` is `findsNothing` at 100 ms |
| features | `'the query runs in under a second against the 400-ewe fixture'` | `restoreFixture`, then the elapsed **fakeAsync** budget — never a wall clock (`12 §11.6`) |
| data | `'toMatchExpression neutralises OR, AND, NOT and NEAR'` | Four queries that are bare FTS5 operators; each returns rows or none, and none throws |
| data | `'toMatchExpression neutralises a double quote, an asterisk and a caret'` | `"` doubled, not backslashed. `03 §9.2`'s stated failure mode is a syntax error *at 3am* |
| data | `'toMatchExpression returns null for whitespace and for punctuation only'` | An empty MATCH is a syntax error, not an empty result |
| data | `'the last token is prefix-matched and the earlier ones are not'` | `wat` matches *watery*; `watery mou` matches *watery mouth*; `wat mouth` does **not** match *watery mouth* |
| data | `'watry returns zero rows'` | `03 §9.2`, stated as a fact so nobody adds a trigram index to "fix" it |
| data | `'a diacritic in a note is found by its unaccented form'` | `remove_diacritics 2` in the tokenizer, against the fixture's unicode notes (`12 §11.5`) |
| data | `'porter stemming finds scoured from scouring'` | The tokenizer's second mitigation |
| data | `'results are ordered by ascending rank_score, and title outranks body'` | `bm25(f, 2.0, 1.0)` is negative and smaller is better. Two hits, one matching in `title` |
| data | `'the excerpt brackets the matched term'` | `snippet(f, 1, '[', ']', '…', 12)` — column 1 is `body` |
| data | `'the alias is used in MATCH, snippet and bm25, or in none of them'` | Source text over `search.drift`: `search_fts` and `f` never both appear as the function's first argument. Spelling trap 1, which fails at runtime |
| data | `'no result column is named rank'` | Spelling trap 2 |
| data | **`'adding a note through addNote makes the open search stream re-emit'`** | **The trigger-invalidation trap.** If this fails, the read moves to a `customSelect` naming the five source tables in `readsFrom:` — and the fix, with its reason, lands in this commit |
| data | `'a note added to a ewe with no other notes does not abort on NOT NULL'` | `03 §9.2`'s `COALESCE` rule, from the source-table trigger |
| data | `'a treatment, a lambing, a lamb and a ewe note are all searchable'` | Spec §7.7 says *"every note, tag, and treatment"*; the fan-in has five `subject_kind`s and all five must return hits |
| data | `'deleting a season leaves no orphan search_docs row'` | `03 §9.2`'s sweep. `SeasonRepository` runs `sweepSearchDocs` then `rebuildSearchIndex` inside the delete transaction; assert `search_docs` is empty and an `integrity-check` does not throw |
| data | `'search_docs appears in no backup'` | `03 §9.2` / `04`: excluded, and it repopulates itself |
| data · **`@Tags(['uk-zone'])`** | `'a note occurring at 01:30 on the clocks-back night is found once, not twice'` | `TZ=Europe/London`. `notes.occurred_at` is epoch millis and `search_docs.occurred_at` copies it; the repeated hour must not produce two index rows, and the hit's rendered date must be stable |

### 5.5 What this task deliberately does not build

- **The screen, the hit widget, the navigation and the three empty strings.** T06. This task ends with
  a provider and a repository verb, both green, and a test that pumps them without a `NoteSearchScreen`.
- **The *"Did you mean…"* pass.** `03 §9.2` lists it third among the fuzzy mitigations and it is not
  needed to make the anchor green. If it is built, it is a bounded Dart-side scan of
  `search_docs.body`, never a second index.
- **The `note_search` matrix variant.** T07.

## 6. Constraints that bind this task

- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Exactly two debounces exist in `lib/`** — 200 ms on note search, 400 ms on free-text fields
  (`02 §10.3` rule 8). *"A third is a defect."* Grep every `Duration(milliseconds:` near a `Timer`
  before committing.
- **Offline** — FTS5 is bundled by `package:sqlite3` **3.5.0** through Dart build hooks; nothing here
  reaches a network. G2 and G3 stay green and no dependency is added.
- **`customStatement(` outside `lib/core/db/` is a layer-8 violation.** The SQL lives in
  `search.drift` (R22); `customSelect` in `lib/data/` with an explicit `readsFrom:` is the one
  permitted alternative and is `00-README` §8 step 14's own wording.
- **The schema is frozen.** No table, no column, no second index. If `drift_schemas/` moves, stop.

## 7. Definition of Done

- [ ] `'a 200 ms debounced query for watery returns every note that contains it'` passes, and was seen to fail first for the stated reason
- [ ] debounced at 200 ms and proved
- [ ] the provider disposes with its last listener
- [ ] the query runs in under a second against the 400-ewe fixture
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the debounce is asserted in **both** directions — one statement after 200 ms, zero after 190 ms
- [ ] the family is keyed on the **settled** query, never on raw keystrokes
- [ ] `ref.onDispose` cancels the timer; `ref.keepAlive` appears nowhere
- [ ] `toMatchExpression` neutralises `OR`, `AND`, `NOT`, `NEAR`, `"`, `*`, `^` and `(`, and returns null for an empty tokenisation
- [ ] the last token is prefix-matched with the `*` **outside** the quotes
- [ ] the alias is used consistently in `MATCH`, `snippet` and `bm25`, and no result column is named `rank`
- [ ] **adding a note through `addNote` makes an open search stream re-emit** — or the read is a `customSelect` naming the five source tables in `readsFrom:`, with the reason written in the file
- [ ] no `LIKE` fallback branch and no second index exist anywhere
- [ ] no `Future.delayed` in any test in this diff; the debounce is driven by `fakeAsync`
- [ ] no spinner renders at any point in the debounce window
- [ ] exactly two `Timer`-backed debounces exist in `lib/`
- [ ] `SearchHit` has a row in `CONVENTIONS §2.14`, added in this commit
- [ ] if a `03 §9.2` fallback shipped, it is recorded in both `03` and `04` in this commit
- [ ] `drift_schemas/` is untouched; if `database.g.dart` moved, the regeneration is in this commit

## 8. Verification

```bash
fvm flutter test test/features/note_search_test.dart
make check
make test
```

```bash
fvm flutter test test/data/note_repository_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
fvm flutter test test/drift/                     # the FTS5 shadow tables still migrate
```

```bash
grep -rn "Duration(milliseconds:" lib/ | grep -i timer        # expect exactly two: 200 and 400
grep -rn "Future.delayed" test/                               # expect zero (12 §11.6)
grep -rn "ref.keepAlive" lib/                                 # expect zero (02 §4.2)
grep -rn "LIKE '%" lib/                                       # expect zero — no fallback branch
grep -rn "customStatement(" lib/ | grep -v "^lib/core/db/"    # expect zero (layer rule 8)
grep -n "AS rank\b" lib/core/db/search.drift                  # expect zero (spelling trap 2)
grep -rn "CircularProgressIndicator" lib/features/            # expect zero (ui.spinner)
git diff --name-only main -- drift_schemas/                   # expect empty
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(flock): noteSearchProvider over FTS5, debounced`
