# N27-T02 — The one-line summary, assembled in Dart from counts

| | |
|---|---|
| **Epic** | [N27 — Ewe Card](epic.md) · `00-README` §9 step 10 (2 of 4) |
| **Task** | 2 of 7 |
| **Depends on** | N27-T01 |
| **Commit** | one commit · `feat(ewe_card): the one-line summary, assembled from counts` |

## 1. Why this task exists

*"3 seasons · avg 2.0 · assisted twice · prolapsed 2025."* Assembled **in Dart from `ewe_summaries`
counts**, never read as a string frozen in the database — because a frozen string is wrong the moment
terminology changes, units change, the locale changes, or a record is corrected.

This is the line spec §7.7 says must be *"visible before anything else"* and `00-README` §9 calls the
retention feature. It is also the one place in the app where four clauses of arithmetic sit one
character away from becoming veterinary advice, so §12.2's origination line binds every word of it.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/03-data-model-and-schema.md` | **§5.13 (`EweSummaries` — all eight columns, the `@DataClassName('EweSummary')`, the `lastObservationSeason` FK and its doc comment, and the paragraph "stores counts only — never a percentage, never a formatted string")** · §5.1 (`Seasons.year`, `.label`) · §10.1 (the six `ewe_observation` keys) | every count the line is made of, and the rule that the line is not stored |
| `docs/engineering/07-screens.md` | §4.1 (the header is *"a single-row watch of `ewe_summaries`"* — the summary must never wait for an aggregate; the sentence is assembled in Dart) · §4.2 (Frame 1 is a placeholder **at the summary line's exact height**) · §1.2 (what a screen may watch besides its content statement) · §3.1–§3.2 (the Flock row reads the same counts and renders them at 18 pt) | where the counts come from and what the header may watch |
| `docs/engineering/05-domain-correctness.md` | §6.5 (average litter size — `lambsBorn ÷ ewesLambed`, **not configurable**, zero-lamb lambings excluded from both sides with coverage reported) · §6.7 (assisted rate — ease ≥ 2, both sides exclude unscored lambings, coverage always reported, `notComputable` not `0%`) · **§7.3 (the origination line, and the legitimate-copy test that already contains `'412 · 3 seasons · avg 2.0 · assisted twice'`)** · §8 (terminology, `TermLabel`) | the arithmetic of two clauses, and the safety rule that bounds all four |
| `docs/engineering/10-accessibility-and-i18n.md` | **§8.5 (the terminology-placeholder rule — `{singularTerm}` / `{pluralTerm}`, never `{singular}` / `{plural}`; never derive a plural by appending "s")** · §8.4 rule 4 (dates and times are never formatted inside a message — pass a pre-formatted `String`) · §9.2 (`lib/core/ui/formatters.dart` is the one formatting authority) · §5 (never ellipsise a user's own words; the card's own text wraps) | every ARB message this task authors |
| `docs/design/indelible.md` | **§8 screen 2** (the summary printed *first, above everything, on its own 64 px row in the record face at 20 px*) · **§7.4** (the *Flock* row's summary is **three** clauses) · §3.4 (the type scale) · §3.5 (tabular numerals) | what the line looks like, and why the card and the flock row differ |
| `docs/engineering/CONVENTIONS.md` | §2.8 (`EweSummary` is a re-exported row class — `lib/features/` reaches it through `lib/data/models.dart`, never `lib/core/db/`), §2.13 (`FlockRepository`), §3.1 (`terminologyProvider`, `unitsProvider`, `settingsProvider` — the app-level singletons), §3.2 (`eweTimelineProvider`), §4.5 (widget keys), §5.1 (*record*, *season*, *barren*, *stillborn*), §5.4 (dates a human reads are never all-numeric), R20, R29, R61, R68 | **BINDING** on the row class, the providers and every word |
| `docs/engineering/12-testing.md` | §5.1 (`pumpApp` sets `locale: const Locale('en','GB')`), §6.1 (`ewe_card` is variant 2), §8.2 + §8's note (**`ewe_card_summary_line` is deliberately *not* a golden** — it is covered by the matrix plus the a11y gates) | how the line is asserted, and the test it must not become |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-domain` | the summary's arithmetic and its caveats |
| `shed-accessibility-and-copy` | the line's wording, its terminology placeholders and its reading order |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/ewe_card_test.dart`
- **Test** — `'the summary line is assembled in Dart from ewe_summaries counts, not read as a stored string'`
- **Why it is red today** — nothing summarises a ewe, and this line is the reason the product exists in year two.

```bash
fvm flutter test test/features/ewe_card_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it cannot pass by storing the string. Seed one `ewe_summaries` row with
`seasonsRecorded: 3, lambingsRecorded: 3, lambsBorn: 6, assistedLambings: 2, scoredLambings: 3` and one
`obs_prolapse` observation in the 2025 season. Assert **three** things:

1. the rendered line reads `3 seasons · avg 2.0 · assisted twice · prolapsed 2025`;
2. after `terminologyProvider` is overridden so a ewe is a *gimmer*, the **same seeded row** renders
   the gimmer wording without a database write — which a stored string structurally cannot do;
3. `grep`-equivalent: the generated `database.g.dart` has no text column on `EweSummaries`
   (`findColumn(schema, table: 'ewe_summaries', column: 'line')` from `test/support/reads.dart`
   returns null), so nobody added one to make case 1 easy.

**Green.** The minimum code that passes, and nothing beyond it — the assembly from counts, with terminology placeholders fed by `terminologyProvider`.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Step 3 (one read method), step 6 (the widget), step 6 item 22 (the ARB) and step 7 (tests).** No
schema, no domain file, no new provider in `lib/data/providers.dart` — the counts already exist and
the arithmetic is four divisions over ints that arrive in one row. Say the skipped layers in the
commit message.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/flock_repository.dart` | **Edit.** `watchEweSummary(EweId)` → `Stream<EweSummary?>`. A **single-row lookup**, which 07 §1.2 permits alongside the content statement. `null` is a real state: a ewe with no lambings has no `ewe_summaries` row until T03 writes one |
| 2 | `lib/features/flock/ewe_card_controller.dart` | **Edit.** `eweSummaryProvider` (`StreamProvider.autoDispose.family<EweSummary?, EweId>`) and `EweSummaryFacts` + `eweSummaryFacts(...)` — the pure arithmetic, in one place, so the widget only formats |
| 3 | `lib/features/flock/widgets/ewe_summary_line.dart` | **New.** `EweSummaryLine extends ConsumerWidget` — reads the facts, the terminology and the localisations, emits one 64 px row at the record scale. Key `ewe_card.summary` |
| 4 | `lib/features/flock/ewe_card_screen.dart` | **Edit.** The summary row goes first, above the timeline, at a fixed height so Frame 1 does not shift |
| 5 | `lib/l10n/app_en.arb` | **Edit.** Five messages plus the four clause fragments, each with a `description`, each date and count pre-formatted or an ICU plural. No domain noun is a literal |
| 6 | `test/support/seeds.dart` | **Edit.** `seedEweSummary(db, ewe: …, seasons: …, lambings: …, lambsBorn: …, assisted: …, scored: …, lastObservationSeason: …)` |
| 7 | `test/features/ewe_card_test.dart` | **Edit.** The anchor plus §5.4's cases |

### 5.2 The signatures

The arithmetic is separated from the wording deliberately: the facts are testable without a widget
tree, and the wording is testable without arithmetic.

```dart
// lib/features/flock/ewe_card_controller.dart

/// The four clauses, as numbers. Nothing here formats and nothing here reads a
/// clock, a locale or a Terminology — that is the widget's half.
@immutable
final class EweSummaryFacts {
  const EweSummaryFacts({
    required this.seasonsRecorded,
    required this.lambingsRecorded,
    required this.assistedLambings,
    required this.scoredLambings,
    this.averageLitterSize,          // null ⇒ notComputable, never 0.0
    this.lastObservationKind,        // a vocab_terms key, e.g. 'obs_prolapse'
    this.lastObservationYear,
  });

  final int seasonsRecorded;
  final int lambingsRecorded;
  final int assistedLambings;
  final int scoredLambings;
  final double? averageLitterSize;
  final String? lastObservationKind;
  final int? lastObservationYear;

  /// 05 §6.7: coverage is ALWAYS reported when it is partial.
  bool get assistedCoverageIsPartial => scoredLambings < lambingsRecorded;
}

/// The one place the arithmetic lives. `newestObservation` comes from the
/// timeline this screen is already watching — see §5.3 item 3.
EweSummaryFacts eweSummaryFacts(
  EweSummary? summary, {
  ({String kind, int year})? newestObservation,
});
```

```dart
// lib/data/flock_repository.dart
/// A single-row lookup (07 §1.2), not a second content statement. Returns null
/// until the ewe has something to summarise; T03 is what writes the row.
Stream<EweSummary?> watchEweSummary(EweId ewe) =>
    (_db.select(_db.eweSummaries)..where((t) => t.ewe.equals(ewe.value)))
        .watchSingleOrNull();
```

```json
// lib/l10n/app_en.arb — the frame is the ARB's, the nouns are the overlay's (10 §8.5)
"eweCardSummarySeasons": "{count, plural, =0{No seasons recorded} =1{1 season} other{{count} seasons}}",
"@eweCardSummarySeasons": {
  "description": "Clause 1 of the ewe card summary line (spec §7.7). A count of seasons in which this animal has a recorded lambing. Never a judgement.",
  "placeholders": { "count": { "type": "num" } }
},

"eweCardSummaryAverage": "avg {average}",
"@eweCardSummaryAverage": {
  "description": "Clause 2. Average litter size for THIS animal: lambs born divided by her recorded lambings (05 §6.5). {average} arrives pre-formatted to one decimal by lib/core/ui/formatters.dart — never formatted inside this message (10 §8.4 rule 4). Omitted entirely when not computable; never rendered as 0.0.",
  "placeholders": { "average": { "type": "String", "example": "2.0" } }
},

"eweCardSummaryAssisted": "{count, plural, =0{never assisted} =1{assisted once} =2{assisted twice} other{assisted {count} times}}",
"@eweCardSummaryAssisted": {
  "description": "Clause 3. Lambings with a recorded ease of 2 or more (05 §6.7). Unscored lambings are excluded from both sides and are named by eweCardSummaryAssistedCoverage; a blank ease is NEVER read as unassisted.",
  "placeholders": { "count": { "type": "num" } }
},

"eweCardSummaryAssistedCoverage": "of {scored} scored",
"@eweCardSummaryAssistedCoverage": {
  "description": "Appended to clause 3 only when some lambings have no ease score. 05 §6.7: coverage is always reported.",
  "placeholders": { "scored": { "type": "num" } }
},

"eweCardSummaryObservation": "{observation} {year}",
"@eweCardSummaryObservation": {
  "description": "Clause 4. The most recent recorded observation and the year of the season it was recorded in — e.g. 'prolapsed 2025'. {observation} is the USER-EDITABLE vocab_terms label for an ewe_observation key; never hard-code it and never translate it. The app records what the shepherd observed and never infers it (03 §5.7, safety rule 2).",
  "placeholders": {
    "observation": { "type": "String", "example": "prolapsed" },
    "year": { "type": "String", "example": "2025" }
  }
},

"eweCardTitle": "{singularTerm} {tag}",
"@eweCardTitle": {
  "description": "The card's headingLevel: 1 title. {singularTerm} is a USER-EDITABLE noun from the terminology overlay (ewe/gimmer/theave/…). See 05-domain-correctness.md §8 and 10 §8.5.",
  "placeholders": {
    "singularTerm": { "type": "String", "example": "ewe" },
    "tag": { "type": "String", "example": "412" }
  }
}
```

### 5.3 The details that are easy to get wrong

1. **The obvious performance fix is the defect.** `UPDATE ewe_summaries SET line = …` at write time
   makes the header instant and is exactly what 03 §5.13 forbids: *"stores counts only — never a
   percentage, never a formatted string"*, because a stored string freezes the terminology, the
   locale and the units at write time and is wrong the moment a record is corrected. The `codegen`
   job fails on the new column; the anchor's case 3 fails before that.
2. **`avg` is over `lambingsRecorded`, not `seasonsRecorded`.** 05 §6.5 fixes litter size as
   `lambsBorn ÷ ewesLambed`, aggregated by **birth dam** — for one animal, her lambs born divided by
   her recorded lambings. A ewe with three recorded seasons and two lambings has an average over 2,
   not 3; dividing by seasons deflates it and there is no note on the card saying so.
3. **The *"prolapsed 2025"* clause has no column behind it, and adding one is a migration.**
   `ewe_summaries` stores `last_observation_season` — a **season FK**, not a kind. The kind comes from
   the newest `TimelineKind.observed` row in the timeline this screen is **already watching** (T01) —
   no second statement, no new column, no violation of the one-query rule. Two consequences to state
   in the commit message rather than discover later:
   - the **Flock row** has only `s.last_observation_season` from `flockListQuery`, so it honestly
     renders **three** clauses — which is exactly what Indelible §7.4 draws;
   - the **card** has the timeline, so it renders **four** — which is exactly what Indelible §8
     screen 2 draws. The two artefacts were never in conflict; the column set explains why.
4. **`ewe_summaries` has no row until something writes one.** `watchSingleOrNull` returns `null` for a
   ewe created ten seconds ago, and `EweSummaryFacts` must render *"No seasons recorded"* rather than
   throwing or rendering an empty row that shifts the layout. T03 is what starts writing rows; until
   then every card in the suite exercises the null path, which is the right way round.
5. **`assisted twice` is a plural category, not a hard-coded word.** `=1` / `=2` are explicit ICU
   cases because *"assisted 2 times"* is not English and *"assisted twice"* is what the spec prints.
   And when `scoredLambings < lambingsRecorded` the coverage fragment is **appended, not omitted** —
   05 §6.7's rule is absolute: unscored lambings leave both sides and the coverage is always reported.
   Reading a blank ease as *unassisted* deflates the number and is the silent inference §12.4 forbids.
6. **Zero is not "not computable".** 05 §6.5 and §6.7 both say `notComputable`, **not** `0`. A ewe with
   one lambing and no lambs recorded yet (common and transient — the row is created on screen entry,
   decision #11) has *no* average, and rendering `avg 0.0` is the app asserting something false about a
   live animal. Drop the clause; do not print a zero.
7. **Never derive a plural by appending "s"** (10 §8.5). The shepherd typed one word; guessing the
   other is safety rule 4. Both forms come from `TermLabel(singular, plural)` through
   `terminologyProvider`, and the placeholders are `singularTerm` / `pluralTerm` — `plural` is an ICU
   keyword and a placeholder that shadows it parses today and stops parsing on the next `gen-l10n`.
8. **The observation label is the user's, and it must not become a clinical claim.** The vocabulary is
   `vocab_terms(list='ewe_observation')` — six seeded keys, user-extensible, `label IS NULL` meaning
   *render the shipped ARB default* (R66). Resolve it at the presentation edge, never in
   `lib/domain/` or `lib/data/`, which the layer rules forbid from importing `AppLocalizations`. And
   the clause states **what was observed**, never a consequence: *"prolapsed 2025"* is a record;
   *"prolapse risk"* is a diagnosis and `ContentPolicy` should catch it.
9. **The line is one string to a screen reader and four clauses to a sighted reader.** Build it as one
   `Text` with a single `semanticLabel`, not four sibling `Text`s — four nodes means four rotor stops
   in front of the one line the whole screen exists to deliver (10 §3.4). The separator is the
   middle dot `·` visually; the semantics label uses a comma or a full stop so it is spoken, not
   swallowed.
10. **200 % text scale wraps; it does not truncate.** 10 §5 is explicit that a user's own words are
    never ellipsised, and the whole line is the payload. Let it wrap onto three lines at AX5; the
    matrix pumps `ewe_card` at 3 text scales × 2 bold states and will catch a `RenderFlex` overflow
    that a fixed-height row introduces. That fixed height is Frame 1's placeholder only — measure and
    reserve at scale 1.0, and let the loaded row grow.
11. **`terminologyProvider` and `unitsProvider` are `Provider`, not `StreamProvider`** (§3.1, R68).
    Both derive from `settingsProvider`. Watching `settingsProvider` here directly instead would put
    a second `AsyncValue` on the screen for no gain, and 07 §1.2 permits the singletons precisely so
    the screen does not have to.
12. **This line is not a golden.** 12 §8's note is explicit: *"the ewe-card summary line is covered by
    the matrix plus the a11y gates."* Eight images is the budget and this is not one of them. Do not
    add `matchesGoldenFile`.
13. **05 §7.3's legitimate-copy test already contains this line.** `'412 · 3 seasons · avg 2.0 ·
    assisted twice'` is a fixture in `ContentPolicy`'s does-not-reject test. If the wording is changed
    here, that assertion is the canary — and if a new clause trips `bannedInUserFacingText`, the
    wording is wrong, not the guard.

### 5.4 The full test set this task ends with

| File | Case | Edge it covers |
|---|---|---|
| `test/features/ewe_card_test.dart` | `'the summary line is assembled in Dart from ewe_summaries counts, not read as a stored string'` | **The anchor.** The line renders; the same seeded row re-renders under a different terminology; `ewe_summaries` has no text column |
| | `'the summary line is the first widget in the card, above the timeline'` | Spec §7.7's *"visible before anything else"*, as a widget-order assertion, not a comment |
| | `'a ewe with no ewe_summaries row renders No seasons recorded and does not throw'` | `watchSingleOrNull` returning null — every ewe, for the first ten seconds of her life |
| | `'a lambing with no lambs recorded yet drops the average clause rather than printing avg 0.0'` | 05 §6.5's `notComputable`; the common transient state decision #11 creates |
| | `'the average divides by lambings recorded, not seasons recorded'` | Seed 3 seasons / 2 lambings / 4 lambs and assert `avg 2.0`, not `avg 1.3` |
| | `'a lambing with no ease score is excluded from both sides and the coverage is stated'` | 05 §6.7, both halves. Seed 3 lambings, 2 scored, 1 assisted → `assisted once · of 2 scored` |
| | `'no lambing has an ease score, so the assisted clause is absent, not zero'` | `notComputable`, **not** `0%` |
| | `'the observation clause names the newest observation and the year of its season'` | Seed two observations in different seasons; the newer one wins |
| | `'a ewe with no observation renders three clauses'` | The Flock row's shape, reached from the card's own data — proves the clause is optional, not blank |
| | `'renaming ewe to gimmer changes the title and the line with no database write'` | `terminologyProvider` overridden in the container; the row is untouched |
| | `'the summary line exposes one semantics node, not four'` | 10 §3.4. Four nodes is four rotor stops in front of the retention feature |
| | `'the line wraps and does not truncate at textScale 2.0 with boldText'` | 10 §5; the matrix covers it too, but this fails with a readable message |
| | `'the assembled line does not trip ContentPolicy.bannedInUserFacingText'` | 05 §7.3 in the tier that owns the wording. Run every clause combination the cases above produce |
| `test/features/ewe_card_dst_test.dart` | `@Tags(['uk-zone'])` · `'an observation recorded at 01:30 on 25 October 2026 attributes to its own season, not to the year of the instant'` | The ambiguous hour, and the season-is-a-stored-FK rule this clause depends on |

## 6. Constraints that bind this task

- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **§12.2, the origination line** — the app may arithmetic-transform a number the shepherd supplied; it
  may never originate one that is a clinical decision. Four counts in, four clauses out, no judgement.
- **§12.4** — an unscored lambing is *not recorded*, never *unassisted*; a missing average is absent,
  never `0.0`.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the summary line is assembled in Dart from ewe_summaries counts, not read as a stored string'` passes, and was seen to fail first for the stated reason
- [ ] no stored summary string anywhere
- [ ] the line respects the user's terminology and units
- [ ] it renders at 200% text scale without truncation
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] `ewe_summaries` gained no column; the `codegen` job produced no diff under `drift_schemas/`
- [ ] the average divides by `lambingsRecorded`; a zero-lamb lambing drops the clause rather than printing `0.0`
- [ ] partial ease coverage is stated on the line, and a blank ease is never read as unassisted
- [ ] every new ARB message has a `description`, and no domain noun is a literal in any of them
- [ ] the line is one semantics node, and no `matchesGoldenFile` call was added

## 8. Verification

```bash
# 1. Red first, for the stated reason.
fvm flutter test test/features/ewe_card_test.dart

# 2. Green, plus the zone leg.
fvm flutter test test/features/ewe_card_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone

# 3. Nothing moved in the schema.
make gen && git diff --exit-code -- lib/ drift_schemas/ test/drift/generated/

# 4. Both gates.
make check
make test
```

```bash
grep -rn "avg\|assisted\|prolaps" lib/features/flock/ --include=*.dart   # expect: keys, not sentences
grep -n "\"singular\"\|\"plural\"" lib/l10n/app_en.arb                   # expect: nothing (10 §8.5)
grep -rn "matchesGoldenFile" test/features/ewe_card_test.dart            # expect: nothing (12 §8)
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(ewe_card): the one-line summary, assembled from counts`
