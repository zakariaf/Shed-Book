# c2 — API and code-correctness audit

Adversarial review of `docs/research/raw/01..10`. Lens: **would a beginner following these notes hit a
compile error or a silent bug?**

**Method.** Every load-bearing claim was checked against a primary source (pub.dev API, api.flutter.dev,
`raw.githubusercontent.com/flutter/flutter`, drift.simonbinder.eu, dart.dev, sqlite.org) or reproduced
locally. The machine has the exact toolchain the notes assume:

```
$ flutter --version
Flutter 3.44.6 • channel stable
Framework • revision ee80f08bbf (3 weeks ago) • 2026-07-08
Tools • Dart 3.12.2 • DevTools 2.57.0
```

That matches `02`'s header byte-for-byte, so the toolchain claims across all ten documents are **verified,
not assumed**. Everything below was run on it.

---

## Summary

| # | Severity | Where | One line |
|---|---|---|---|
| 1 | blocker | 01 §7.2, 04 §5.1 vs 02 §1.5 | Docs disagree on the Riverpod version; the 3.4.1 half provably does not `pub get` |
| 2 | blocker | 01 §7.2, §8.4, §8.5 | `ProviderScope(retry:)` and `Notifier`+`.autoDispose` are compile errors on 2.6.1 |
| 3 | blocker | 02 §4.4 | Riverpod-3 family snippet labelled "2.6.1 spelling"; 2 compile errors; falsifies the doc's "all snippets analyze clean" claim |
| 4 | high | 03 §3.3 | `validateDatabaseSchema(this)` is not a top-level function, and the async call is swallowed by a sync `assert` |
| 5 | high | 03, 05, 06, 08, 10 | Example code uses `DateTime.now()`, which 01/04/09 make a hard CI failure |
| 6 | high | 05 §6.4 | Tap-target test omits `ensureSemantics()`; the gate cannot work |
| 7 | high | 05 §2.5 | `_AtLeast` overrides a deprecated member 10 bans, and has no `==`/`hashCode` |
| 8 | medium | 02 §1.4 | The "real stack" used for the resolution matrix includes the EOL `sqlite3_flutter_libs` |
| 9 | medium | 04 §2.3 | `Clock.fixed` + `tester.pump(Duration)` cannot both be right; time freezes |
| 10 | medium | 01 §10.3 | Drift view uses `groupBy`, undocumented for Dart-defined views |
| 11 | medium | 01 §8.5 | `abstract base class` forces every subclass to be `base`/`final`/`sealed`; the example ignores this |
| 12 | low | 01 §6.1 | "Dart 3.12 private named params" comment on code that uses ordinary initializing formals |
| 13 | low | 08 §0.2 | Dart-version discrepancy left open; it is resolvable in one command |

---

## 1 — BLOCKER. The doc set cannot decide on a Riverpod version, and one choice does not resolve

**Claims.**
- `01` §Bottom-line row 9 and §7.2: *"Adopt `flutter_riverpod` 3.4.1 … with `retry: (_, __) => null` on the root scope (non-negotiable)."*
- `04` §5.1: *"Riverpod: **flutter_riverpod 3.4.1** … Riverpod 3 ships `ProviderContainer.test()`."*
- `02` §1.5: *"`flutter_riverpod: 2.6.1` — exact pin, not `^2.6.1`."*

**Verified.** `riverpod` 3.4.1 does carry `test: ^1.0.0` in runtime `dependencies`
(https://pub.dev/api/packages/riverpod), and `flutter_riverpod` 3.4.1 carries `flutter_test`
(https://pub.dev/api/packages/flutter_riverpod). `02` is right about the cause.

**Reproduced.** Minimal pubspec, this app's stack, Flutter 3.44.6:

```yaml
dependencies:  { flutter_riverpod: ^3.4.1, drift: ^2.34.2, drift_flutter: ^0.3.1,
                 path_provider: ^2.1.6, flutter_local_notifications: ^22.2.0, share_plus: ^13.3.0 }
dev_dependencies: { flutter_test: sdk, build_runner: ^2.4.0, drift_dev: ^2.34.5 }
```

```
Because flutter_riverpod >=3.4.1 depends on riverpod 3.4.1 which depends on test ^1.0.0,
one of flutter_test from sdk or build_runner >=2.0.0 or drift_dev >=2.34.1+1 or
flutter_riverpod >=3.4.1 must be false.
So, because shed_probe depends on both build_runner ^2.4.0 and drift_dev ^2.34.5,
version solving failed.
```

Swapping only that one line to `flutter_riverpod: 2.6.1` → `Changed 113 dependencies!`.

`02`'s documented workaround also reproduces exactly: `build_runner: any` + `drift_dev: any` resolves,
and pub silently picks **`drift_dev 2.34.0`** (not 2.34.5), `analyzer 12.1.0`, `build_runner 2.15.1` —
precisely the "silently held your database toolchain back" cost `02` predicted.

**Correction.** `01` and `04` are wrong. Either the whole doc set states `flutter_riverpod: 2.6.1`, or it
adopts a workaround *explicitly and everywhere*, with `drift_dev` pinned to 2.34.0 and a CI assertion on
the lockfile. It cannot ship as-is: `01` and `03`/`04` describe a `pubspec.yaml` that fails on the first
`flutter pub get`.

---

## 2 — BLOCKER. `01`'s Riverpod code does not compile on the version the project can actually use

`01` §7.2 calls `retry: (retryCount, error) => null` **"Mandatory configuration — do not ship without it"**
and repeats it in the §8.4 widget test. §8.5 defines `abstract base class WriteController extends
Notifier<WriteState>` used as `NotifierProvider.autoDispose<PenWriteController, WriteState>(...)`, with the
comment *"Riverpod 3: `Notifier`, no `AutoDispose` prefix."*

Both are Riverpod-3-only. Compiled verbatim against `flutter_riverpod: 2.6.1`:

```
error • 'PenWriteController' doesn't conform to the bound 'AutoDisposeNotifier<WriteState>'
        of the type parameter 'NotifierT'                    • type_argument_not_matching_bounds
error • The named parameter 'retry' isn't defined            • undefined_named_parameter
```

`ProviderScope`'s `retry` parameter is real — but only in 3.x
(https://pub.dev/documentation/flutter_riverpod/latest/flutter_riverpod/ProviderScope-class.html). The
underlying behaviour `01` is defending against is real too (riverpod.dev/docs/whats_new: *"Providers that
fail during initialization will automatically retry … with an exponential backoff"*), which is exactly why
this matters: on 2.6.1 there is no auto-retry to disable, so the "non-negotiable" line is both
uncompilable **and** unnecessary. The doc gives no way to tell those apart.

**Correction.** Gate every Riverpod snippet on the chosen major. If 2.6.1: drop `retry:`, note that 2.6.1
has no auto-retry, and use `AutoDisposeNotifier` wherever `.autoDispose` is applied.

---

## 3 — BLOCKER. `02` §4.4 is Riverpod-3 code presented as Riverpod-2, and the doc's compile guarantee is false

`02` §4 opens with: *"Every snippet below was compiled with `flutter analyze` (Flutter 3.44.6 / Dart
3.12.2) against `flutter_riverpod` and `go_router`, and reports **"No issues found!"**."* §4.4 then gives:

```dart
class EweCardVm extends AsyncNotifier<EweCard> {
  EweCardVm(this.eweId);
  final int eweId;
  @override Future<EweCard> build() async => db.eweCard(eweId);
}
// 2.6.1 spelling (also valid in 3.x):
final eweCardVmProvider =
    AsyncNotifierProvider.autoDispose.family<EweCardVm, EweCard, int>(EweCardVm.new);
```

Compiled verbatim against the pinned `flutter_riverpod: 2.6.1`:

```
error • 'EweCardVm' doesn't conform to the bound 'AutoDisposeFamilyAsyncNotifier<EweCard, int>'
error • The argument type 'EweCardVm Function(int)' can't be assigned to the parameter
        type 'EweCardVm Function()'
```

In 2.6.1 the bound is `FamilyAsyncNotifier<T, Arg>` / `AutoDisposeFamilyAsyncNotifier<T, Arg>`, the create
function takes **no** arguments, and the family argument arrives as `build(Arg arg)` and `this.arg`
(https://pub.dev/documentation/riverpod/2.6.1/riverpod/FamilyAsyncNotifier-class.html). Constructor
delivery is a Riverpod **3** change — riverpod.dev/docs/whats_new: *"Instead of extending `FamilyNotifier`,
notifiers now accept arguments through constructors."*

The tell is in the doc itself: it justifies the snippet by quoting `riverpod-3.4.1/lib/src/builder.dart`
and then labels the result "2.6.1 spelling". A beginner copying §4.4 gets two errors on the first ewe card
screen with no idea why, because the surrounding prose promises it analyzes clean.

**Correction.** Rewrite §4.4 for 2.6.1 (`AutoDisposeFamilyAsyncNotifier<EweCard, int>`, `build(int arg)`,
zero-arg constructor tear-off) and delete the blanket "every snippet compiles" claim, or re-run it and
scope it per version.

---

## 4 — HIGH. `03`'s `validateDatabaseSchema` call is a compile error, and the fix is already in `04`

`03` §3.3:

```dart
beforeOpen: (details) async {
  assert(() { validateDatabaseSchema(this); return true; }());
},
```

`validateDatabaseSchema` is an **extension member** (`VerifySelf` on `GeneratedDatabase`) in
`package:drift_dev/api/migrations_native.dart`, called as `db.validateDatabaseSchema()`
(https://pub.dev/documentation/drift_dev/latest/api_migrations_native/VerifySelf.html). There is no
top-level function of that name, so `validateDatabaseSchema(this)` does not compile.

Second, quieter defect: it returns `Future<void>`. Even corrected to `validateDatabaseSchema()`, wrapping
it in a synchronous `assert(() { …; return true; }())` starts the check and returns `true` immediately. A
schema mismatch then surfaces as an unhandled async error long after `beforeOpen` completed — the opposite
of the "cheap insurance" the doc claims.

`04` §3.5 has it right: `if (kDebugMode) { await validateDatabaseSchema(); }`. Two docs, two spellings,
one of them broken.

---

## 5 — HIGH. Five documents' example code would fail the CI gate three other documents mandate

`01` §11.3 ships `tool/check_layers.dart` with a **textual ban** applied to all of `lib/`:

```dart
const _bannedText = <String, Set<String>>{
  'lib/': {"date('now')", 'CURRENT_TIMESTAMP', 'DateTime.now('},
};
```

`04` §2.1 (*"Rule for `lib/`: `DateTime.now()` is banned"*, enforced by policy gate A) and `09` §3.8
(*"Ban `DateTime.now()` in `lib/`. One lint-enforced ban."*) repeat it.

The implementation code a developer would copy violates it repeatedly:

| File | Lines |
|---|---|
| `03-persistence.md` | 676 (`fosterLamb`), 1367, 1598, 1643, 1661 |
| `06-platform-integration.md` | 340 (`reconcile`, `after: DateTime.now().toUtc()`), 369 |
| `08-performance-and-reliability.md` | 309, 314, 476, 662, 807, 841, 1129, 1134 |
| `10-accessibility-and-i18n.md` | 1102 (`seededAt: DateTime.now()`) |
| `05-design-system-3am.md` | §12: *"'Hours since penned' is derived from `entered_at` and `DateTime.now()`"* |

`06` line 340 is the worst of them, because `reconcile()` is the reminder scheduler — the code path
`04` §2 identifies as the one where a DST or clock bug is invisible and safety-relevant.

**Correction.** Either rewrite every snippet to `clock.now()` (the docs' own rule), or downgrade the ban
from a hard CI failure to a guideline with named exemptions. Right now the doc set specifies a gate that
its own reference implementations trip on day one.

---

## 6 — HIGH. `05`'s tap-target test omits `ensureSemantics()` — the gate `04` warns about by name

`04` §6.1 is explicit and correct:

> Semantics are **not** on by default in widget tests … Forgetting `ensureSemantics()` makes the guideline
> evaluate an empty tree and **pass vacuously**. That is the number-one way this gate silently does nothing.

`05` §6.4 then writes the test **without it**:

```dart
testWidgets('${screen.name} meets the 60pt tap floor', (tester) async {
  await tester.pumpWidget(screen.build());
  await tester.pumpAndSettle();
  await expectLater(tester, meetsGuideline(shedTapTargetGuideline));   // no ensureSemantics()
```

Verified against `flutter/flutter` `packages/flutter_test/lib/src/accessibility.dart`:

```dart
for (final RenderView view in tester.binding.renderViews) {
  result += _traverse(view.flutterView, view.owner!.semanticsOwner!.rootSemanticsNode!);
}
```

With no live `SemanticsHandle`, `semanticsOwner` is null and that is a null-check throw, not a pass — so
`04`'s "pass vacuously" wording is itself slightly off, but the practical verdict is the same and worse:
`05`'s snippet as written cannot do its job. `05` §6.4 is the version a reader lands on first, because it
sits in the design-system doc next to the 60 pt rule.

The rest of `05`/`04` on this API is **correct** and I confirmed it from source:
`MinimumTapTargetGuideline` is public and const-constructible as
`const MinimumTapTargetGuideline({required this.size, required this.link})`, and `04` §6.3's four skip
rules (`isMergedIntoParent`, `shouldSkipNode`, `hasImplicitScrolling` boundary,
`Offset.zero & view.physicalSize` boundary) match the source exactly. That makes the omission in `05` the
only defect — and the one that matters.

**Correction.** Add `final handle = tester.ensureSemantics(); addTearDown(handle.dispose);` to `05` §6.4,
or delete the snippet and cross-reference `04` §6.2 as the single source.

---

## 7 — HIGH. `05`'s `_AtLeast` TextScaler overrides a deprecated member `10` bans, and lacks value equality

`05` §2.5:

```dart
class _AtLeast extends TextScaler {
  const _AtLeast(this._inner, this._min);
  @override double scale(double fontSize) => math.max(_inner.scale(fontSize), fontSize * _min);
  @override double get textScaleFactor => math.max(_inner.textScaleFactor, _min);
}
```

Two problems, both verified on https://api.flutter.dev/flutter/painting/TextScaler-class.html:

1. `TextScaler.textScaleFactor` is deprecated — *"This property exists only for backward compatibility
   purposes, and will be removed in a future version of Flutter."* `10` §4.1 states the house rule as
   **"`textScaleFactor` must not appear anywhere. Add a lint/grep in CI."** `05` puts it in the theme
   layer, so the grep `10` mandates fires on `05`'s own recommended widget.
2. No `==`/`hashCode`. The class docs say to *"Consider overriding the `==` operator if applicable to avoid
   unnecessary rebuilds."* `_ShedMediaOverrides` constructs a fresh `_AtLeast` inside `build()`, so
   `MediaQuery.updateShouldNotify` sees a changed `textScaler` on **every** rebuild and invalidates every
   MediaQuery dependant in the tree. `02` §8.1 makes exactly this argument about identity-vs-value equality
   and even says *"I made this exact mistake while drafting §4 … Assume it will happen again."* It did,
   two documents over.

**Correction.** Drop the `textScaleFactor` override entirely (`scale()` is the operative method), add
`==`/`hashCode` over `(_inner, _min)`, and hoist the instance out of `build()`.

---

## 8 — MEDIUM. `02`'s resolution matrix was run against a pubspec the rest of the doc set forbids

`02` §1.4: *"I built the pubspec Shed Book will actually have — Drift + `sqlite3_flutter_libs` +
`path_provider` + …"*.

`03` §2.1 and `08` §0.1 both say the opposite, correctly: `sqlite3_flutter_libs` is `0.6.0+eol`,
**discontinued** on pub.dev, and *"Starting from version 0.6.0, this package no longer does anything."*
(confirmed on https://pub.dev/packages/sqlite3_flutter_libs; `isDiscontinued` is not set but the version
tag and banner are). `03` §2.6's pubspec carries `# NOT sqlite3_flutter_libs (EOL, no-op)`.

The conclusion survives — I reproduced the failure *without* `sqlite3_flutter_libs` — but the stated method
is wrong, and a reader reconciling `02` §1.4 against `03` §2.6 has no way to know which pubspec is real.

**Correction.** Re-state `02` §1.4's matrix against `03` §2.6's pubspec and drop `sqlite3_flutter_libs`.

---

## 9 — MEDIUM. `04`'s two widget-test time recipes contradict each other

`04` §2.3 asserts, correctly, that `tester.pump(const Duration(hours: 25))` *"is a legitimate way to test
the pen-board badge in a widget test"*. I confirmed the mechanism: `AutomatedTestWidgetsFlutterBinding`
does `_clock = fakeAsync.getClock(DateTime.utc(2015))` and runs the body via `fakeAsync.run(...)`
(`packages/flutter_test/lib/src/binding.dart`), and `FakeAsync.run` installs the zone clock
(`run()` internally calls `withClock(_clock, …)` —
https://pub.dev/documentation/fake_async/latest/fake_async/FakeAsync/run.html). So `clock.now()` in
widget-under-test code really is fake and really does advance.

Then the very next snippet says *"To pin an absolute start time in a widget test, wrap the body"*:

```dart
await withClock(Clock.fixed(DateTime.utc(2026, 3, 28, 3, 0)), () async {
  await tester.pumpApp(const PenBoardScreen());
  expect(find.text('25 h'), findsOneWidget);
});
```

`Clock.fixed` returns a clock whose `now()` **never moves**. Inside that wrapper, `pump(Duration)` still
advances FakeAsync's timers but `clock.now()` is frozen, so every "hours since penned" / "days until clear"
readout stays at its initial value forever. Follow §2.3's first recipe and the second one and the pen-board
test silently measures 0 h.

**Correction.** Say plainly that `Clock.fixed` freezes time and is only for single-instant assertions; for
elapsed-time widget tests use the binding's own advancing fake clock (offset the seed data instead of
pinning `now`).

---

## 10 — MEDIUM. `01`'s drift view uses `groupBy`, which drift does not document for Dart-defined views

`01` §10.3:

```dart
@override
Query as() => select([ewes.id, ewes.tag, lambingCount, avgLitter])
    .from(ewes)
    .join([leftOuterJoin(lambings, …), leftOuterJoin(lambs, …)])
    ..groupBy([ewes.id]);
```

drift's own Dart-views page (https://drift.simonbinder.eu/dart_api/views/) documents exactly one shape —
`select([...]).from(table).join([innerJoin(...)])` — plus the nullability rule `01` correctly quotes
(*"expressions defined as an `Expression` getter are always nullable"*). It says nothing about `groupBy`
or `where` inside `as()`. The snippet additionally leans on cascade precedence so the return value is the
`JoinedSelectStatement`, not `groupBy`'s result.

This is the query behind the Season Summary and the ewe-card one-line summary — the retention feature. It
is presented with no hedge and no source for the `groupBy` half.

**Correction.** Either cite a drift source for `groupBy` in a Dart view, or mark it unverified and fall
back to the `customSelect` + explicit `readsFrom:` route `01` already describes for the histogram.

---

## 11 — MEDIUM. `abstract base class` makes every subclass in `01` §8.5 a compile error unless modified

```dart
abstract base class WriteController extends Notifier<WriteState> { … }
```

Dart's class modifiers require any subtype of a `base` class to itself be `base`, `final` or `sealed`. The
doc's usage line — `NotifierProvider.autoDispose<PenWriteController, WriteState>(PenWriteController.new)` —
never says so, and the obvious `class PenWriteController extends WriteController {}` does not compile. I
had to write `final class PenWriteController extends WriteController {}` to get past it while checking
finding #2.

**Correction.** Show the subclass with its modifier, or drop `base`.

---

## 12 — LOW. Mislabelled language feature in `01` §6.1

```dart
LambingRepository({
  required AppDatabase db,               // Dart 3.12 private named params:
  …
})  : _db = db, …
```

Private named parameters are genuinely new in **Dart 3.12** (dart.dev/resources/language/evolution:
*"private named parameters … let you initialize private fields directly through initializing formal
parameters"*), so the fact is right — but the code beneath the comment uses ordinary initializing
formals and an initializer list. Either use `required this._db` or delete the comment; as written it
teaches a beginner the wrong thing about what the syntax buys.

---

## 13 — LOW. `08` leaves a toolchain discrepancy open that costs one command to close

`08` §0.2: *"The Flutter 3.44.0 release-notes page contains a PR entry reading 'Bumped to Dart 3.10',
while secondary coverage … pairs it with Dart 3.12. … **Resolve this locally with `flutter --version`**."*

Done: `Flutter 3.44.6 • revision ee80f08bbf • Tools • Dart 3.12.2 • DevTools 2.57.0`. Nine other documents
assert Dart 3.12.2 as fact; `08` should simply record the resolved answer rather than leaving a
"discrepancy" the distilled docs will have to re-open.

---

## Verified correct — do not re-litigate

Checked against primary sources and found **accurate**:

- **Toolchain**: Flutter 3.44.6 / revision `ee80f08bbf` / Dart 3.12.2 / DevTools 2.57.0 — exact.
- **Riverpod dependency pathology** (`02` §1.1–1.4): `riverpod` 3.4.1 declares `test: ^1.0.0` at runtime;
  `flutter_riverpod` 3.4.1 declares `flutter_test`. `riverpod_generator` 4.0.6 declares `analyzer ^13.0.0`
  while pinning `riverpod_analyzer_utils 1.0.0-dev.10`, which requires `analyzer ^12.0.0` — genuinely
  unresolvable in any project. The `any`-constraint workaround resolves and silently pins `drift_dev`
  to 2.34.0. All reproduced.
- **drift** (`01`, `03`, `04`): `BEGIN IMMEDIATE` landed in 2.34.0; `closeStreamsSynchronously` in 2.22.0;
  `late final` column fields, `isStrict`, `unique()`, `uniqueKeys`, `@TableIndex(columns: {#x}, unique:)`,
  and `mixin … on Table` are all documented drift syntax; `DriftNativeOptions`'s parameter list in `03` §3.2
  matches the published API exactly, including the absence of `readPool`; `build.yaml` keys
  (`sql.dialect`, `sql.options.modules: [fts5]`, `store_date_time_values_as_text`,
  `override_hash_and_equals_in_result_sets`) are all real and correctly nested.
- **flutter_local_notifications 22.2.0** (`06` §1.2): the named-parameter signatures given for
  `initialize`, `show`, `zonedSchedule` (including `required AndroidScheduleMode`), `cancel` and
  `periodicallyShow` match the published API verbatim. `IOSFlutterLocalNotificationsPlugin` does still
  exist alongside the `Darwin*` settings classes, so `06` §1.1's advice is right.
- **flutter_test accessibility** (`04` §6.1, §6.3): `MinimumTapTargetGuideline` is public and
  const-constructible with `{required Size size, required String link}`; the four skip conditions and the
  `_kMinimumGapToBoundary = 0.001` constant match `flutter/flutter` source exactly. This is the best-sourced
  section in the whole set.
- **TextScaler / textScaleFactor** (`10` §4.1): the migration table and deprecation status are correct;
  `TestPlatformDispatcher.textScaleFactorTestValue` / `clearTextScaleFactorTestValue` exist and are
  **not** deprecated, so `05` §6.4's use of them is fine.
- **Flutter breaking changes** (`05` §1.2): "Material 3 tokens update" and "`FontWeight` also controls the
  weight attribute of variable fonts" are both under **3.41**; "SnackBar with action no longer
  auto-dismisses", "UISceneDelegate adoption" and "The default page transition on Android is now
  `PredictiveBackPageTransitionBuilder`" are all under **3.38**; `IconData` marked `final` is under 3.44.
  All confirmed on docs.flutter.dev/release/breaking-changes.
- **Language / SQLite**: dot shorthands require Dart ≥ 3.10 and work in switch-expression cases; FTS5's
  trigram tokenizer — *"Substrings consisting of fewer than 3 unicode characters do not match any rows"* —
  confirms `03`'s "trigram FTS5 physically cannot match a 2-char query".
- **Package versions**, all confirmed live: `in_app_purchase` 3.3.0, `in_app_purchase_storekit` 0.4.11,
  `go_router` 17.3.0, `share_plus` 13.3.0, `drift` 2.34.2 / `drift_dev` 2.34.5 / `drift_flutter` 0.3.1,
  `sqlite3` 3.5.0, `sqlite3_flutter_libs` 0.6.0+eol, `clock` 1.1.2, `timezone` 0.11.1, `patrol` 4.8.0,
  `alchemist` 0.14.0, `mocktail` 1.0.5, `very_good_analysis` 10.3.0, `flutter_lints` 6.0.0,
  `riverpod_lint` 3.1.6, and `golden_toolkit` 0.15.0 **discontinued**.
