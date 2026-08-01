# N25-T01 — `remindersProvider` and `RemindersView` — three groups off the ticker

| | |
|---|---|
| **Epic** | [N25 — Reminders screen](epic.md) · `00-README` §9 step 9 (2 of 2) |
| **Task** | 1 of 6 |
| **Depends on** | N24-T08 |
| **Commit** | one commit · `feat(reminders): three groups from one statement, off the ticker` |

## 1. Why this task exists

One statement, three groups — due today, overdue, upcoming — with the day boundaries
computed from N12-T03's ticker so the groups re-sort themselves at midnight without a rebuild
storm.

Nothing has ever read a reminder back. N24 wrote rows and projected them to the OS; the shepherd has no
way to see what the app knows. This task is the read path and the screen skeleton: the `customSelect`,
the provider, the three headings, the row. T02–T05 hang the honest line and the two verbs off it.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §11.1 | the SQL, verbatim, and the muted-are-listed-not-counted rule |
| `docs/engineering/07-screens.md` | §11.3 | the seven states, including "empty in one bucket only" |
| `docs/engineering/07-screens.md` | §1.2 | the one-query rule and what a screen may legitimately watch besides it |
| `docs/engineering/07-screens.md` | §9.2 | `minuteTickProvider`'s body, and why `.autoDispose` is load-bearing |
| `docs/engineering/CONVENTIONS.md` | §3.2, §3.3, §3.4, §4.5, R25 | `remindersProvider`, the ticker, the controller pair, widget keys |
| `docs/engineering/01-architecture.md` | §4.4 | `.distinct()` in the repository, never in the widget; `readsFrom:` on aggregates |
| `docs/engineering/03-data-model-and-schema.md` | §5.10 | `reminders`' columns, its CHECKs and `idx_reminder_due_open` |
| `docs/engineering/10-accessibility-and-i18n.md` | §3.4, §3.8, §8 | the heading table, the one live region, the ARB house rules |
| `docs/design/indelible.md` | Screen 9 | overdue above the ruling with a `†`, then `DUE`, then a double rule marked `NOT YET WRITTEN` |
| `shed-book-spec.md` | §7.6 | due today, overdue, upcoming |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-riverpod-providers` | one statement, three groups, and the ticker's blast radius |
| `shed-screens-and-routing` | the screen and its route |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/reminders_test.dart`
- **Test** — `'the three groups re-sort at the local midnight boundary from one statement'`
- **Why it is red today** — nothing reads reminders back for a screen.

The assertion, so the anchor cannot pass by accident: seed three open reminders — one at `23:30`
yesterday, one at `23:50` today, one at `00:10` tomorrow — pump `RemindersScreen`, assert
Overdue / Due today / Upcoming hold 1 / 1 / 1, then `await tester.pump(const Duration(minutes: 40))`
across local midnight and assert 2 / 1 / 0 **without a second `pumpApp`**, and assert the statement re-ran
exactly once across those forty ticks.

```bash
fvm flutter test test/features/reminders_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — one statement, the grouping in Dart over a single ordered read, and the boundary from the
ticker.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 Files touched, in `00-README` §8's order

| §8 step | File | What changes, and why |
|---|---|---|
| 1 — schema | **skipped** | `reminders` shipped in N07-T06 and was frozen at N07-T08. This task stores nothing new. Say so in the commit body; `codegen` fails the PR if `drift_schemas/` moves |
| 2 — domain | **skipped** | the bucketing is arithmetic over two `Instant`s that already exist. No new domain type |
| 3 — write path (read half) | `lib/data/reminder_repository.dart` | add `watchReminders(...)` and the `ReminderRow` record. This is the **only** layer that may hold the `customSelect`; `lib/features/` may not import `package:drift/*` (layer rule 5) |
| 4 — wiring | `lib/data/providers.dart` | **no change.** `reminderRepositoryProvider` already exists (§3.1, N24-T04) |
| 5 — controllers | `lib/features/reminders/reminders_controller.dart` | **new.** `RemindersView`, `remindersProvider`, `RemindersState`, `RemindersController`, `remindersControllerProvider` |
| 6 — UI | `lib/features/reminders/reminders_screen.dart` | **new.** `RemindersScreen` — three groups, the frame-1 placeholders, the error panel |
| 6 — UI | `lib/features/reminders/widgets/reminder_group.dart` | **new.** the `headingLevel: 2` heading plus its own one-line empty state |
| 6 — UI | `lib/features/reminders/widgets/reminder_row.dart` | **new.** one row: kind label, animal tag, due time, and the *source event's* provenance line |
| 6 — routing | `lib/routing/routes.dart` | add the push helper `Routes.reminders(BuildContext)`. `RouteNames.reminders` **already exists** — 02 §8.1 declares 13 and a fourteenth breaks the matrix self-check |
| 6 — ARB | `lib/l10n/app_en.arb` | screen title, three group headings, three per-bucket empty lines, the row's semantic label |
| 7 — tests | `test/features/reminders_test.dart` | **new.** the anchor plus §5.4's cases |
| 7 — tests | `test/features/reminders_dst_test.dart` | **new**, `@Tags(['uk-zone'])`. Tags are per-library, so a mixed file cannot be zone-pinned |

### 5.2 The signatures

**`lib/data/reminder_repository.dart`** — 07 §11.1's statement, verbatim, with an explicit `readsFrom:`
because `schedulable_total` is a scalar subquery and decision #60 sends every aggregate through
`customSelect`:

```dart
/// One row of 07 §11.1's statement. A record, not a class: it is pure Dart, so
/// `lib/features/` may hold it without importing drift, and it gets `==` for
/// free — which is what the `.distinct()` below needs. Same shape of decision
/// as `ProjectedReminder` in 08 §2.3.
typedef ReminderRow = ({
  ReminderId id,
  String kind,            // one of 03 §5.10's eight; also the channel id (R49)
  String title,           // what the app SAID, stored at write time (08 §2.6)
  Instant dueAt,
  bool muted,
  String? eweTag,
  String? lambTag,
  String bucket,          // 'overdue' | 'today' | 'upcoming' — computed in SQL
  int schedulableTotal,   // identical on every row; the honest line's `stored`
});

Stream<List<ReminderRow>> watchReminders({
  required Instant startOfToday,
  required Instant startOfTomorrow,
});
```

**`lib/features/reminders/reminders_controller.dart`**:

```dart
/// CONVENTIONS §3.2 fixes the name and the provider's type. The three lists are
/// a PARTITION of the open reminders, never a filter — 07 §11.3 says
/// "filtered-empty is impossible", and this shape is why.
typedef RemindersView = ({
  List<ReminderRow> overdue,     // oldest first
  List<ReminderRow> dueToday,    // soonest first
  List<ReminderRow> upcoming,    // soonest first
  int schedulableTotal,
});

/// keepAlive (§3.2). ONE statement. The `.select` is not tidiness: watching the
/// raw tick re-runs the SQL 1,440 times a day; collapsed to the civil day it
/// re-runs once, at local midnight.
final remindersProvider = StreamProvider<RemindersView>((ref) async* {
  final today = ref.watch(minuteTickProvider.select(_civilDay));
  final repo = await ref.watch(reminderRepositoryProvider.future);
  yield* repo
      .watchReminders(
        startOfToday: today.startOfDayLocal(),
        startOfTomorrow: today.plusDays(1).startOfDayLocal(),
      )
      .map(_partition);
});

/// `AsyncValue.valueOrNull` is banned (decision-record §5.1; 02 §2.2 bans every
/// AsyncValue accessor). An exhaustive switch, with `appNow()` as the
/// not-yet-ticked arm, is the only spelling that survives the gate.
LocalDate _civilDay(AsyncValue<Instant> tick) => switch (tick) {
      AsyncData(:final value) => LocalDate.of(value),
      _ => LocalDate.of(appNow()),
    };
```

`RemindersController` is the screen controller (§3.4, §4.4 rule 1) and holds **screen state, never data**.
On day one that is one field — `bool alertsGranted`, filled in T02 — plus the scroll anchor. Declare the
pair now so T02 does not invent a second object mid-epic.

Widget keys, `<screen>.<element>[.<qualifier>]`, every segment `lower_snake` (§4.5):
`reminders.group.overdue`, `reminders.group.due_today`, `reminders.group.upcoming`,
`reminders.row.<id>`, `reminders.row.<id>.due_at`.

### 5.3 The details that are easy to get wrong

- **The bucket is computed in SQL; the partition is done in Dart; neither is done twice.** 07 §11.1's
  `CASE` produces `bucket`; `_partition` only sorts rows into lists. Recomputing the bucket in Dart from
  `dueAt` gives two sources of truth that disagree for exactly one minute a day.
- **`ORDER BY r.due_at ASC` already gives overdue oldest-first, and the instinct is to reverse it.** On a
  list of overdue things the reflex is newest-first. The DoD says oldest first, the single `ASC` produces
  it, and the assertion exists so nobody "fixes" it.
- **A keepAlive provider watching an `.autoDispose` one keeps it alive.** `remindersProvider` is keepAlive
  (§3.2); `minuteTickProvider` is `.autoDispose` precisely so "the loop would [not] keep waking the process
  every 60 s all night with no pen board on screen" (07 §9.2). Measure it: subscribe, pop the screen,
  assert the generator stopped. The pen board reads the ticker **at build, inside the tile**, for exactly
  this reason. If the subscription outlives the screen, the fix is one of two recorded edits, not a local
  choice — either `remindersProvider` becomes `.autoDispose` (a `CONVENTIONS` §3.2 edit) or the civil day
  is watched by `RemindersScreen` and pushed into the controller.
- **`ref.invalidate` is not how you re-bucket.** drift's `watch()` re-emits on any write to `reminders`,
  `ewes` or `lambs`. The one legitimate `ref.invalidate` in the codebase is
  `ref.invalidate(minuteTickProvider)` on `AppLifecycleState.resumed` (R25, 02 §4.1) and it already exists
  in `lib/app.dart`. A second one is a defect.
- **`customStatement(` is banned outside `lib/core/db/`; `customSelect` is not.** Layer rule 8 bans the
  mutating API and `customStatement(`. A read `customSelect` in `lib/data/` is the sanctioned shape for an
  aggregate — with `readsFrom: {reminders, ewes, lambs}` spelled out, because without it drift cannot track
  the statement and the stream silently stops updating (01 §4.4).
- **`.distinct()` goes in the repository and needs a comparator.** drift re-runs a stream on *any* write to
  a tracked table even when the result is byte-identical (drift#3295), and `List` equality is identity.
  `.distinct((a, b) => const ListEquality<ReminderRow>().equals(a, b))` — never bare, never in the widget.
- **Frame 1 is a fixed-height placeholder, never a spinner.** `CircularProgressIndicator` under
  `lib/features/**` is a gate row (`ui.spinner`) and fails the build. 07 §11.3: three group headers with
  three fixed-height row placeholders each — the geometry is known before the data is.
- **An empty bucket keeps its heading and gets its own string.** 07 §11.3: *"A missing heading reads as a
  rendering failure, and 'nothing overdue' is the single most reassuring line on this screen at 03:00."*
  Three distinct strings — "Nothing overdue." / "Nothing due today." / "Nothing coming up." — not one
  reused string with a placeholder.
- **Muted rows are listed here.** T04 renders the strike; T01's job is not to lose the row. The `WHERE`
  clause is `completed_at IS NULL` and nothing else — `muted` is selected, never filtered on.
- **The row shows the *source event's* provenance, not the reminder's.** 07 §11.6: a colostrum row reads
  `412 · colostrum · due 03:24 · from a lambing recorded automatically at 01:24`. `due_at` is arithmetic on
  a user-set interval and is not itself an observation, so it carries no provenance label; the event it
  came from does, and that is the one a shepherd needs to judge whether the reminder is still right.
- **The one live region on this screen is the Overdue group heading**, and only when the minute tick moves
  an item into it (10 §3.8). Not the rows. A live region on a frequently-changing node is a screen reader
  that will not shut up.
- **ARB message names and widget keys are different namespaces.** `remindersGroupOverdue` is a Dart
  identifier gen-l10n generates; `reminders.group.overdue` is a `Key`. Every ARB message carries a
  `description`, and no domain noun is a literal — the animal term arrives from `terminologyProvider`.
- **Times are `HH:mm`, 24-hour, `en_GB`; dates a human reads are `d MMM y`, never all-numeric** (§5.4).
  Formatting happens in `lib/core/ui/formatters.dart`, the only `package:intl` call site outside
  `lib/data/`; the controller never formats.

### 5.4 The full test set

`test/features/reminders_test.dart`

| Case | What it holds |
|---|---|
| `'the three groups re-sort at the local midnight boundary from one statement'` | **the anchor**, §4's assertion |
| `'overdue is ordered oldest first'` | three overdue rows at −3 h, −2 h, −1 h render in that order |
| `'a completed reminder is in none of the three groups'` | excluded by the `WHERE`, not by Dart |
| `'a muted reminder is still listed'` | T04 owns the strike; T01 owns not losing the row |
| `'each group heading is headingLevel 2 and uses 07 §11.3's words'` | Overdue · Due today · Upcoming, exactly |
| `'an empty bucket keeps its heading and prints its own line'` | the three strings, asserted separately |
| `'filtered-empty is unreachable'` | zero open reminders renders the empty state, never a filter message |
| `'a read failure renders the standard panel and never the exception text'` | decision #124 |
| `'the row names the source event and its provenance label'` | `recorded automatically` / `time entered by you` / `time edited by you` |
| `'the statement is not re-run when the tick moves inside one civil day'` | the `.select`; count executor calls across five ticks |
| `'the ticker is not left running when the screen pops'` | the keepAlive/autoDispose interaction above |

`test/features/reminders_dst_test.dart` — `@Tags(['uk-zone'])`, run under `TZ=Europe/London`

| Case | What it holds |
|---|---|
| `'a reminder due at 01:30 on 25 October 2026 appears in Due today exactly once'` | the repeated hour: one row, one bucket, no duplicate |
| `'a reminder due at 01:30 on 29 March 2026 lands in the bucket its resolved instant belongs to'` | the skipped hour: `DateTime(2026,3,29,1,30)` resolves to `02:30`, and the row does not vanish |
| `'the day boundary crosses once on 29 March 2026, not twice'` | `startOfDayLocal()` across a 23-hour civil day; one flip |
| `'the day boundary crosses once on 25 October 2026, not twice'` | a 25-hour civil day; still one flip |

Use `atFixed(DateTime(...), () async { … })` for the single-instant cases and **offset the seed data** for
the elapsed cases — `Clock.fixed` freezes `appNow()` and an elapsed assertion wrapped in it silently
measures zero forever (decision #113, 12 §2.2). Put that comment above every `atFixed` call.

### 5.5 Verification

```bash
fvm flutter test test/features/reminders_test.dart
TZ=Europe/London fvm flutter test test/features/reminders_dst_test.dart
rg -n 'package:drift' lib/features/reminders/                  # expect: no matches
rg -n 'combineLatest|ref\.invalidate' lib/features/reminders/  # expect: no matches
rg -n 'CircularProgressIndicator' lib/features/reminders/      # expect: no matches
git diff --stat -- drift_schemas/ lib/core/db/                 # expect: empty
make check
make test
```

## 6. Constraints that bind this task

- **One statement.** 07 §1.2: every screen has exactly one *content* statement; besides it this screen may
  watch only single-row lookups and the app-level singletons (`settingsProvider`, `minuteTickProvider`).
  `combineLatest` over drift streams is a build-breaking defect (drift#3338).
- **3am** — every interactive element ≥ `context.tokens.tapMin` (60) on both axes with ≥ `gapMin` (16)
  separation, the 18 pt text floor, dark only, and none of the banned gestures: no swipe, no drag, no
  long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'the three groups re-sort at the local midnight boundary from one statement'` passes, and was seen to fail first for the stated reason
- [ ] one statement
- [ ] the boundary comes from the ticker, not from a rebuild timer
- [ ] overdue is ordered oldest first
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/features/reminders_test.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(reminders): three groups from one statement, off the ticker`
