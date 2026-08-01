# N26-T06 — `SearchHit` rendering, navigation, and the three distinct empty strings

| | |
|---|---|
| **Epic** | [N26 — Flock and Note Search](epic.md) · `00-README` §9 step 10 (1 of 4) |
| **Task** | 6 of 7 |
| **Depends on** | N26-T05 |
| **Commit** | one commit · `feat(flock): search hit rendering, navigation and three empty states` |

## 1. Why this task exists

A hit renders with enough context to be recognisable and navigates to **the record the
note belongs to**. Three distinct empty strings — three different facts, three different things to do
about them, and `07 §2.2` says out loud why they are not one: *"a shepherd who sees the wrong one
concludes the app lost their notes."*

> **Correction carried into this task.** The backlog described the third condition as *"query too
> short"*. There is no length threshold on this screen. `07 §2.2` and `07 §18` agree on the three, and
> they are: **no query yet** → *"Type to search notes."* · **no notes exist at all** → *"No notes
> recorded yet."* · **query with no match** → *"No notes match 'watery'."*, with a `Clear` action on the
> third only. The length problem belongs to the **keypad** path, where FTS5 is banned outright and
> `rankTagMatches` handles two-character queries (`03 §9.1`, decision #35). Note the correction in the
> commit message.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§18** (the note-search screen's states, verbatim: *"Frame 1 → the search field, already focused and typeable, over an empty result box (the same rule as the keypad: the input works before the data does)"*; *"loaded → results showing the note, its animal and its date with provenance"*; *"over-cap → nothing, ever"*; the three actions: type, open a result, clear) · **§2.2** (the empty-state table's note-search row — the three strings) · §1.4 (the state vocabulary) · §1.5 (the §12 disclosure matrix) · §19.2 (the seven screens with no cap surface) | every state, every string and what the screen may never render |
| `docs/engineering/03-data-model-and-schema.md` | **§9.2** (the five `subject_kind`s and what `title`/`body` hold for each; `snippet(f, 1, '[', ']', '…', 12)`) · §5.11 (`Notes` — `body`, `occurred_at` **distinct from `created_at`**, the provenance quad; the `>= 1` subject CHECK) · §4.1 (instants as epoch millis) | what a hit is *about*, and which record owns it |
| `docs/engineering/CONVENTIONS.md` | §2.2 (`RecordedTime`, `provenanceLabel`, `TimeSource`) · §2.14 (`RouteNames`, `Routes`) · §3.2 (`noteSearchProvider`) · §3.4 (`noteSearchControllerProvider`) · §4.5 (widget keys) · §5.4 (**copy conventions: no all-numeric human date; every displayed event time carries its provenance label**) · **R33** (ids cross boundaries; `int` does not) · **R60** (`d MMM y`) | the names, the keys and the date format |
| `docs/engineering/05-domain-correctness.md` | `RecordedTime.provenanceLabel` — an exhaustive switch that can never be empty (decision #53): *recorded automatically* / *time entered by you* / *time edited by you* | the label that must accompany every event time |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.2 (the eight label rules) · **§3.3 (`spellOutTag`)** · **§3.4 (note search carries a `headingLevel: 1` and **no** level 2 — *"each is one task, and heading stops would add navigation to screens whose entire purpose is not having any"*; and the level-1 title exists *"because §7.3's gate asserts at least one `headingLevel > 0` node on **all fourteen** variants"*)** · §3.8 (live regions) · §8.4 (ARB conventions; the `description` carries the rationale) · §8.5 (the terminology-placeholder rule) · **§9.1–§9.2 (one formatting authority; never render an all-numeric date to a human)** | what the screen says rather than shows |
| `docs/design/indelible.md` | §7.3 (the 64 px ruled record row: margin cell 0–68, spine at x=68, record column 76–377) · §7.12 (the text field: **no placeholder, ever**; Focused is a 2 px `--ink-full` rule and a caret, *"no glow, no fill, no colour change"*) · §7.13 (the word button — `CLEAR`) · §7.16 (the 44 px page header, always printing what the book is filtered to) · §2.7 (`AUTO` and `†edited` stamps; `— NOT RECORDED` over a dotted rule) · §7.7 (boxed = the animal, unboxed = the writing — a provenance stamp is **unboxed**) | the hit row's geometry and the provenance stamp's form |
| `docs/engineering/06-design-system.md` | §6.1 (`tapMin` 60, `gapMin` 16) · §12 (`ShedEmptyState` *"occupies the same box the populated content will"*; `ShedAnimalRow`) · §5.1 (the type scale; the 18 px floor) | the shared components and the floor |
| `docs/engineering/02-state-di-navigation.md` | §8.1 (the push helpers, and `RouteSettings(name:)`'s two reasons) · §8.2 (the stack, three pushes deep at most) · §4.5 (the exhaustive `AsyncValue` switch; **never a spinner**) · §4.3 (`ref.listen` in `build`, unconditionally) | how a hit reaches its record, and what it may not do |
| `docs/engineering/12-testing.md` | §5.1 (`pumpApp`, `locale: en_GB`) · §6.1 variant 13 (*"Note search — a real route, not a spec §9 screen. It is pumped like any other"*) · §7.4 (the house semantics rule) | what T07 will pump, and the locale the dates render in |
| `docs/research/00-tech-decisions.md` | §5 only for versions · #35 (two problems, two surfaces) · #53 (`RecordedTime` provenance) · #71 (never a spinner; the empty state is the teaching surface) · #90 (nothing monetization-related on the shed path) · #108 (no all-numeric human date) · §7.0 ruling 3 (en_GB, 24-hour, ambiguous hour **01:00–01:59**) | the decisions the screen applies |
| `shed-book-spec.md` | §7.7 · §5 (no onboarding after first run — *"the empty states are the teaching surface"*) | why three strings and not one |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `indelible-states-and-feedback` | the three empty states and their wording |
| `shed-screens-and-routing` | navigation from a hit to its record |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/note_search_test.dart`
- **Test** — `'each of the three empty conditions renders its own string and a hit navigates to its record'`
- **Why it is red today** — hits render as bare text and go nowhere.

```bash
fvm flutter test test/features/note_search_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so the three strings cannot collapse into one and the navigation cannot be
faked. Assert four things:

1. Each of the three conditions renders **its own** ARB key, read from `AppLocalizations` and never
   typed as a literal into the test, and each of the other two is absent. The three conditions:
   an empty query against a populated database; any query against a database with **zero** notes; and
   a query with no match against a populated one.
2. The `Clear` action is present on the **third** only. `07 §2.2` puts it there and nowhere else — a
   *Clear* offered when the field is already empty is a control that does nothing.
3. Tapping a hit whose `subject_kind` is `lambing` pushes a route whose `RouteSettings.name` is
   `RouteNames.lambingEntry`, carrying a **`LambingId`**, not an `int` (R33). Read the pushed route off
   a `NavigatorObserver`; asserting only that *some* route was pushed passes on a push to the wrong one.
4. Tapping a hit whose `subject_kind` is `ewe` pushes **nothing** and says so in the row. `EweCardScreen`
   and `Routes.eweCard` are **N27-T01's**; a hit that silently does nothing is worse than one that
   states its own limit.

**Green.** The minimum code that passes, and nothing beyond it — the hit widget, the navigation, and three ARB strings with descriptions.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Steps 1–5 are skipped and the commit message says so.** The provider, the repository verb and the
tokeniser all landed in T05; this task is UI, routing, the ARB and tests.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/features/flock/note_search_screen.dart` | **New.** `NoteSearchScreen` — the 44 px header, the already-focused field, the result box, and the three-way empty branch. The `headingLevel: 1` title lives here |
| 2 | `lib/features/flock/widgets/search_hit_row.dart` | **New.** `SearchHitRow` — the 64 px ruled row: the excerpt with its bracketed match, the animal, and the date with its provenance stamp |
| 3 | `lib/features/flock/note_search_controller.dart` | **Edit.** Add the `NoteSearchEmptiness` discriminator so the screen branches on a **named state**, not on three nested `isEmpty` checks (see §5.2) |
| 4 | `lib/routing/routes.dart` | **Edit.** Nothing new — `Routes.noteSearch` landed in T05, and the four destination helpers (`lambingEntry`, `lambCard`, `treatments`, and later `eweCard`) belong to their own epics. Confirm the file is unchanged and say so in the commit message |
| 5 | `lib/l10n/app_en.arb` | **Edit.** The three empty strings, the `Clear` label, the screen title, the field label, the hit's `semanticLabel` frame and the *"opens with the ewe card"* line for the deferred `ewe` kind — each with a `description` that states the fact it carries **and the fact it must not be confused with** |
| 6 | `test/features/note_search_test.dart` | **Edit.** The anchor and the per-state cases in §5.4 |
| 7 | `test/support/seeds.dart` | **Edit, if needed.** A `seedTreatmentNote` convenience so the five `subject_kind`s are all reachable from one file without a bespoke loader |

### 5.2 The signatures

Branch on a **named** state, not on three nested emptiness checks — the whole defect this task exists
to prevent is two of the three conditions sharing a string:

```dart
// lib/features/flock/note_search_controller.dart

/// 07 §2.2 and §18. THREE facts, three strings, and the discriminator is a
/// sealed type so a fourth condition cannot be added without editing every
/// switch. `noQuery` is not "no results"; `noNotesAtAll` is not "no match".
sealed class NoteSearchEmptiness { const NoteSearchEmptiness(); }

/// The field is empty. "Type to search notes."   — no action.
final class NoQuery       extends NoteSearchEmptiness { const NoQuery(); }

/// The database holds zero notes.  "No notes recorded yet."  — no action.
final class NoNotesAtAll  extends NoteSearchEmptiness { const NoNotesAtAll(); }

/// A query returned nothing. "No notes match '{query}'."     — "Clear".
final class NoMatch       extends NoteSearchEmptiness {
  const NoMatch(this.query);
  final String query;
}
```

The hit row. `07 §18`: *"results showing the note, its animal and its date with provenance"*:

```dart
// lib/features/flock/widgets/search_hit_row.dart
/// Indelible §7.3's ruled record row, 64 px: margin cell 0–68 (the date and its
/// provenance stamp), spine at x=68, record column 76–377 (the excerpt), the
/// animal's tag right-aligned.
///
/// The excerpt arrives from `snippet(f, 1, '[', ']', '…', 12)` with the matched
/// term bracketed. Render the brackets as a WEIGHT change, not as literal `[`
/// and `]` — but never as a colour change alone (decision #106).
class SearchHitRow extends StatelessWidget {
  const SearchHitRow({
    super.key,
    required this.hit,
    required this.onOpen,   // null when the destination screen does not exist yet
  });

  final SearchHit hit;
  final VoidCallback? onOpen;
}
```

Navigation, keyed on the `subject_kind` the fan-in table stores:

```dart
/// 03 §9.2 tabulates five subject kinds. Four have a screen today; the fifth
/// does not, and this switch says so rather than pretending.
///
/// The switch is exhaustive over the five STORED KEYS, with a `default:` that
/// THROWS rather than falls through — search_docs.subject_kind is written by
/// triggers, so a sixth kind means a schema change nobody told this file about.
///
/// R33: the id crosses the boundary as an extension type, never as a bare int.
/// SearchHit.subjectId is the raw int, and this is its ONE wrapping site.
VoidCallback? openerFor(BuildContext context, SearchHit hit) => switch (hit.subjectKind) {
      'lambing'   => () => Routes.lambingEntry(context, LambingId(hit.subjectId)),
      'lamb'      => () => Routes.lambCard(context, LambId(hit.subjectId)),
      'treatment' => () => Routes.treatments(context),
      // A note's owner is one of ewe / lamb / lambing / season (03 §5.11's
      // `>= 1` CHECK). Route to the most specific one the row carries.
      'note'      => _openerForNote(context, hit),
      // N27-T01 lands Routes.eweCard and EweCardScreen. Until then the row
      // renders and states its own limit; it does not silently do nothing.
      'ewe'       => null,
      _ => throw StateError('unknown search_docs.subject_kind: ${hit.subjectKind}'),
    };
```

The date, with its provenance, which is `CONVENTIONS §5.4`'s hardest rule to remember:

```dart
/// CONVENTIONS §5.4: "Every displayed event time carries its provenance label.
/// A bare 03:21 is a review failure." And R60: "Dates a human reads are never
/// all-numeric" — `d MMM y`, `11 Mar 2026`.
///
/// The label comes from RecordedTime.provenanceLabel, an exhaustive switch that
/// can never be empty (decision #53): "recorded automatically" / "time entered
/// by you" / "time edited by you". Indelible §7.7 makes it an UNBOXED stamp —
/// it is a note about the writing, not a state of the animal.
///
/// The formatting happens in lib/core/ui/formatters.dart, the ONLY package:intl
/// call site in lib/ outside lib/data/ (10 §9.1). Not here, and not in the ARB:
/// 10 §8.4 rule 4 bans DateTime placeholders in messages — "pass a
/// pre-formatted String. One formatting authority, not two."
```

### 5.3 The details that are easy to get wrong

- **The three strings are three because two of them are alarming and one is not.** `07 §2.2`: *"'No
  notes recorded yet' and 'no notes match this' are different facts, and a shepherd who sees the wrong
  one concludes the app lost their notes."* This is why the discriminator is a sealed type rather than
  `if (results.isEmpty)`: the naive branch cannot tell an empty corpus from an empty result and will
  show the alarming string to a shepherd whose five seasons are fine.
- **`NoNotesAtAll` needs a *second* fact the search result does not carry.** An FTS5 query returning
  zero rows is `NoMatch` **or** `NoNotesAtAll`, and the query cannot tell you which. The screen needs a
  cheap `SELECT EXISTS (SELECT 1 FROM search_docs)` — one boolean, watched, not a second full query.
  Add it as a named `.drift` query beside `searchAll`, or as a second tiny `customSelect`; either way it
  is **not** a second search.
- **Frame 1 is the field, focused and typeable, over an empty result box.** `07 §18`, and it is *"the
  same rule as the keypad: the input works before the data does."* So the field's `autofocus` is true
  and its focus does not wait on `databaseProvider`. Loading is never a spinner (decision #71,
  `ui.spinner`).
- **There is never placeholder text inside the field.** Indelible §7.12: *"In the dark, a grey
  placeholder is indistinguishable from an entered value."* The hint lives in the **label**, above the
  line, in the control voice. And `NoQuery`'s string — *"Type to search notes."* — lives in the result
  box, not in the field.
- **Focused is a rule and a caret, not a glow.** Indelible §7.12: *"Rule goes 2 px solid `--ink-full`;
  2 px `--ink-full` caret. No glow, no fill, no colour change."*
- **A hit navigates to the owning record, never to a list.** The `treatment` kind is the awkward one:
  `RouteNames` has `treatments` (the screen) and no per-treatment route, so the honest opener pushes the
  Treatments screen. If that reads as "a list", the fix is a scroll-to or a filter argument on the
  Treatments route — **not** a fourteenth `RouteNames` entry, which would break `02 §8.1`'s checkable
  arithmetic (*"`RouteNames` constants minus one must equal `Routes` push methods"*).
- **A note's owner is one of four, and the CHECK is `>= 1`, not `= 1`.** `03 §5.11`: a note may name a
  ewe **and** a lambing at once. Route to the most specific one present — lamb, then lambing, then ewe,
  then season — and write the precedence down, because the order is a product decision and not an
  implementation detail.
- **`search_docs.ewe_id` is nullable.** A season-scoped note has no ewe, so the row's "animal" column
  is empty and must render Indelible §2.7's `— NOT RECORDED` treatment — *"a visible gap, never a hidden
  field"* — rather than collapsing the column and shifting every other row's geometry.
- **The `ewe` kind has no destination until N27, and the row must say so.** A `ShedTapTarget` with a
  null `onTap` announces as a disabled button; Indelible §7.13 says disabled is *"avoided. Where
  genuinely impossible, `--ink-low` with a dotted underline and a printed reason beside it."* Print the
  reason. Name N27-T01 in the code comment, not in the user-facing string.
- **`SearchHit.subjectId` is a raw `int` and this file is its one wrapping site.** R33 — *"a bare `int`
  never crosses a repository, controller, route-helper or provider-family boundary"* — with the same
  allowance `WriteCommitted.insertedId` gets. Wrap once, at the opener.
- **The `subject_kind` switch throws on an unknown key rather than falling through.** The column is
  written by triggers, so a sixth kind means the schema changed and nobody told this file. A silent
  `default: null` renders an inert row and nobody finds out.
- **Every displayed event time carries its provenance label.** `CONVENTIONS §5.4` and `07 §1.5`'s
  §12.5 column. `03 §5.11` makes `notes.occurred_at` deliberately distinct from the mixin's
  `created_at` — *"a note typed at 06:00 about 03:20 has two different instants and the timeline sorts
  on the first."* The hit renders `occurred_at`, with its label. A bare date is a review failure.
- **`d MMM y`, never `11/03/2026`.** R60 and decision #108. Numeric dates exist only inside CSV, beside
  an ISO-8601 column. `pumpApp` pins `locale: const Locale('en', 'GB')` for exactly this
  (`12 §5.1`: *"A harness that inherits the runner's locale produces `3/28/2026` on a US CI runner and
  passes"*).
- **Formatting happens in `lib/core/ui/formatters.dart` and nowhere else.** `10 §9.1`, and `10 §8.4`
  rule 4 bans `DateTime` placeholders in ARB messages: *"pass a pre-formatted `String`. One formatting
  authority, not two."*
- **`headingLevel: 1` and no level 2.** `10 §3.4`: note search is one task, and *"heading stops would
  add navigation to screens whose entire purpose is not having any."* The level-1 title is not optional
  either — §7.3's gate asserts at least one `headingLevel > 0` node on **all fourteen** variants.
- **Over-cap renders nothing, ever.** `07 §18` says it in those words, and §19.2 lists the two surfaces
  that exist: Flock and Settings. Nothing here watches `entitlementProvider` (decision #90).
- **The excerpt's brackets are a weight change, not a colour.** `snippet()` returns `[` and `]` around
  the match; rendering them literally is ugly and rendering them as colour alone breaks decision #106.
  Weight is capped at w700 (`06 §5.3`), which is enough.
- **`ref.listen` for navigation, registered unconditionally at the top of `build`.** `02 §4.3`: it
  *"never appears inside an `if`"*, and navigation is a side effect, not a build-time decision.

### 5.4 The full test set

| Case | What it asserts |
|---|---|
| `'each of the three empty conditions renders its own string and a hit navigates to its record'` | **The anchor.** Three conditions, three ARB keys read from `AppLocalizations`, the other two absent in each; `Clear` on the third only; a `lambing` hit pushes `RouteNames.lambingEntry` with a `LambingId`; an `ewe` hit pushes nothing and prints a reason |
| `'an empty corpus and an empty result set render different strings'` | The sharpest half. Zero notes versus 400 ewes' notes with a nonsense query — the two must not share a key |
| `'the no-match string names the query the shepherd typed'` | `07 §2.2`: *"No notes match 'watery'."* The query is a placeholder, not a concatenation (`10 §8.4`) |
| `'Clear returns the screen to the no-query state and cancels the pending timer'` | Round-trip; `db.executedStatements` unchanged after `Clear` (T05's `clear()`) |
| `'frame 1 renders a focused, typeable field over an empty result box'` | `07 §18`. The field has focus before `databaseProvider` completes; no spinner anywhere |
| `'the field renders no placeholder'` | Indelible §7.12. `decoration.hintText` is null; the hint is in the label |
| `'a hit renders the excerpt, the animal and the date with its provenance label'` | `07 §18` and `CONVENTIONS §5.4`. All three present; the label is one of `RecordedTime.provenanceLabel`'s three |
| `'a hit whose note was time-edited renders the edited label, not the auto one'` | Decision #53. `seedEditedLambing`-shaped: `time_source = 'edited'`, `original_effective` non-null |
| `'a hit renders d MMM y and never an all-numeric date'` | R60. The rendered text matches `\d{1,2} [A-Z][a-z]{2} \d{4}` and matches no `\d{2}/\d{2}/\d{4}` |
| `'a season-scoped note with no ewe renders the not-recorded treatment, not a collapsed column'` | `search_docs.ewe_id` is nullable; Indelible §2.7's *"a visible gap, never a hidden field"*. Assert the row's `Rect` is unchanged |
| `'each of the five subject kinds renders a hit'` | `03 §9.2`'s table. Five seeded rows, five hits |
| `'a lamb hit pushes lamb_card with a LambId'` | R33, through a `NavigatorObserver` |
| `'a treatment hit pushes treatments'` | The one kind with no per-record route; assert the route **name**, not just that a push happened |
| `'a note owned by both a ewe and a lambing routes to the lambing'` | The `>= 1` CHECK and the stated precedence: lamb → lambing → ewe → season |
| `'an unknown subject_kind throws rather than rendering an inert row'` | Insert a `search_docs` row with a sixth kind directly and expect a `StateError` |
| `'the screen carries exactly one headingLevel 1 node and no headingLevel 2'` | `10 §3.4`; `Semantics(header: true)` appears nowhere |
| `'the tag in a hit's semantic label is spelled out and the term is not'` | `10 §3.3`, through `attributedLabel:` |
| `'nothing monetization-related renders at any entitlement state or hour'` | `07 §18` (*"over-cap → nothing, ever"*) and decision #90. Both entitlement states × 11:00 and 23:00; `FakePurchaseService.calls` empty |
| `'every hit row and the Clear action meet the 60 pt floor'` | `06 §6.1`, on the laid-out `Rect`s at `Device.small` |
| `'the empty state occupies the same box the results will'` | Decision #71, `06 §12`. `Rect` equality across all three empty states and the populated box |
| **`@Tags(['uk-zone'])`** `'a note occurring at 01:30 on the clocks-back night renders one date, once'` | `TZ=Europe/London`, `withClock` at **01:30**, rendered twice across the repeated hour. `occurred_at` is epoch millis; `LocalDate.of` must give the same civil date both times, and the rendered string must be byte-identical |
| **`@Tags(['uk-zone'])`** `'a note whose original_effective and effective straddle the spring-forward gap renders the edited label and both times'` | Indelible §2.7's *Edited timestamp* row: `†edited — event 03:20 as entered`, the second time on a second line. The gap is where a naive `DateTime` round-trip loses an hour |

### 5.5 What this task deliberately does not build

- **`Routes.eweCard` and `EweCardScreen`.** N27-T01. The `ewe` kind's opener is null here and the row
  prints its reason.
- **A per-treatment route.** `RouteNames` has thirteen entries and `02 §8.1`'s arithmetic depends on
  it. If a treatment hit needs to land on a row rather than a screen, that is an argument on the
  existing `Routes.treatments`, not a fourteenth name.
- **The `note_search` matrix variant.** T07.
- **The *"Did you mean…"* suggestion.** `03 §9.2`'s third fuzzy mitigation, and it is optional.

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 60 × 60 pt with ≥ 16 pt separation (`06 §6.1`; Indelible builds to 64 × 64), 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **The empty states are the teaching surface** — spec §5 bans onboarding after first run and
  decision #71 makes the empty state carry the teaching. Each of the three says what is true and what
  to do about it, in one line, at the same control the populated screen uses.
- **Every displayed event time carries its provenance label** (`CONVENTIONS §5.4`, decision #53). A
  bare date on a hit row is a review stop.

## 7. Definition of Done

- [ ] `'each of the three empty conditions renders its own string and a hit navigates to its record'` passes, and was seen to fail first for the stated reason
- [ ] three distinct strings, all in the ARB
- [ ] a hit navigates to the owning record, not to a list
- [ ] the hit shows enough surrounding text to be recognised
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the commit message notes the *"query too short"* → *"no query yet"* correction, citing `07 §2.2` and `07 §18`
- [ ] the three conditions are discriminated by a **sealed type**, not by nested `isEmpty` checks
- [ ] an empty corpus and an empty result set never share a string, and `NoNotesAtAll` is decided by its own cheap existence read
- [ ] `Clear` is present on the no-match state only
- [ ] the field is focused and typeable at frame 1, and renders no placeholder
- [ ] every hit renders its date as `d MMM y` **with** a `RecordedTime.provenanceLabel`
- [ ] all five `subject_kind`s render; the `ewe` kind prints its own limit and names N27-T01 in a code comment
- [ ] an unknown `subject_kind` throws rather than rendering an inert row
- [ ] ids cross the boundary as extension types; `SearchHit.subjectId` is wrapped at exactly one site (R33)
- [ ] `RouteNames` still has thirteen entries; no fourteenth was added
- [ ] the screen carries a `headingLevel: 1` and no `headingLevel: 2`
- [ ] nothing monetization-related renders at any entitlement state or hour, and `FakePurchaseService.calls` stays empty
- [ ] no spinner renders in any state

## 8. Verification

```bash
fvm flutter test test/features/note_search_test.dart
make check
make test
```

```bash
TZ=Europe/London fvm flutter test --tags uk-zone
fvm flutter test test/features/note_search_test.dart --plain-name 'three empty conditions'
```

```bash
grep -rn "hintText" lib/features/flock/                       # expect zero (Indelible §7.12)
grep -rn "CircularProgressIndicator" lib/features/            # expect zero (ui.spinner)
grep -rn "header: true" lib/                                  # expect zero (a11y.header_bool)
grep -rEn "[0-9]{2}/[0-9]{2}/[0-9]{4}" lib/l10n/app_en.arb    # expect zero (R60)
grep -rn "DateFormat\|package:intl" lib/features/             # expect zero (10 §9.1)
grep -c "static const" lib/routing/routes.dart                # RouteNames still 13 (02 §8.1)
grep -rn "entitlementProvider\|purchaseServiceProvider" lib/features/flock/note_search_screen.dart
                                                              # expect zero (decision #90)
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(flock): search hit rendering, navigation and three empty states`
