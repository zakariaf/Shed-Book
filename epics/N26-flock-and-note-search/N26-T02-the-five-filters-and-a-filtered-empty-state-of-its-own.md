# N26-T02 — The five filters and a filtered-empty state of its own

| | |
|---|---|
| **Epic** | [N26 — Flock and Note Search](epic.md) · `00-README` §9 step 10 (1 of 4) |
| **Task** | 2 of 7 |
| **Depends on** | N26-T01 |
| **Commit** | one commit · `feat(flock): the five filters and a filtered-empty state of its own` |

## 1. Why this task exists

Spec §7.7's filters — barren, not yet lambed, triplet-bearing, currently penned, under
treatment — and a **filtered-empty** state whose copy is not the empty state's, because *you have no
ewes* and *no ewes match this filter* are different facts and only one of them is alarming.

It also carries **ruling N1**, and that is the safety-shaped half of the task. `07 §3.1`'s
`under_withdrawal` predicate is `w.kind = 'days' AND w.clear_date >= :today`, and `03 §5.8` says
*"NO ROW for a target means NotRecorded."* Put those two sentences together and a ewe injected
yesterday whose withdrawal nobody typed is **absent** from the *under treatment* filter — the app
answering a withdrawal question on the user's behalf, which is the exact shape spec §12.1 forbids.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§3.1** (the filters are SQL, the search box is Dart) · **§3.2** (the Filtered-empty state and its *"Clear filters"* action) · §3.3 (*"Toggle a filter \| 1 each \| filter chips are 60 pt, in a horizontally scrolling row"*) · §1.4 (the state vocabulary — Empty and Filtered-empty are separate rows) · §2.2 (the empty-state table) | which five, how they render, and why two empty strings |
| `docs/engineering/03-data-model-and-schema.md` | **§5.3** (`ewe_seasons.status`'s seven stored keys; `scanned_count` `BETWEEN 0 AND 6`; **no default, and why**) · **§5.8** (`Treatments` + `TreatmentWithdrawals`; *"NO ROW for a target means NotRecorded"*; `voided_at`) · §5.9 (`pen_occupancies.exited_at IS NULL`) · §5.13 (`app_settings.current_season`) | every column each filter reads |
| `docs/engineering/05-domain-correctness.md` | the `WithdrawalStatus` triple — `ClearsOn` / `NoWithdrawal` / `WithdrawalUnknown` — and `computeWithdrawalStatus({administeredAt, period})` · `clearDateFor` · `LocalDate.of(Instant)` | why *not recorded* is a third answer and not a false |
| `docs/engineering/CONVENTIONS.md` | §2.7 (the withdrawal types; **`WithdrawalMilkings` does not exist**) · §2.14 · §3.4 (`flockControllerProvider` holds screen state, never data) · §4.4 (controllers: *"derived collections are stored fields computed in a factory, never getters"*) · §4.5 (widget keys) · §5.1 (*barren*, never *empty*; *penned*, never *housed*) · **R42** (barren is `ewe_seasons.status = 'barren'`, and `EweObservations` never carries it) · R24 (`now` is a parameter) | **BINDING** on the words, the keys and where barren lives |
| `docs/design/indelible.md` | **§8 Screen 1** (*"a single horizontally scrolling 64px ruled line of words with counts printed after them: `ALL 8 · NOT YET LAMBED 2 · IN THE PENS 4 · UNDER TREATMENT 1 · BARREN 1`"*) · §7.13 (the word button; **Selected** is a 2px `--ink-full` underline while siblings sit at `--ink-mid`) · §2.7 (`WITHDRAWAL · CLEARS 12 AUG` with day tally marks; `— NOT RECORDED` over a dotted rule) · §4.5 (the reach bands: the filter line is in the **reach** band, and nothing there is required) | the filter line's form, and what *selected* looks like without colour |
| `docs/engineering/06-design-system.md` | §6.1 (`tapMin` **60**, `gapMin` **16**) · **§7 (the gesture ban, and the one permitted tracked gesture)** · §12 (`ShedEmptyState` *"occupies the same box the populated content will"*) | the target floor and the horizontal-scroll problem |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.2 rule 2 (**never put state in the label** — use `selected:`) · §3.2 rule 3 (the label matches the visible text) · §5.2 (the redundancy table) · §8.4 (ARB conventions; the `description` carries the rationale) | how a selected filter announces itself |
| `docs/engineering/12-testing.md` | §2.3 (the ambiguous hour) · §5.2 (fixtures for shape at volume) · §11.5 (`flock_400_3seasons.json`) | how five filters get asserted against 400 ewes |
| `docs/research/00-tech-decisions.md` | §5 only for versions · #47 (SQL-side time is banned) · #50 (the stored `clear_date`) · #52 (the two gates that prove *never default a withdrawal*) · #59 (statistic inputs; `to_ram` is a commercially sensitive denominator) · #71 (never a spinner) · §7.0 ruling 3 (ambiguous DST hour **01:00–01:59**) | the decisions the filters apply |
| `shed-book-spec.md` | **§7.7** (*"Filter the flock by anything: barren, not yet lambed, triplet-bearing, currently penned, under treatment"*) · **§12.1** (never default a medicine withdrawal period) | the five, named, and the rule ruling N1 protects |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-withdrawal` | the *under treatment* filter is a withdrawal-status read, and *not recorded* is a third answer |
| `indelible-states-and-feedback` | two distinct empty states and their wording |

`shed-screens-and-routing` fired in T01 and its rulings still bind; do not reload it for the filter
line. `CLAUDE.md` allows at most two auto-firing skills per intent.

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/flock_test.dart`
- **Test** — `'a filter with no matches renders the filtered-empty copy, not the empty copy'`
- **Why it is red today** — there are no filters, and the first empty state would serve both cases.

```bash
fvm flutter test test/features/flock_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it cannot pass on a shared string. Restore `flock_400_3seasons.json`, select
**barren**, then select **triplet-bearing** as well so the intersection is empty, and assert:

1. `find.text(l10n.flockFilteredEmpty)` is `findsOneWidget` **and**
   `find.text(l10n.flockEmpty)` is `findsNothing` — the two ARB keys are read from
   `AppLocalizations`, never typed as literals into the test, so renaming one breaks compilation rather
   than passing silently.
2. The action reads *"Clear filters"*, not *"Add a ewe"*. `07 §3.2` gives Empty and Filtered-empty
   **different actions**, and an app that offers *Add a ewe* when 400 ewes exist has told the shepherd
   their flock is gone.
3. Clearing the filters restores the full row count, read off the database — round-tripping the state
   rather than asserting a snapshot of it.

**Green.** The minimum code that passes, and nothing beyond it — five filters over the one statement, and two distinct ARB strings.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8 order

**Steps 1–3 are skipped and the commit message says so** — with one exception at step 2: nothing new is
computed, but `computeWithdrawalStatus` gains a second call site, which is why `test/policy/` gains a
row rather than `test/domain/`.

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/data/flock_repository.dart` | **Edit.** `watchFlock()` gains `Set<FlockFilter> filters` and the four SQL predicates. `FlockFilter` is declared here, beside `FlockRow`, because layer rule 3 forbids `lib/data/` importing `lib/features/`. The `under treatment` predicate is **not** in SQL — see §5.2 |
| 2 | `lib/features/flock/flock_controller.dart` | **Edit.** `FlockState` gains `Set<FlockFilter> active` and the **stored** filtered list; `FlockController` gains `toggle(FlockFilter)` and `clearFilters()`. The withdrawal comparison happens here, against a `LocalDate` the widget supplies |
| 3 | `lib/features/flock/widgets/flock_filter_line.dart` | **New.** The 64 px horizontally scrolling ruled line of word buttons with counts. Selected = a 2 px `--ink-full` underline, never a colour change (Indelible §7.13) |
| 4 | `lib/features/flock/flock_screen.dart` | **Edit.** Mount the filter line under the header; branch Empty / Filtered-empty; watch `minuteTickProvider.select((t) => LocalDate.of(t))` so the day boundary re-renders **and the ticker dies with the screen** |
| 5 | `lib/l10n/app_en.arb` | **Edit.** `flockFilteredEmpty`, `flockClearFilters`, the five filter labels and the *withdrawal not recorded* row label — each with a `description` naming the fact it states and the fact it must not be confused with |
| 6 | `docs/engineering/07-screens.md` §3.1 | **Edit — ruling N1.** Replace the `under_withdrawal` `EXISTS` with the two clock-free columns and state, in one sentence, that an unrecorded withdrawal is **unknown**, never clear. `00-README` §10's amendment rule: the document that applies the decision changes in the same commit |
| 7 | `docs/engineering/CONVENTIONS.md` §2.14 | **Edit.** Add the `FlockFilter` row |
| 8 | `test/support/seeds.dart` | **Edit.** Extend `seedTreatment` with a `withdrawalDays` that may be **omitted**, so a test can create the unrecorded case without a bespoke helper |
| 9 | `test/policy/flock_filter_never_implies_a_withdrawal_test.dart` | **New.** The property, not the file (`CONVENTIONS §4.1`). Ruling N1's executable form |
| 10 | `test/features/flock_test.dart` | **Edit.** The anchor and the per-filter cases |
| 11 | `test/data/flock_repository_test.dart` | **Edit.** Each predicate against `NativeDatabase.memory()` |

### 5.2 The signatures

```dart
// lib/data/flock_repository.dart

/// Spec §7.7's five, in the order Indelible §8 prints them on the filter line.
/// The stored keys are the ARB keys and the widget keys; spell them once.
enum FlockFilter {
  notYetLambed('not_yet_lambed'),
  currentlyPenned('currently_penned'),
  underTreatment('under_treatment'),
  tripletBearing('triplet_bearing'),
  barren('barren');

  const FlockFilter(this.key);
  final String key;
}
```

Four of the five narrow the `WHERE`; the fifth cannot, and that is ruling **N1**:

```dart
  /// 07 §3.1: "Filters are SQL; the search box is Dart." Four of the five are.
  ///
  /// `underTreatment` is NOT here. It is the one filter whose answer depends on
  /// today's date, SQL-side time is banned (decision #47), and a `:today` bound
  /// once when the statement is built never advances — so a phone left on this
  /// screen across midnight would filter against yesterday. The statement
  /// returns `latest_clear_date` and `unrecorded_withdrawal` (T01, both
  /// clock-free) and the controller compares them. Ruling N1.
  Stream<List<FlockRow>> watchFlock({Set<FlockFilter> filters = const {}});
```

The four SQL predicates, appended to T01's statement as an `AND`-joined `WHERE`:

```sql
-- notYetLambed  — 03 §5.3's stored keys, for the CURRENT season only.
--                 'barren' is NOT "not yet lambed": Indelible §8 prints them as
--                 two different stamps (TO LAMB, BARREN) on two different rows.
es.status IN ('to_ram','scanned')

-- currentlyPenned — 07 §3.1 verbatim. `penned_since IS NOT NULL` on the row.
EXISTS (SELECT 1 FROM pen_occupancies o
         WHERE o.ewe = e.id AND o.exited_at IS NULL)

-- tripletBearing — the SCAN, not the birth. See §5.3 for why, and for the
--                  document amendment if the reviewer disagrees.
es.scanned_count >= 3

-- barren — R42. `ewe_seasons.status = 'barren'`, for the current season.
--          NEVER an EweObservations row: "the `ewe_observation` vocabulary has
--          no barren key" (obs_prolapse, obs_mastitis, obs_poor_mothering,
--          obs_good_mothering, obs_no_milk, obs_other).
es.status = 'barren'
```

And the fifth, in Dart, where the clock lives:

```dart
// lib/features/flock/flock_controller.dart

/// Ruling N1. A row is "under treatment" when its withdrawal status is
/// ClearsOn (still running) OR WithdrawalUnknown (a live treatment whose
/// withdrawal nobody typed). NoWithdrawal — 'not_applicable', explicitly
/// recorded — is the only arm that means "clear", because it is the only one
/// the user actually answered.
///
/// Spec §12.1: the app never defaults a withdrawal period. Reading an ABSENT
/// row as "not under treatment" is defaulting it to zero by omission, which is
/// the one direction the rule does not permit. 03 §5.8: "NO ROW for a target
/// means NotRecorded."
bool isUnderTreatment(FlockRow row, LocalDate today) {
  if (row.hasUnrecordedWithdrawal) return true;               // WithdrawalUnknown
  final clear = row.latestClearDate;
  return clear != null && clear.compareTo(today) >= 0;        // ClearsOn
}
```

The screen supplies `today` from the ticker, and the ticker dies with the screen:

```dart
// lib/features/flock/flock_screen.dart
/// The day boundary, watched by the WIDGET and not by the provider.
/// 02 §4.2 makes minuteTickProvider `.autoDispose` so "nothing should tick when
/// nothing displays elapsed time"; flockListProvider is keepAlive, so a watch
/// there would pin the ticker for the life of the app. `.select` on the civil
/// date means one rebuild per DAY, not one per minute.
final today = ref.watch(minuteTickProvider.select(
  (tick) => tick.whenData(LocalDate.of),
));
```

The controller's derived list is a **stored field computed in a factory**, never a getter:

```dart
/// CONVENTIONS §4.4 rule 5 and 02 §4.4: "anything reachable through `.select`
/// is a stored field, computed once in the state class's factory. Never a
/// getter that builds a collection."
@immutable
final class FlockState {
  factory FlockState.from({
    required List<FlockRow> all,
    required Set<FlockFilter> active,
    required String query,
    required LocalDate today,
  }) { … }                       // filters, then ranks, ONCE

  final List<FlockRow> visible;  // stored
  final Set<FlockFilter> active;
  final Map<FlockFilter, int> counts;   // Indelible §8 prints a count per word
}
```

### 5.3 The details that are easy to get wrong

- **Ruling N1 is the task, and it is a §12.1 question wearing a filter's clothes.** `07 §3.1`'s
  predicate quietly equates *"no withdrawal row"* with *"no withdrawal"*. `03 §5.8` is explicit that
  they are different: the child table exists precisely because *"a nullable `int?` conflates 'the label
  says 0 days' with 'I didn't look', and `0` is a real label value."* Amend `07 §3.1` in this commit.
  If a reviewer disagrees, **carry it into the PR body as open with both sides cited** — do not
  implement around it.
- **`NoWithdrawal` is not the same as an absent row.** `03 §5.8`'s `kind` CHECK is
  `('days','not_applicable')`, and `not_applicable` is something the user *typed*. Only that arm may
  mean *clear*. The three-way distinction is `05`'s sealed `WithdrawalStatus` and it exists so this
  exact conflation is unrepresentable.
- **`voided_at` is a soft void and the filter must respect it** (decision #69). A voided treatment is
  still in the medicine book — the book *"shows the void; it never loses the row"* — but it is not a
  live withdrawal. T01's statement already carries `t.voided_at IS NULL`; a filter that reads
  `latest_clear_date` without it is filtering on a treatment the shepherd withdrew.
- **`triplet-bearing` is the *scan*, not the birth, and this needs a written line.** `ewe_seasons.scanned_count`
  is what a scanner wrote, and it is the number the filter exists to serve: at 11am in the yard a
  shepherd filters for triplet-bearing ewes because they need extra feed **before** they lamb. Reading
  it as `lambings.declared_birth_type = 3` answers a historical question the Ewe Card already answers,
  and P8 makes `declared_birth_type` derived from tally strokes anyway. Write the reasoning into the
  predicate's comment; if it is ruled the other way, the change is one line and one test.
- **`scanned_count >= 3`, not `= 3`.** The CHECK is `BETWEEN 0 AND 6`. A ewe scanned for quads needs
  more feed than one scanned for triplets, and a filter that hides her is worse than useless.
- **`barren` is `ewe_seasons.status`, and R42 exists because 07 got it wrong.** `07 §4.3` said barren
  was an `EweObservations` row; R42 rules it is a **season participation outcome** and lists the six
  `obs_*` keys to prove the vocabulary has no barren term. Reading `ewe_observations` here reproduces a
  ruled-against defect.
- **`not yet lambed` excludes `barren`.** The stored keys are seven — `to_ram`, `scanned`, `lambed`,
  `barren`, `aborted`, `died`, `sold` — and the filter admits the first two only. A ewe recorded barren
  has *finished* the season; showing her under *not yet lambed* is telling the shepherd to keep
  watching her.
- **A ewe with no `ewe_seasons` row matches none of the season-scoped filters, and that is correct.**
  `es.status` is `NULL` and `NULL IN (…)` is `NULL`, which SQLite treats as false in a `WHERE`. Do not
  "fix" it with `COALESCE(es.status, 'to_ram')` — `03 §5.3` refuses that default because `to_ram` is
  the denominator of a commercially sensitive number (decision #59).
- **Two selected filters are an `AND`, not an `OR`, and the intersection is often empty.** That is what
  makes the Filtered-empty state reachable and is why the anchor selects two. `07 §3.2`'s copy is
  *"No animals match these filters."* — plural, because more than one can be on.
- **The filter line scrolls horizontally, and drag is banned.** `07 §3.3` puts the chips *"in a
  horizontally scrolling row"*; `CLAUDE.md` bans drag and drag handles; Indelible §8 makes it a single
  64 px ruled line of words. **The gate has no row that catches
  `ListView(scrollDirection: Axis.horizontal)`** — this is caught in review, not by CI, so write the
  reasoning beside the widget. `06 §7`'s one permitted tracked gesture is scrolling, with the
  mitigation that *"no action is ever reachable only behind a scroll"*: `ALL` is always visible, and
  every filter is also reachable from the index sheet (Indelible §7.17).
- **Selected is an underline, not a colour.** Indelible §7.13: *"Underline goes 2px `--ink-full`; label
  `--ink-full` while siblings sit at `--ink-mid`."* `10 §5.1` and decision #106 forbid colour as the
  only channel, and a red-head-torch shepherd is optically colour-blind (Indelible §2.7).
- **`selected:`, never `label: 'Barren, selected'`.** `10 §3.2` rule 2. And rule 3: the label matches
  the **visible** text, or Voice Control's *"tap barren"* does nothing.
- **The counts printed after each word are computed from the unfiltered list, not the filtered one.**
  Indelible §8: `ALL 8 · NOT YET LAMBED 2 · IN THE PENS 4 · UNDER TREATMENT 1 · BARREN 1`. A count
  computed after filtering reads `0` for every unselected word the moment one filter is on, which makes
  the line useless exactly when it matters.
- **The empty state occupies the same box the list will.** `06 §12` and decision #71:
  `ShedEmptyState` is *"one line of copy + one action, at the same `tapHero` control the populated
  screen uses. No illustration, no spinner, no tour."*
- **Filters do not survive a pop.** `02 §9` — there is no state restoration, and `07 §1.6` resets the
  Navigator to Quick Entry after two minutes backgrounded. Persisting the filter set to `app_settings`
  would be a schema change, which is irreversible after N07's freeze; the filter set lives in the
  keepAlive controller and dies with the process, which is the honest answer.

### 5.4 The full test set

| File | Case | What it asserts |
|---|---|---|
| features | `'a filter with no matches renders the filtered-empty copy, not the empty copy'` | **The anchor.** Two filters whose intersection is empty; `flockFilteredEmpty` present, `flockEmpty` absent, action reads *Clear filters*; clearing restores the full count |
| features | `'each of the five filters narrows the 400-ewe fixture to its own count'` | Five cases, each count read off the database, none a literal |
| features | `'two selected filters intersect rather than union'` | *barren* + *currently penned* against a fixture ewe that is both, and one that is only one |
| features | `'the counts after each filter word are computed before filtering'` | Select *barren*; the *IN THE PENS* count is unchanged |
| features | `'a selected filter announces with selected:, not with a word in its label'` | `10 §3.2` rule 2. The semantics node's `label` is the visible word; `selected` is true |
| features | `'a selected filter is distinguishable with colour removed'` | Render at both `ShedPaletteId.deepRed` and `night`; the underline exists in both, and the two frames differ in geometry, not only in ink |
| features | `'every filter word is at least 60 by 60 and 16 apart'` | `06 §6.1`. The line scrolls, so assert against the laid-out `Rect`s, not the intended sizes |
| features | `'the empty state and the filtered-empty state occupy the same box'` | Decision #71; `Rect` equality between the two, and with the populated list's content box |
| features | `'clearing the filters issues no additional statement'` | The filter set is a `WHERE` on the one statement; the count changes, `db.executedStatements` grows by one per **filter change**, never per row |
| data | `'notYetLambed admits to_ram and scanned and excludes barren, lambed, aborted, died and sold'` | All seven stored keys, one assertion each |
| data | `'barren reads ewe_seasons.status and never ewe_observations'` | R42. Seed an `obs_*` row too and prove it changes nothing |
| data | `'tripletBearing admits scanned_count 3, 4, 5 and 6 and excludes 0, 1 and 2'` | `>=`, not `=`; the CHECK bounds are 0..6 |
| data | `'a ewe with no ewe_seasons row for the current season matches no season-scoped filter'` | `NULL IN (…)` is not true; no `COALESCE` |
| data | `'currentlyPenned reads an open occupancy and ignores an exited one'` | `exited_at IS NULL` |
| data | `'a voided treatment does not put a ewe under treatment'` | Decision #69; the clear date is in the future and the treatment is voided |
| policy | `'a live treatment with no withdrawal row is under treatment, not clear'` | **Ruling N1.** The property, in `test/policy/` because it holds a §12 rule, named for the property and not for the file (`CONVENTIONS §4.1`) |
| policy | `'a withdrawal recorded as not_applicable is clear, and an absent one is not'` | The two arms that look alike and are not. `03 §5.8`'s `kind` CHECK |
| policy | `'no filter predicate reads a clock'` | Source text over the SQL: no `date(`, no `datetime(`, no `CURRENT_`, no `:today` (decision #47) |
| features · **`@Tags(['uk-zone'])`** | `'a clear date of today is still under treatment at 01:30 and at 01:30 again'` | `TZ=Europe/London`, `withClock` at **01:30** on the clocks-back night, evaluated twice across the repeated hour. `clear_date >= today` must hold both times: the ewe must not become clear for one hour and then unclear again |
| features · **`@Tags(['uk-zone'])`** | `'the day boundary rebuild fires once across the 23-hour clocks-forward day'` | The `.select((t) => LocalDate.of(t))` contract. On the spring-forward day the wall clock skips an hour; the civil date still changes exactly once, so the filter must re-evaluate once |

### 5.5 What this task deliberately does not build

- **The trailing state word and figure on the row** (`WITHDRAWAL 9d`, `PEN 4 31h`). T03 renders them;
  this task produces the facts they render.
- **The `WITHDRAWAL — NOT RECORDED` row rendering.** The ARB string is authored here because the
  filter is here; the row that shows it is T03's.
- **Persisting the filter set.** There is no column for it and there must not be.

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 60 × 60 pt with ≥ 16 pt separation (`06 §6.1`; Indelible builds to 64 × 64), 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. Here specifically: **barren**, never *empty* or *not in lamb*; **penned**, never *housed*; **withdrawal period** then **withdrawal**, never *withholding* or *"the days"*.
- **Safety rule §12.1, as a mechanism rather than a note** — *never default a medicine withdrawal
  period*. Ruling N1 is this rule applied to a read. `CLAUDE.md` puts §12.1 at *unconstructible +
  unpersistable*; a filter that reads an absent row as clear drops it to *documented*, and *"a rule
  that has dropped to merely documented has been deleted, whatever the prose says."*

## 7. Definition of Done

- [ ] `'a filter with no matches renders the filtered-empty copy, not the empty copy'` passes, and was seen to fail first for the stated reason
- [ ] all five filters, each asserted against the 400-ewe fixture
- [ ] two distinct empty strings, both in the ARB
- [ ] under treatment reads the withdrawal status, not a boolean
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] **ruling N1 is closed by an amendment to `07 §3.1` in this commit, or carried into the PR body as open with both sides cited**
- [ ] a live treatment with no `treatment_withdrawals` row places its ewe **under treatment**, and the property is held in `test/policy/`
- [ ] `not_applicable` is the only arm that means clear
- [ ] `barren` reads `ewe_seasons.status` (R42); `ewe_observations` appears nowhere in this diff
- [ ] `tripletBearing` is `scanned_count >= 3` and its comment states why the scan and not the birth
- [ ] no filter predicate reads a clock; `:today` appears nowhere in the SQL
- [ ] `minuteTickProvider` is watched by the **widget** with `.select` on the civil date, never by `flockListProvider`
- [ ] the filter counts are computed from the unfiltered list
- [ ] a selected filter is distinguishable with colour removed, and announces with `selected:` rather than a word in its label
- [ ] `FlockFilter` has a row in `CONVENTIONS §2.14`, added in this commit
- [ ] `drift_schemas/` is untouched — the filter set is never persisted

## 8. Verification

```bash
fvm flutter test test/features/flock_test.dart
make check
make test
```

```bash
fvm flutter test test/data/flock_repository_test.dart
fvm flutter test test/policy/flock_filter_never_implies_a_withdrawal_test.dart
TZ=Europe/London fvm flutter test --tags uk-zone
```

```bash
grep -rn ":today\|date(\|datetime(\|CURRENT_" lib/data/flock_repository.dart  # expect zero
grep -rn "ewe_observations\|eweObservations" lib/features/flock/ lib/data/flock_repository.dart
                                                                             # expect zero (R42)
grep -rn "minuteTickProvider" lib/features/flock/                            # widget only
grep -rn "Dismissible\|Draggable\|onLongPress\|Slider" lib/features/flock/    # expect zero
git diff --name-only main -- drift_schemas/                                  # expect empty
git diff main -- docs/engineering/07-screens.md                              # ruling N1's amendment
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(flock): the five filters and a filtered-empty state of its own`
