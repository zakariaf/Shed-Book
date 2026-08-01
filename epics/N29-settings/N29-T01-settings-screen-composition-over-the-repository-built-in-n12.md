# N29-T01 — Settings screen composition over the repository built in N12

| | |
|---|---|
| **Epic** | [N29 — Settings](epic.md) · `00-README` §9 step 10 (4 of 4) |
| **Task** | 1 of 8 |
| **Depends on** | N28-T06 |
| **Commit** | one commit · `feat(settings): the screen over the repository built in N12` |

## 1. Why this task exists

`SettingsRepository` already exists (N12-T02) with its parameterised persist-and-re-read
test; this is the **screen**. Deliberate friction throughout: this is daylight work and nothing here is
on the 3am path.

Concretely, everything below the screen has been in place for seventeen epics. `app_settings` has
fourteen columns, one row, and `CHECK (id = 1)` (`03 §5.13`). `SettingsRepository` owns every write to
it and has an event verb per column. `settingsProvider : StreamProvider<AppSetting>` is in the DI
graph, and `themeProvider`, `unitsProvider` and `terminologyProvider` derive from it. What has never
existed is a widget that renders any of them.

This task builds the **frame**: the twelve-section list in `07 §14.3`'s order, the screen controller,
the write controller, the route helper entry, and the two sections that need nothing new —
**Reminders** (a row reaching N25's interval editor plus the alerts toggle) and **Pens** (rename and
deactivate, sent here by `07 §9.5` and by N19's epic notes). T02 through T07 write into the frame.

Section 9 (**Unlock**) is deliberately not built: `purchaseServiceProvider` and `entitlementProvider`
arrive in N30, and a section that renders an offer over a provider that does not exist is exactly the
`UnimplementedError` stub N12 refused. Eleven sections, plus a ledger comment.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | **§14.1** (the query: `settingsProvider` plus three counts — *"the only screen with no list statement, and that is legitimate"*) · **§14.2** (six states; **Empty is impossible** and Error replaces the *section list only*) · **§14.3** (the twelve sections **in order**) · **§14.4** (≤ 2 taps for every non-destructive setting; 4 for each destructive one) · **§14.5** (§12 on this screen) · §9.5 (pen rename and the turn-out threshold are sent here) · §20 (primaries in the bottom third; sheet defaults; back is a bottom-bar button) | the screen, section by section |
| `shed-book-spec.md` | §7.10 | units, terminology, intervals, season, theme, the two deletes |
| `docs/engineering/CONVENTIONS.md` | §1 (`lib/features/settings/`) · §1.1 layer rules 5, 6 and 7 · §2.11 (`ShedSectionHeading`, `ShedFieldRow`, `ShedTapTarget`, `context.tokens`) · §3.1 (`settingsProvider`, R29) · **§3.4** (`settingsControllerProvider`, `settingsWriteControllerProvider` — two objects per screen, never one) · **§4.5 + R59** (`<screen>.<element>[.<qualifier>]`, `lower_snake`) · §5 (vocabulary) | **BINDING** on every name, key and path |
| `docs/engineering/10-accessibility-and-i18n.md` | **§3.4** (`headingLevel` only; Settings is *"one per settings group"*; `header: true` is a no-op on 3.44) · §3.2 (label rules) · §4.1–§4.3 (text scaling; never clamp; label-above-value survives 200%) · §8.4 (ARB house rules) | the headings and every string |
| `docs/engineering/06-design-system.md` | §12 (the component inventory: `ShedSectionHeading` emits `headingLevel: 2`, screen titles emit `1`; `ShedFieldRow` puts the label **above** the value) · §9.3 (`tapMin` 60 is the floor for *"every interactive thing, including Settings rows"*) | the controls and their size contracts |
| `docs/design/indelible.md` | **§8 screen 12** (ruled rows, one setting per row, every control a word button or a text field; the double rule above the two deletes) · §7.12 (**never a placeholder inside a field**) · §7.13 (word button; *"never a filled red button"*) · §7.16 (the 44px sticky page header) · §4.4 (row heights) | the composition and its rhythm |
| `docs/engineering/02-state-di-navigation.md` | §6 (controller conventions: screen state, never data; no `BuildContext`, no drift, no formatting) · §7 (`WriteController.guard()`) · §8.1 (`RouteNames` — **thirteen entries**, `Routes.settings`) | the two controllers and the route |
| `docs/engineering/11-monetization-and-store.md` | §5 (`Routes.settings(context, {bool focusUnlock = false})` — an argument on an existing helper, **not** a fourteenth `RouteNames` entry) | the signature N30-T05 will call |
| `docs/engineering/12-testing.md` | §5.1 (`pumpApp`, and its non-zero default padding) · §6.2 (`kPumpableVariants` — **not** touched here; T08 owns it) | how the screen is pumped |
| `docs/research/00-tech-decisions.md` | #71 (**never a spinner** — there is no loading state anywhere) · #104 (`headingLevel`) · #90 (nothing on the shed path branches on `unlocked`) | the states this screen may have |
| `epics/00-PLAN-CRITIQUE.md` | §5 rule 5 (the harness grows per epic) · §9 change 9 (`SettingsRepository` moved to N12) · §9 change 17 (a11y and ARB authored inside each widget task) | why the repository is not here |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-screens-and-routing` | the screen, its route and its sections |
| `indelible-page-and-screens` | the page composition and the deliberate friction |

The heading hierarchy and the ARB rules this task authors are `10 §3.4` and `10 §8.4`, cited in
Sources and spelled out in §5.3; the skill budget is two auto-firing and the two above are the ones
that decide whether the **screen** is right rather than whether its strings are tidy.

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/settings_test.dart`
- **Test** — `'every setting on the screen round-trips through SettingsRepository'`
- **Why it is red today** — the repository exists and nothing renders it.

```bash
fvm flutter test test/features/settings_test.dart   # expect: failing, for the reason above
```

Sharpen the assertion so it cannot pass by rendering a list of labels. Drive it from the **same
`_Setting` table N12-T02 wrote**, or from a table of the same shape, and assert three things per row:

1. The screen renders a control whose widget key is `settings.<section>.<element>` and whose current
   state matches the stored value read straight out of `app_settings`.
2. Driving that control commits — `tester.tap()` (or the field's `enterText` + the field's own commit
   affordance), `await tester.pumpAndSettle()`, then read the **column**, not the widget.
3. There is **no second writer**: after the interaction, `settingsProvider` has emitted again and the
   control's new state came from that emission rather than from local widget state. Set the column
   directly in the test, pump, and assert the control follows.

Assert the section list's length against `07 §14.3`'s twelve with **one** documented exclusion, so the
count is derived rather than remembered:

```dart
expect(kSettingsSections.length, 11,
    reason: '07 §14.3 lists twelve; Unlock (9) is N30-T05 — see the ledger in settings_screen.dart');
```

**Green.** The minimum code that passes, and nothing beyond it — the screen over the existing repository, section by section.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.0 The check this task opens with

**`lib/features/settings/settings_screen.dart` may already exist on this branch.** Two earlier tasks
say they *edit* it and no task says it creates it:

- N23-T02 — *"`lib/features/settings/settings_screen.dart` — **Edit.** The Settings ▸ Data row that
  opens it. §14.3 row 11, §14.4's 4-tap budget"*
- N23-T03 — *"`lib/features/settings/settings_screen.dart` — **Edit.** The Diagnostics line that shows
  the counts"*

```bash
ls -l lib/features/settings/
git log --oneline -- lib/features/settings/settings_screen.dart
```

If the file exists, **compose over it**: keep the Data row and the sweep line exactly where N23 put
them, slot them into sections 11 and 10, and do not re-create the file. If it does not, create it and
say so in the commit message — N23's two rows were retroactively wrong and the next reader deserves
one sentence rather than a rediscovery. Either way this is one line of commit message, decided once.

### 5.1 The files, in `00-README` §8 order

**Steps 5 (controllers), 6 (UI), 7 (ARB) and 8 (tests).** No schema — every column exists and was
frozen at N07-T08. No domain — nothing is computed. No data step — `SettingsRepository` was written at
N12-T02 and this task adds no verb to it. **Say all three out loud in the commit message.**

| # | File | What changes in it, and why |
|---|---|---|
| 1 | `lib/features/settings/settings_controller.dart` | **New.** `SettingsController extends Notifier<SettingsState>` plus `settingsControllerProvider` (`CONVENTIONS` §3.4). Screen state only: which section is expanded, which sheet is open, which field is focused. **No data** — the values come from `settingsProvider`, watched in the widget |
| 2 | `lib/features/settings/settings_write_controller.dart` | **New or Edit.** `SettingsWriteController extends WriteController` plus `settingsWriteControllerProvider` (`NotifierProvider.autoDispose`). One method per settable thing, each a `guard()`ed call into `SettingsRepository`. N23-T02 may already have put `restore` here; keep it and add beside it |
| 3 | `lib/features/settings/settings_screen.dart` | **New or Edit** (§5.0). `SettingsScreen extends ConsumerWidget`. The `kSettingsSections` list, the page header, the eleven section bodies, the four states §14.2 permits |
| 4 | `lib/features/settings/widgets/settings_section.dart` | **New.** The one section shell every section uses: `ShedSectionHeading` (`headingLevel: 2`) over a column of ruled rows. One widget, eleven call sites — a section that hand-rolls its own heading is a section that forgets the heading level |
| 5 | `lib/features/settings/widgets/pen_settings_section.dart` | **New.** Section 5. Rename a pen, deactivate a pen, and the turn-out threshold field. Reaches `PenRepository` and `SettingsRepository.setTurnOutThresholdHours` |
| 6 | `lib/routing/routes.dart` | **Edit.** `Routes.settings(BuildContext context, {bool focusUnlock = false})`. `RouteNames.settings` already exists — this file has declared thirteen names since N13-T01. **Do not add a fourteenth** |
| 7 | `lib/l10n/app_en.arb` | **Edit.** Every string this screen renders, each with a `description`. Eleven section titles, the Reminders and Pens rows, the six state strings |
| 8 | `test/features/settings_test.dart` | **New.** The anchor, the section-count self-check, the state cases and the friction cases. T02–T07 append to this file |

Nothing under `lib/data/`, nothing under `lib/domain/`, nothing under `lib/core/`. If a repository verb
appears in this diff, a section has reached past the frame.

### 5.2 The signatures

```dart
// lib/features/settings/settings_screen.dart
//
// SECTION LEDGER — 07 §14.3 lists TWELVE sections. This screen renders ELEVEN.
//
//   1  Units            N29-T02      7  Keep screen on   N29-T04
//   2  Terminology      N29-T03      8  Left-handed      N29-T04
//   3  Reminders        HERE (row -> N25's editor + requestAlerts)
//   4  Season           N29-T05      9  Unlock           *** N30-T05 ***
//   5  Pens             HERE        10  Diagnostics      N29-T07 (+ N23-T03's sweep line)
//   6  Appearance       N29-T04     11  Data             N23-T02 (restore) + N29-T06 (deletes)
//                                   12  About            N29-T07
//
// Section 9 is absent, not stubbed: purchaseServiceProvider (N30-T01) and
// entitlementProvider (N30-T02) do not exist, and a section rendering an offer
// over a provider that does not exist is a lie that compiles.
enum SettingsSection { units, terminology, reminders, season, pens, appearance,
                       keepScreenOn, leftHanded, diagnostics, data, about }

/// Order is 07 §14.3's, with `unlock` absent. The screen iterates this list;
/// the self-check in the test asserts its length and its order.
const List<SettingsSection> kSettingsSections = SettingsSection.values;

final class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) { … }
}
```

```dart
// lib/features/settings/settings_controller.dart
/// Screen state, never data (CONVENTIONS §4.4 rule 1). The VALUES live in
/// app_settings and arrive through settingsProvider; this holds what the
/// SCREEN is doing.
final class SettingsState {
  const SettingsState({this.openSheet, this.focusUnlock = false});
  final SettingsSection? openSheet;
  final bool focusUnlock;          // set by Routes.settings(focusUnlock: true) — N30-T05 reads it
}

final class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();
  void openSheet(SettingsSection s);
  void closeSheet();
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
```

```dart
// lib/features/settings/settings_write_controller.dart
/// EVERY mutation on this screen goes through guard() (02 §7.1). It refuses to
/// run concurrently, which is the double-tap defence on a screen where one of
/// the taps destroys a season.
final class SettingsWriteController extends WriteController {
  @override
  WriteState build() => const WriteIdle();

  Future<void> setTurnOutThresholdHours(int hours);
  Future<void> renamePen(PenId pen, String label);
  Future<void> deactivatePen(PenId pen);
  Future<void> turnOnAlerts();          // -> NotificationScheduler.requestAlerts() (08 §8.2)
  // T02..T07 add one method each. There is no setAll(), no apply(), no commit().
}

final settingsWriteControllerProvider =
    NotifierProvider.autoDispose<SettingsWriteController, WriteState>(
        SettingsWriteController.new);
```

```dart
// lib/routing/routes.dart — an ARGUMENT on the existing helper (11 §5), never a
// fourteenth RouteNames entry.
static Future<void> settings(BuildContext context, {bool focusUnlock = false}) =>
    Navigator.of(context).push(_route(
      RouteNames.settings,
      (_) => const SettingsScreen(),
    ));
```

Widget keys, R59 spelling, read by T02–T08 and by N33's four sweeps — spell them once, correctly:

```
settings.title                       settings.section.units
settings.section.terminology         settings.section.reminders
settings.reminders.intervals         settings.reminders.turn_on_alerts
settings.section.season              settings.section.pens
settings.pens.rename.3               settings.pens.deactivate.3
settings.pens.turn_out_threshold     settings.section.appearance
settings.section.keep_screen_on      settings.section.left_handed
settings.section.diagnostics         settings.section.data
settings.section.about
```

`settings.pens.rename.3` keys on `PenId(3)`, not on a label: N19-T06 makes the same point in reverse —
a pen label is renameable **from this screen**, so keying on it silently moves a test contract the day
someone renames pen 3 to "Shed A".

### 5.3 The details that are easy to get wrong

- **Settings is `07-screens.md` §14, not §13.** §13 is Export. Every pre-deepening task file in this
  folder cited §13; a developer who opened it would have written the Export screen a second time. The
  same correction applies to the wakelock: it is `08 §7`, not §6.
- **The Empty state is impossible and must not be written.** `07 §14.2`: *"`app_settings` has
  `CHECK (id = 1)` and every column has a default, so the row exists from `onCreate`. **A settings
  screen with no settings is a bug, not a state.**"* An `if (rows.isEmpty) return ShedEmptyState(...)`
  branch here is dead code that will be *maintained* for three seasons.
- **Frame 1 paints every label and every control at its stored-default position.** `07 §14.2`: *"the
  sections are static, only the values wait. **No shift when the row lands.**"* That means the section
  list is built from `kSettingsSections` — a `const` — and only the *values* read `settingsProvider`.
  Building the list inside an `AsyncData` arm makes the whole screen pop in, which is the jank the
  first-frame work in N11 exists to prevent.
- **There is no spinner, anywhere, ever** (decision #71; `ui.spinner` bans
  `CircularProgressIndicator` under `lib/features/`). The not-yet-loaded value renders as the stored
  default, because that is what it will be.
- **The Error state replaces the *section list only*.** `07 §14.2`: *"Diagnostics stays reachable,
  because a database read failure is exactly when someone needs it."* Wrapping the whole `Scaffold`
  body in the standard panel is the natural implementation and it removes the one button a shepherd
  with a broken database needs. Diagnostics is section 10 and it is T07's, but the **layout decision**
  that keeps it outside the panel is this task's.
- **`headingLevel: 2` on every section heading, `1` on the screen title, and `header: true` nowhere.**
  `Semantics(header: true)` is a **no-op on both platforms as of 3.44** (`10 §3.4`) — it compiles, it
  reads correctly in review, and it does nothing. `a11y.header_bool` fails the build on it. `10 §3.4`'s
  table gives Settings *"one per settings group"*, which is eleven level-2 nodes here and a twelfth
  when N30-T05 lands.
- **Two controllers, never one** (`CONVENTIONS` §3.4, §4.4 rule 1). The screen controller holds screen
  state; the write controller holds `guard()`. A single `SettingsController` with both is the shape
  every settings screen in every other app has, and it is the shape that lets a second tap run a second
  write.
- **The controller never formats, never navigates and never holds a `BuildContext`** (`02 §6`), and
  `ref.watch(settingsProvider.select((s) => s.<column>))` is per row, not once for the screen.
  Eleven sections over one `StreamProvider` means one column change rebuilds eleven sections without
  `.select` — the difference between a frame and three at 200% text scale on a 375 pt device.
- **No `AsyncValue` accessor.** `.value`, `.valueOrNull`, `.requireValue`, `.hasValue` and `.asData`
  are banned (`02 §2.2`); four are grepped. Pattern-match: `AsyncData(:final value) => …`, with
  `AsyncError()` and `AsyncLoading()` both named and no `default:`.
- **`Routes.settings` takes `focusUnlock` and does not add a route.** `11 §5` is explicit: it is *"an
  argument on an existing push helper — **not** a fourteenth `RouteNames` entry."* T08's self-check
  asserts thirteen. Adding one here breaks the matrix in the epic that completes it.
- **Every non-destructive setting is ≤ 2 taps from this screen** (`07 §14.4`). That prices the design:
  a section that opens a sheet that opens a second sheet is three. `ShedBottomSheet` is the only
  overlay (`indelible.md` §7.14), it is one level deep, and it closes on an explicit `tapPrimary`
  Cancel — `showDragHandle: false`, `enableDrag: false`, `isDismissible: false`, all three typed
  because all three Flutter defaults are the permissive one (`07 §20` rule 3).
- **Back is a bottom-bar button, not only the AppBar chevron** (`07 §20` rule 2). On a 6.7" phone the
  chevron is the furthest point from a right thumb's pivot.
- **Nothing on this screen watches `entitlementProvider` or `purchaseServiceProvider`.** Neither exists
  yet, and after N30 the rule still holds for ten of the eleven sections (`07 §19.2`: the affordance
  exists in exactly two places, and one of them is section 9).
- **The Reminders row reaches N25's editor; it does not re-implement it.** `RouteNames` has thirteen
  entries and none is `reminder_intervals`. The row is a `ShedTapTarget` that pushes
  `Routes.reminders(context)`; the interval editor is a section on **that** screen (N25 epic, risk 5).
- **"Turn on lock-screen alerts" is one of exactly two permitted call sites for
  `NotificationScheduler.requestAlerts()`** (`08 §8.2`): *"an explicit tap on 'Turn on alerts'
  (Reminders) or Settings ▸ Reminders. **Never** from `initialize()`, from a write path, at first
  launch, mid-lambing."* Calling it when the section builds is the defect — it turns opening Settings
  into a permission dialog.
- **The Pens section is this screen's, and it is small.** `07 §9.5`: rename lives *"in the sheet and in
  Settings ▸ Pens"*, and the turn-out threshold is *"not on this screen; it is a season-level
  preference, not a 3am decision."* `07 §14.3` row 5 adds bulk add and reorder — **reorder is a drag
  and drag is banned outright**. Implement reorder as a pair of `ShedTapTarget` move controls or leave
  it out and record which; do not reach for `ReorderableListView`, which is a `Draggable` under a
  different name and a `check_policy` row.
- **The turn-out threshold is a display threshold, never a recommendation** (`03 §5.13`, and the reason
  is written into the schema itself). `CHECK (turn_out_threshold_hours BETWEEN 1 AND 336)`: 0 and 337
  are `WriteFailed`, never clamped to 1 and 336. The label is the user's own number played back —
  `10 §8.4`'s `penReadyThreshold` description says why.
- **There is no SnackBar** (P2, `CLAUDE.md`, superseding `CONVENTIONS` §2.11). The receipt for a
  setting is **the row, re-printed with its new value**, which arrives through `settingsProvider`'s next
  emission. A settings screen with eleven toasts is the anti-pattern this ruling exists to prevent.
- **No `Save`, no `Apply`, no `Done`.** Every write commits immediately (`CLAUDE.md` non-negotiable 4).
  `db.save_verb` fires on `save\w*(` under `lib/data/`, and an ARB button key starting with `save`
  fails the build too (`07 §15.5`).
- **`lib/features/settings/` may not import `lib/features/export/` or any other sibling** (layer rule
  6). That is why N23-T02 put the live-count read on `ExportRepository` rather than reaching for
  `exportCountsProvider`, and it is the same rule that will bite T06.

### 5.4 The full test set

`test/features/settings_test.dart` — created here, appended to by T02 through T07.

| Case | What it asserts |
|---|---|
| `'every setting on the screen round-trips through SettingsRepository'` | **The anchor.** Table-driven over the `_Setting` rows: the control reflects the column, driving the control writes the column, and setting the column moves the control |
| `'the section list is 07 §14.3's order with Unlock absent'` | `kSettingsSections` equals the eleven, in order; length asserted with the `reason:` naming N30-T05 |
| `'frame one paints every section label with no value loaded'` | Pump with a `databaseProvider` that never completes; every section heading is found; no exception; no `CircularProgressIndicator` anywhere |
| `'the section list does not shift when the settings row lands'` | Record each heading's `Rect` at frame 1, complete the database, pump, and assert every `Rect` is unchanged (`07 §14.2`) |
| `'the empty state does not exist on this screen'` | `find.byType(ShedEmptyState)` is `findsNothing` against a database seeded by `seedFirstRun` — and there is no other database this screen can have |
| `'a read error replaces the section list and leaves Diagnostics reachable'` | Force the read into `AsyncError`; the panel renders; `settings.section.diagnostics` is still hit-testable |
| `'the screen title is headingLevel 1 and every section heading is headingLevel 2'` | Semantics walk. Eleven level-2 nodes; zero nodes with `header: true` |
| `'every interactive element is at least 60 x 60, carries a semanticLabel, and is keyed settings.<section>[.<element>]'` | `tester.getRect` against `context.tokens.tapMin`, a semantics walk, and the R59 key shape. Indelible builds 64; 60 is the floor |
| `'no non-destructive setting is more than two taps from this screen'` | Walk the eleven sections; each either commits in one tap or opens exactly one sheet whose control commits in the second (`07 §14.4`) |
| `'no banned gesture is bound anywhere on the screen'` | Source text over `lib/features/settings/`: `Dismissible`, `Draggable`, `Tooltip`, `InteractiveViewer`, `onLongPress:`, `Slider`, `ReorderableListView` — all zero |
| `'nothing on the screen watches the entitlement or the store seam'` | `entitlementProvider` and `purchaseServiceProvider` appear nowhere under `lib/features/settings/`; and neither exists yet, so the case is a source-text one |
| `'Turn on alerts does not request a permission until it is tapped'` | `FakeNotificationScheduler.calls` does **not** contain `requestAlerts` after the screen builds; it does after one tap (`08 §8.2`) |
| `'renaming a pen writes the pen row and re-renders the board's label'` | Rename `PenId(3)`; `pens.label` is the typed string; `penBoardProvider` emits the new label |
| `'the turn-out threshold refuses 0 and 337 and accepts 1 and 336'` | `WriteFailed` on both ends, stored value unchanged, nothing clamped (safety rule 4) |
| `'no SnackBar is shown for any setting change'` | `find.byType(SnackBar)` is `findsNothing` through every interaction (P2) |
| `'every string on this screen is an ARB message with a description'` | Source-text case over `app_en.arb`; no literal user-facing string in any file under `lib/features/settings/` |
| `'the screen renders without overflow at the smallest device and textScaler 2.0, bold'` | `Device.small` × 2.0 × bold. Eleven sections is the longest list in the app; this is the cell most likely to break, and T08 will run it thirty-six times |

## 6. Constraints that bind this task

- **3am** — every interactive element ≥ 64 × 64 with ≥ the ruled separation, 18 px text floor, dark only, and none of the banned gestures: no swipe, no drag, no long-press, no pinch, no slider.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **Every write commits immediately.** There is no settings draft, no Apply button and no `commit()`;
  each control is its own transaction through `guard()`.
- **§12.2 on this screen, stated once:** *"no section may recommend a value"* (`07 §14.5`). The
  turn-out threshold is the user's. The Pens section describes pens, not husbandry.
- **This screen is not on the shed-screen list** and the wakelock may never be held on it
  (`08 §7.1` condition 2 names Settings among the six that are excluded).

## 7. Definition of Done

- [ ] `'every setting on the screen round-trips through SettingsRepository'` passes, and was seen to fail first for the stated reason
- [ ] no second `app_settings` writer is introduced
- [ ] every control is at least 64 × 64
- [ ] the screen is not on the shed-screen list
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] the commit message records whether `settings_screen.dart` already existed (§5.0) and states that the schema, domain and data steps are all skipped
- [ ] `kSettingsSections` holds eleven sections in `07 §14.3`'s order, and the ledger comment names N30-T05 as section 9's home
- [ ] the screen title emits `headingLevel: 1`, every section heading emits `2`, and `header: true` appears nowhere
- [ ] `settingsControllerProvider` and `settingsWriteControllerProvider` both exist; neither holds data and neither holds a `BuildContext`
- [ ] every row reads `settingsProvider.select(...)`, and no `AsyncValue` accessor appears in the diff
- [ ] `RouteNames` still declares exactly thirteen entries; `focusUnlock` is an argument on `Routes.settings`
- [ ] `NotificationScheduler.requestAlerts()` is called from a tap and from nowhere else
- [ ] `ReorderableListView` appears nowhere, and the reorder decision is recorded in the commit message
- [ ] `find.byType(SnackBar)` is `findsNothing` in every case in the file
- [ ] `kPumpableVariants` is **not** touched — that is T08's

## 8. Verification

```bash
fvm flutter test test/features/settings_test.dart
make check
make test
```

```bash
grep -rn "showSnackBar(\|SnackBar(" lib/features/settings/          # expect zero (P2)
grep -rn "header: true" lib/                                        # expect zero (10 §3.4)
grep -rn "CircularProgressIndicator\|ReorderableListView" lib/features/settings/   # expect zero
grep -rn "Dismissible\|Draggable\|Tooltip\|onLongPress\|Slider(" lib/features/settings/  # expect zero
grep -rn "valueOrNull\|requireValue\|hasValue\|asData" lib/features/settings/      # expect zero
grep -rn "features/export/\|features/pens/pen_board_controller" lib/features/settings/  # layer rule 6
grep -c "static const" lib/routing/routes.dart                      # RouteNames: still 13
grep -rn "entitlementProvider\|purchaseServiceProvider" lib/features/settings/     # expect zero
grep -rn "kPumpableVariants" test/support/harness.dart              # unchanged by this task
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(settings): the screen over the repository built in N12`
