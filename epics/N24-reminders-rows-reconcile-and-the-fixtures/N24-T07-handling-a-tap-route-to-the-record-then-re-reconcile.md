# N24-T07 — Handling a tap — route to the record, then re-reconcile

| | |
|---|---|
| **Epic** | [N24 — Reminders: rows, reconcile and the fixtures](epic.md) · `00-README` §9 step 9 (1 of 2) |
| **Task** | 7 of 8 |
| **Depends on** | N24-T06 |
| **Commit** | one commit · `feat(reminders): route a tapped reminder to its record` |

## 1. Why this task exists

A tapped notification resolves its payload to a `ReminderId` — **the record** — and then reconciles,
because the tap consumed one of the projected slots and the 57th reminder can now enter the window.
That is reconcile **call site #4**, the last of the four, and without it the OS list only refills on
the next launch or resume.

> 🚩 **One destination, and it is the Reminders screen** (`08 §2.12`). A tap pushes
> `RouteNames.reminders` through `Routes.navigatorKey` and **does not read the database on the tap
> path** to work out which animal to open — that is an async hop before the first paint, on the one
> path where the phone has been asleep, to save a tap the shepherd is about to make anyway. "The
> record" in this task's title is the **reminder** record, on that screen. If you find yourself
> resolving a `ReminderId` to a `LambingId` inside the tap handler, stop.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/08-platform-integration.md` | **§2.12** (the three cases — foreground, cold launch, and *no notification actions in v1*) · §2.5 (the payload is `reminder:<id>` and carries nothing else) · §2.3 (`launchTapTarget()`, read once during the boot kick) · §2.4 (call site #4 — *"the 57th reminder can now enter the window"*) | the whole tap path, and the one destination |
| `docs/engineering/02-state-di-navigation.md` | **§8.1** (`Routes.navigatorKey`, `_route`, `RouteSettings(name:)`, and *"never for `pushNamed`"*) · §8.4 (*"navigate through `Routes.navigatorKey` for the two context-free cases: notification tap, resume policy"*) · §9.1 (the `State` that already holds the boot kick and the lifecycle observer) | how a context-free navigation is spelled here |
| `docs/engineering/07-screens.md` | §11.4 (completing a reminder is a **tap on the row**, then a reconcile — not something the notification tap does) · §17.2 (the four call sites) | what the tap does *not* do |
| `docs/engineering/CONVENTIONS.md` | §2.1 (`ReminderId`) · §3.5 / R33 (a bare `int` never crosses a boundary) · §4.5 (widget keys) · §2.14 (`RouteNames`, `Routes`) | the id type and the navigation surface |
| `docs/engineering/12-testing.md` | §4.3 (`launchTapTarget()` returns `null` in the fake by default — a test that wants a cold tap sets it) · §5.1 (`pumpApp`) | how a tap is driven in a test |
| `docs/research/00-tech-decisions.md` | **§5 only** for versions · **#21** (nothing before `runApp()`) · #63 (call site #4) · #24 (no state restoration) | why the cold read is post-frame |
| `epics/N13-quick-entry-the-deck-and-the-keypad/N13-T01-routesdart-thirteen-names-one-helper-and-the-p3-ruling.md` | §5.2 (*"each screen epic adds its own `Routes.<screen>` push helper in the commit that adds the screen"*) · §5.4 (`popToQuickEntryGlobal` — *"the resume policy's and the future notification tap's only path"*) | why the push is deferred, and to which task |
| `epics/N25-reminders-screen/N25-T01-remindersprovider-and-remindersview-three-groups-off-the-tic.md` | §5.1 row 6 (*"add the push helper `Routes.reminders(BuildContext)`"*) | the task that closes the one line this task leaves open |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-screens-and-routing` | the deep route and the navigator key |
| `shed-platform-gateways` | the payload and the re-reconcile |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/features/reminders_test.dart`
- **Test** — `'a tapped reminder routes to its record and triggers exactly one reconcile'`
- **Why it is red today** — a tap opens the app and does nothing.

```bash
fvm flutter test test/features/reminders_test.dart   # expect: failing, for the reason above
```

Sharpen both halves:

- **"routes to its record"** — assert the resolved value, `parseReminderPayload('reminder:42')`, equals
  `ReminderId(42)`, and that the navigation request names `RouteNames.reminders`. It does **not** assert
  that a `RemindersScreen` appeared: that widget and its push helper are N25-T01's (§5.3).
- **"exactly one reconcile"** — count, do not merely check presence:
  `expect(fake.calls.where((c) => c == 'cancelAll'), hasLength(1))`. A cold-launch tap fires call
  site #4 *and* call site #1 within milliseconds, and the 500 ms debounce is what collapses them. If
  this assertion reads two, the debounce is broken and every resume in the app costs a double
  projection.

**Green.** The minimum code that passes, and nothing beyond it — the payload route, the navigator key from N13-T01, and the single reconcile.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

### 5.1 The files, in `00-README` §8's order

| §8 step | File | What changes in it, and why |
|---|---|---|
| 3 — data | `lib/data/notification_scheduler.dart` | **Edit.** `initialize({required void Function(int reminderId) onTap})` wires `onDidReceiveNotificationResponse`; `launchTapTarget()` wraps `getNotificationAppLaunchDetails()`; and the top-level `ReminderId? parseReminderPayload(String? payload)` — **public**, so the test can call it without a plugin |
| 6 — root | `lib/app.dart` | **Edit.** `_handleReminderTap(int id)` — the one handler. The post-frame boot kick reads `launchTapTarget()` **once**, after the first frame |
| 7 — tests | `test/features/reminders_test.dart` | **New.** The anchor plus §5.5's cases. N25 extends this same file; do not create a second one |

Nothing under `lib/features/reminders/` changes: there is no screen there yet.

### 5.2 The signatures

```dart
// lib/data/notification_scheduler.dart
/// The payload is `reminder:<id>` and carries nothing else (08 §2.5). Public and
/// top-level so the tap path can be tested without a plugin, and so there is
/// exactly one parser — a second one is a second payload format.
///
/// Returns null for anything malformed, unknown or empty. A tap on a stale
/// notification must not throw on the launch path.
ReminderId? parseReminderPayload(String? payload);
```

```dart
// lib/app.dart — the same State that holds the boot kick and the lifecycle
// observer (02 §9.1). There is no separate notification file.
Future<void> _handleReminderTap(int reminderId) async {
  final id = ReminderId(reminderId);
  // 1. Navigate. Context-free: a notification tap has no BuildContext (02 §8.4).
  //    TODO(N25-T01): push RouteNames.reminders through Routes.navigatorKey.
  //    RemindersScreen and Routes.reminders(BuildContext) do not exist until
  //    N25-T01, which adds the helper in the commit that adds the screen
  //    (N13-T01 §5.2). Until then this handler resolves and reconciles, and
  //    N25-T01 deletes this comment when it lands the push.
  // 2. Reconcile — call site #4. The tap freed a slot; the 57th can enter.
  unawaited(
    ref.read(reminderReconcilerProvider.future).then((r) => r.reconcile()),
  );
}
```

The three cases, from `08 §2.12`:

| Case | Mechanism |
|---|---|
| Foreground, or backgrounded but alive | `onDidReceiveNotificationResponse`, wired in `initialize()` |
| Launched **by** the tap (cold) | `getNotificationAppLaunchDetails()`, read **once** inside the post-frame boot kick and never before `runApp()` |
| Notification action buttons | **None in v1.** No background isolate handler, no `@pragma('vm:entry-point')`, no second copy of the routing logic |

### 5.3 The one line this task deliberately does not write

`08 §2.12` says the tap *"pushes `RouteNames.reminders` through `Routes.navigatorKey`"*. The push
target does not exist yet: `RemindersScreen` is **N25-T01**, and N13-T01 ruled that *"each screen epic
adds its own `Routes.<screen>` push helper in the commit that adds the screen"* — N25-T01's file list
says so in as many words. Writing the push here means either constructing a widget that does not
compile, or inventing a second navigation helper that breaks `02 §8.1`'s checkable arithmetic
(thirteen names minus twelve helpers equals one, asserted in N33-T01).

So this task lands the **resolution** and the **reconcile**, and leaves the push as one
`TODO(N25-T01)` with the reason beside it — the same shape N23 used for its `TODO(N24)` post-restore
call site. Two obligations follow, and both are DoD lines:

1. The comment names the task, not just "later".
2. `test/features/reminders_test.dart` carries a case asserting the TODO exists and names N25-T01, so
   the ledger cannot be deleted as noise before it is honoured.

### 5.4 The details that are easy to get wrong

- **The destination is a list, and that is correct.** The task title says *"route to the record"*, and
  the record in question is the reminder row on the Reminders screen. `08 §2.12` is unambiguous:
  **one** destination, and the app does **not** read the database on the tap path to find the animal.
  Resolving to a `LambingId` or an `EweId` here adds an async hop before the first paint, on the one
  path where the phone has just woken up, to save a tap the shepherd is about to make anyway.
- **The cold read happens once, after the first frame.** `getNotificationAppLaunchDetails()` is read
  inside the post-frame boot kick, never before `runApp()`. `main()` awaits nothing (pre-commit
  decision #4, decision #21), and reading it in `main()` puts a platform-channel round trip in front of
  the first frame — the fifteen-second budget's most expensive possible millisecond.
- **Reading it twice is a double navigation.** `launchTapTarget()` is a one-shot: on Android the
  plugin's launch details persist for the process, so a second read on a later resume re-navigates to
  a reminder the shepherd dealt with an hour ago. Read once, in the boot kick, and never again.
- **"Exactly one reconcile" is a property of the debounce, not of the handler.** A cold launch fires
  call site #1 (boot) and call site #4 (tap) within milliseconds of each other. The 500 ms window is
  what makes them one projection; `_inFlight` is what makes two concurrent ones await the same future.
  Assert the count, not the presence.
- **The tap does not complete the reminder.** Completing is a tap on the row on the Reminders screen
  (N25-T03), and for `colostrum` and `navel` it writes the `CareEvent` — *it is the same tap*
  (decision #43). A notification tap that completed the reminder would silently record care that may
  not have happened, which is a §12.4 failure the app cannot detect.
- **A malformed or stale payload returns `null` and must not throw.** The reminder may have been
  completed, muted or deleted while the phone was in a pocket. The handler resolves nothing, navigates
  to the screen anyway (once N25-T01 lands the push), and the screen says what it knows. Throwing on
  the launch path takes down the first frame.
- **No action buttons in v1, and that is a design decision with teeth.** Adding one means a background
  isolate with no `ProviderScope`, a top-level `@pragma('vm:entry-point')` callback, and a second
  database connection — which is a design conversation, not an edit (`08 §2.12`).
- **Navigate through `Routes.navigatorKey`, never from a `Notifier`.** Controllers hold no
  `BuildContext` and never navigate (`CONVENTIONS §4.4` rule 3). `02 §8.4` names exactly two
  context-free cases: this one and the resume policy.
- **`pushNamed` is banned.** `RouteSettings(name:)` exists for the diagnostics log and
  `ModalRoute.withName`, and for nothing else. There is no `routes:` table and no `onGenerateRoute`.
- **A bare `int` crosses the plugin boundary and stops there.** `onTap` takes an `int` because that is
  what the OS hands back; it becomes a `ReminderId` in the first line of the handler and never travels
  further as an `int` (R33).
- **`unawaited(...)` is from `dart:async` and is deliberate**, not a slip — the same spelling `02 §9.1`
  uses at call site #2. Awaiting the reconcile inside the tap handler would block the navigation
  behind up to 204 platform-channel calls.
- **Nothing in this task is time-shaped**, so there is no new `uk-zone` case; the debounce is elapsed
  time and is driven through the binding's clock. Say so in the commit message.

### 5.5 The full test set

`test/features/reminders_test.dart` — the file N25 later extends; there is no second one

| Case | What it asserts |
|---|---|
| `'a tapped reminder routes to its record and triggers exactly one reconcile'` | **The anchor.** `parseReminderPayload('reminder:42') == ReminderId(42)`; exactly one `cancelAll` in `fake.calls` after the tap |
| `'a cold launch through launchTapTarget reconciles once, not twice'` | The fake returns a `ReminderId` from `launchTapTarget()`; boot (call site #1) and tap (call site #4) collapse into one projection through the debounce |
| `'launchTapTarget is read exactly once per process'` | The fake counts reads; a resume after the cold launch does not re-navigate |
| `'a malformed payload resolves to null and does not throw'` | `''`, `'reminder:'`, `'reminder:abc'`, `'lambing:42'`, `null` — five inputs, one `null` each, no exception |
| `'a tap on a stale reminder id resolves and does not throw'` | Id 999 with no row. §12.4: the app says what it knows rather than routing to nothing |
| `'the tap does not complete, mute or write anything'` | Row counts before and after are equal across `reminders`, `care_events` and `lambings` |
| `'the tap handler holds no BuildContext and no reference to a controller'` | Source text over `lib/app.dart` — `02 §8.4`'s rule, and the reason `Routes.navigatorKey` exists |
| `'pushNamed, onGenerateRoute and a routes: map appear nowhere under lib/'` | `02 §8.1`'s three anti-patterns, re-asserted because this is the first context-free navigation in the app |
| `'the tap path is wired in initialize() and nowhere else'` | Source scan: one `onDidReceiveNotificationResponse`, and no `@pragma('vm:entry-point')` anywhere in `lib/` |
| `'lib/app.dart carries a TODO naming N25-T01 for the push, with the reason'` | §5.3's ledger. The comment **is** the artefact, and a test that reads it is what stops it being deleted |
| `'parseReminderPayload is the only payload parser in the tree'` | Source scan for `'reminder:'` under `lib/`: two hits — where it is written (`project()`) and where it is read |

## 6. Constraints that bind this task

- **Accessibility and the ARB, authored here** — every string in `app_en.arb` with a `description`, every element a `semanticLabel` and a `<screen>.<element>` key, every heading a `headingLevel:`. There is no later sweep that adds them; N33 only verifies.
- **Offline** — no network path may be added. G2 (the dependency allowlist) and G3 (the import scan) stay green, and the permission set never changes without G0's recorded evidence.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.
- **The ARB rule binds negatively: this task renders nothing and authors no string.** The tap path has
  no UI of its own; every string a shepherd sees after the tap is N25's.
- **No permission is requested on this path.** A tap arrives *because* alerts are already granted;
  `08 §2.8`'s rule stands, and `fake.calls` must contain no `requestAlerts` after any case here.

## 7. Definition of Done

- [ ] `'a tapped reminder routes to its record and triggers exactly one reconcile'` passes, and was seen to fail first for the stated reason
- [ ] the tap lands on the record
- [ ] exactly one reconcile follows
- [ ] a tap on a stale notification says so rather than routing to nothing
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary
- [ ] "the record" is the **reminder** record: no database read resolves an animal on the tap path (`08 §2.12`)
- [ ] the push is deferred with a `TODO(N25-T01)` that names the task and the reason, and a test reads it
- [ ] `launchTapTarget()` is read once, in the post-frame boot kick, and never before `runApp()`
- [ ] `parseReminderPayload` returns `null` for every malformed input and throws for none
- [ ] no `@pragma('vm:entry-point')`, no background isolate handler, no notification action buttons
- [ ] no route helper, `RouteNames` entry or `MaterialPageRoute` is added by this task

## 8. Verification

```bash
fvm flutter test test/features/reminders_test.dart
make check
make test
```

```bash
# The tap path, and the two things it must not become.
grep -rn "'reminder:'" lib/                       # expect two: written in project(), read in the parser
grep -rn 'vm:entry-point' lib/                    # expect nothing
grep -rn 'pushNamed\|onGenerateRoute' lib/        # expect nothing
grep -rn 'getNotificationAppLaunchDetails' lib/   # expect one, inside the gateway
grep -n  'TODO(N25-T01)' lib/app.dart             # expect one, with the reason beside it

# routes.dart is untouched: the helper is N25-T01's.
git diff --stat -- lib/routing/ lib/l10n/         # expect nothing
fvm flutter test test/features/ --test-randomize-ordering-seed random
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(reminders): route a tapped reminder to its record`
