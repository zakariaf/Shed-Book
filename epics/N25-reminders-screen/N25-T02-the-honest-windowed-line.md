# N25-T02 — The honest windowed line

| | |
|---|---|
| **Epic** | [N25 — Reminders screen](epic.md) · `00-README` §9 step 9 (2 of 2) |
| **Task** | 2 of 6 |
| **Depends on** | N25-T01 · N24-T01 |
| **Commit** | one commit · `feat(reminders): the honest windowed line, both numbers from data` |

## 1. Why this task exists

*"56 of 312 reminders are on your phone's list."* **Both numbers read from data** — the
budget from `ReminderBudget.forPlatform()` and the count from the rows — and never a hard-coded 56. This
line is the product being honest about a platform limit instead of pretending it does not exist.

07 §17.4 states what it is for: *"Without it, the first symptom of the 64-request ceiling is a lamb that
does not get tubed, and there is no screen anywhere that could have told the shepherd why."*

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/07-screens.md` | §11.2 | the three conditions and their copy, and the fixed-height box |
| `docs/engineering/07-screens.md` | §17.3 | the five rules the line obeys, including "never write *some reminders may not fire*" |
| `docs/engineering/07-screens.md` | §11.5 | the permission is **never** requested from a write path |
| `docs/engineering/08-platform-integration.md` | §2.13 | the two facts that make the line honest |
| `docs/engineering/08-platform-integration.md` | §2.2, §2.4 | `ReminderBudget`'s body; why the two numbers use different predicates |
| `docs/engineering/08-platform-integration.md` | §2.3, §8.2 | `alertsGranted()` / `requestAlerts()` — the only permission call in the app |
| `docs/engineering/03-data-model-and-schema.md` | §5.13 | `app_settings.last_reconcile_scheduled`, nullable, written by `reconcile()` |
| `docs/engineering/CONVENTIONS.md` | §2.14, §3.1, R29, R40, R50 | `ReminderBudget`, `settingsProvider : StreamProvider<AppSetting>` |
| `shed-book-spec.md` | §7.6 | due today, overdue, upcoming |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-accessibility-and-copy` | the wording, and what an honest limitation reads like |
| `shed-platform-gateways` | the budget and the projection it describes |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/reminders_test.dart`
- **Test** — `'the windowed line reads both numbers from data and never a literal 56'`
- **Why it is red today** — nothing states the gap, and the obvious implementation hard-codes the iOS number.

The assertion, sharpened: seed 312 open unmuted reminders, write
`app_settings.last_reconcile_scheduled` with `scheduled = ReminderBudget.forPlatform()`, pump, and assert
the rendered text contains **both** `'${ReminderBudget.forPlatform()}'` and `'312'` — the budget as a
*call*, never as the literal `56` or `200`. Then set `scheduled` equal to `schedulable_total` and assert
the copy switches to the "all N are on your lock screen" form with no layout shift.

```bash
fvm flutter test test/features/reminders_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the line, both numbers from data, and a source assertion that no literal 56 exists in the
feature.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 Files touched, in `00-README` §8's order

| §8 step | File | What changes, and why |
|---|---|---|
| 1–3 | **skipped** | `last_reconcile_scheduled` was added by R40 and shipped in N07; `ReminderBudget` is N24-T01's; `recordProjection()` is N24-T05's. Nothing new is stored, computed or written here |
| 5 — controllers | `lib/features/reminders/reminders_controller.dart` | `RemindersState` gains `alertsGranted`; `RemindersController` gains `refreshAlerts()` and `turnOnAlerts()`. **Screen state, never data** (§4.4 rule 1) |
| 6 — UI | `lib/features/reminders/widgets/reconcile_line.dart` | **new.** `ReconcileLine` — the fixed-height box and its exhaustive three-way switch |
| 6 — UI | `lib/features/reminders/reminders_screen.dart` | mount `ReconcileLine` above the three groups; add the "app only" chip to rows beyond the window |
| 6 — ARB | `lib/l10n/app_en.arb` | three messages with `int` placeholders, one button label, one chip label — each with a `description` naming §17.3 |
| 7 — tests | `test/features/reminders_test.dart` | the anchor plus §5.4's cases |
| 7 — tests | `test/policy/reminder_budget_is_never_a_literal_test.dart` | **new.** a source scan; policy tests are named for the *property* (§4.1) |

### 5.2 The signatures

```dart
// lib/features/reminders/widgets/reconcile_line.dart
//
// 07 §17.3 rule 2: the box is the SAME HEIGHT in all three states, so the list
// below never shifts. That is a layout requirement, not a nicety — a shepherd
// reading the first overdue row must not have it move under their thumb when
// the reconcile lands.
enum ReconcileLineState { windowed, complete, alertsOff }

class ReconcileLine extends ConsumerWidget { … }
```

The three states, resolved by an exhaustive `switch` over three facts and nothing else:

| Fact | Where it comes from |
|---|---|
| `stored` | `RemindersView.schedulableTotal` — the query's own `schedulable_total` (T01) |
| `scheduled` | `AppSetting.lastReconcileScheduled`, via `settingsProvider` (`StreamProvider<AppSetting>` — the **row** class; `appSettingsProvider` is banned, R29) |
| `alertsGranted` | `RemindersState.alertsGranted`, filled by `RemindersController.refreshAlerts()` calling `NotificationScheduler.alertsGranted()` |

```dart
// lib/features/reminders/reminders_controller.dart
final class RemindersController extends Notifier<RemindersState> {
  /// Reads the OS. Called on screen entry and on AppLifecycleState.resumed —
  /// the user can grant or revoke alerts in system Settings while we are
  /// backgrounded, so a cached value goes stale (08 §2.14).
  Future<void> refreshAlerts();

  /// The ONLY permission request in this feature, and it is reachable only from
  /// an explicit tap on "Turn on alerts" (07 §11.5). Never from a write path.
  /// After it resolves, reconcile() runs so the OS list fills immediately.
  Future<void> turnOnAlerts();
}
```

The copy, from 07 §11.2 — `{scheduled}` and `{stored}` are ARB `int` placeholders, never interpolated
literals:

| Condition | Message |
|---|---|
| `stored > scheduled` | "Showing the next {scheduled} reminders on your lock screen. All {stored} are stored in the app." |
| `stored == scheduled` | "All {stored} reminders are on your lock screen." |
| alerts not granted | "Lock-screen alerts are off. All {stored} reminders are stored in the app." + an 88 pt (`tapHero`) **"Turn on alerts"** |

Widget keys: `reminders.reconcile_line`, `reminders.turn_on_alerts`, `reminders.row.<id>.app_only`.

### 5.3 The details that are easy to get wrong

- **`ReminderBudget.forPlatform()` uses `dart:io`'s `Platform`, so a host test can never see the iOS
  branch.** On `ubuntu-latest` and on a developer's Mac, `Platform.isIOS` is false and `forPlatform()`
  returns **200**. Never assert `find.text('56')` or `find.text('200')` — assert against the *call*:
  `find.textContaining('${ReminderBudget.forPlatform()}')`. A test that hard-codes 56 is red on CI; a test
  that hard-codes 200 passes on CI and asserts nothing about iOS. The iOS/Android split itself is
  N24-T01's `test/domain/reminder_budget_test.dart`.
- **The screen never writes `last_reconcile_scheduled`.** It is written by
  `SettingsRepository.recordProjection()` inside `reconcile()`, in the same transaction that records the
  projection, so it stores **what was projected** and not what was intended (08 §2.4, §2.13 fact 1). The
  moment a widget writes it, the line stops being honest and starts being a hope.
- **Nullable is a real state and it is not zero.** `last_reconcile_scheduled` is nullable because "never
  reconciled" is a genuine condition (03 §5.13). `?? 0` on it produces "Showing the next 0 reminders on
  your lock screen" on first run, which is both wrong and alarming. First run, before any reconcile, is
  the alerts-off branch — because alerts genuinely are off until the shepherd taps.
- **The two numbers apply deliberately different predicates, and the difference is not a bug.**
  `schedulable_total` counts `completed_at IS NULL AND muted = 0`. The projection adds `due_at > :after`,
  so it excludes overdue rows — Android's `AlarmManager` fires a past trigger *immediately*, and twelve
  overdue reminders would be twelve pings in one second on every resume (08 §2.4). "Stored in the app" and
  "on your lock screen" are different claims and that is the whole point of the line. What must stay
  **byte-identical** between the two is `completed_at IS NULL` and `muted = 0`.
- **`scheduled` can legitimately exceed what the current query counts**, briefly: the reconcile ran, then
  the shepherd completed four reminders. The `stored > scheduled` / `stored == scheduled` switch must have
  a defined arm for `scheduled > stored` — fold it into the `==` arm ("All {stored} reminders are on your
  lock screen"), never render a negative difference, and never render "56 of 12".
- **`settingsProvider` is a legitimate second watch.** 07 §1.2 permits app-level singletons alongside the
  one content statement. It is a singleton row lookup, not a second content stream, so this is not a
  `combineLatest`.
- **Never write "some reminders may not fire."** 07 §17.3 rule 4: they will fire; they are simply not on
  the lock screen yet, and they enter the window as nearer ones are completed. The banned sentence is the
  one a well-meaning developer writes to be safe, and it is the one that makes a shepherd stop trusting
  the app.
- **The permission is never requested from a write path** (07 §11.5, narrowing decision #65). Reminder
  rows are created automatically inside lambing and treatment transactions, so a literal reading of #65
  would put a system dialog on screen at 03:24 during the first lambing. `requestAlerts()` is reachable
  from exactly two taps in the whole app: this screen's button and Settings ▸ Reminders.
- **Rows beyond the window carry an "app only" chip: icon **plus** the words, never colour alone**
  (07 §17.3 rule 3, decision #106). Which rows those are is `due_at > now` ordered ascending, sliced at
  `scheduled` — the same slice `reconcile()` used.
- **The chip and the line are not a badge count.** Indelible: *"there is no badge count anywhere in the
  app."*
- **`showCapRow` is not involved.** 07 §11.3's over-cap row reads *"Nothing"* — whether the free tier caps
  reminders is §7.1 open question 17 and it changes the reconcile budget, not this screen.

### 5.4 The full test set

`test/features/reminders_test.dart`

| Case | What it holds |
|---|---|
| `'the windowed line reads both numbers from data and never a literal 56'` | **the anchor**, §4's assertion |
| `'all-scheduled renders the second form and the box does not change height'` | 07 §17.3 rule 2; measure the box in both states |
| `'alerts off renders the third form, a full list, and a tapHero Turn on alerts'` | 07 §11.3: "the list is fully populated regardless" |
| `'a null last_reconcile_scheduled never renders a zero'` | the `?? 0` trap |
| `'scheduled greater than stored renders the all-scheduled form, never a negative'` | the completion race |
| `'rows beyond the window carry an app-only chip with an icon and words'` | decision #106 |
| `'the copy contains no sentence about reminders that may not fire'` | 07 §17.3 rule 4, asserted on the rendered text |
| `'no permission call is made on screen entry'` | `FakeNotificationScheduler.calls` contains `alertsGranted` and **not** `requestAlerts` |
| `'tapping Turn on alerts requests once and then reconciles once'` | the two-call sequence, in order |
| `'the reconcile line is not a live region'` | 10 §3.8 lists the only three; this is not one |

`test/policy/reminder_budget_is_never_a_literal_test.dart`

| Case | What it holds |
|---|---|
| `'no budget literal appears in lib/features/ or in the ARB'` | scans `lib/features/**.dart` and `lib/l10n/app_en.arb` for `\b56\b` and `\b200\b`; the only permitted occurrence of either number in the app is `lib/domain/reminder_budget.dart` |

A source-scanning test rather than a new `tool/check_policy.dart` row on purpose: `check_policy.dart` is
N01's file and the gate's rule table is a cross-epic edit. If the owner wants it mechanised in `gate`
instead, the row id is `copy.budget_literal` and it belongs in N33.

### 5.5 Verification

```bash
fvm flutter test test/features/reminders_test.dart
fvm flutter test test/policy/reminder_budget_is_never_a_literal_test.dart
rg -n '\b56\b|\b200\b' lib/features/ lib/l10n/app_en.arb   # expect: no matches
rg -n 'may not fire' lib/l10n/app_en.arb                   # expect: no matches
rg -n 'requestAlerts' lib/                                 # expect: the gateway + one controller method
make check
make test
```

## 6. Constraints that bind this task

- **§12.3 and §12.2 both bind the copy.** The line states a platform fact about the shepherd's own phone.
  It may not imply the app is a record anybody is obliged to keep, and it may not originate a number —
  both numbers are read, one from `app_settings`, one from the query.
- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name. **`reconcile`, never `schedule`, `sync` or `refresh`** on the projection (R51); **`projection`, never `queue` or `cache`, in copy** (§5.2).

## 7. Definition of Done

- [ ] `'the windowed line reads both numbers from data and never a literal 56'` passes, and was seen to fail first for the stated reason
- [ ] both numbers from data
- [ ] no literal budget number in `lib/features/`
- [ ] the line renders on Android too, with its own number
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
3. **Commit** — `feat(reminders): the honest windowed line, both numbers from data`
