# N04-T05 — `appNow()` — the one wall-clock reader

| | |
|---|---|
| **Epic** | [N04 — Domain: time and units](epic.md) · `00-README` §9 step 2 (1 of 3) |
| **Task** | 5 of 8 |
| **Depends on** | N04-T04 |
| **Commit** | one commit · `feat(core): appNow(), the one wall-clock reader in the app` |

## 1. Why this task exists

`lib/core/time/app_clock.dart` — the **only** file under `lib/` permitted to call
`DateTime.now(`, its single `[exempt]` allowlist line, and `checkLocalWallTimeExists`, which answers
whether a given local wall time exists at all (it does not, in the spring-forward gap).

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §1.3 | `app_clock.dart` printed in full, and the "no second clock abstraction" anti-pattern |
| `docs/engineering/05-domain-correctness.md` | §2.8 | the `DateTime.now()` ban, the gate rows, the two shell greps, and how tests install time |
| `docs/engineering/05-domain-correctness.md` | §7.5 | `checkLocalWallTimeExists` printed in full, and why the *ambiguous* hour is deliberately not warned about |
| `docs/engineering/CONVENTIONS.md` | §2.2, §4.7, §6 R23, R24, R56 | `appNow()`'s spelling and home; the `[exempt]` line format; the four day-one exemptions |
| `docs/research/00-tech-decisions.md` | §2.E #46, §5.1 | one clock, `package:clock` **1.1.2** |
| `docs/engineering/12-testing.md` | §2.1, §2.2 | `atFixed`, and the `Clock.fixed`-in-a-widget-test trap |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-domain` | `now` is a parameter everywhere else; this is the one place it is read |
| `shed-conventions` | the `[exempt]` line's format, and R56's four-line day-one budget, are its subject |

`CLAUDE.md` caps auto-firing skills at two per intent. `shed-testing` is not reloaded: the policy test
that keeps `appNow()` the only reader is written out in §5.4 — the scan, the planted `DateTime.now(`
that must make it fire, and the negative case that keeps it quiet on `clock.now()`.
## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/policy/one_clock_test.dart`
- **Test** — `'DateTime.now( appears in exactly one non-generated file under lib/'`
- **Why it is red today** — `DateTime.now(` may be called from anywhere, and N03-T06's rule has no legitimate call site to point at yet.

```bash
fvm flutter test test/policy/one_clock_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the file, the allowlist line with its reason, and the test that counts call sites across
`lib/` rather than trusting the gate alone. **Read §5.3.1 before you write the assertion**: the naive
`expect(hits.length, 1)` is red forever, for a reason that is the whole design.

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8 step 2 (domain — `wall_time.dart`, `warning.dart`) plus one file in `lib/core/`, and
step 7 (tests). Step 1 skipped: nothing is stored. This is the only task in the epic that touches a
**configuration** file, and that line is the one thing here a reviewer must never wave through.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `test/policy/one_clock_test.dart` | new | The anchor, written first. `test/policy/` is named for the **property**, not the file under test (CONVENTIONS §4.1) |
| 2 | `lib/domain/validation/warning.dart` | new, **partial** | `final class Warning` and `enum WarningCode` with its **first** member, `timeDoesNotExistLocally`. See §5.3.4 — this file is completed by N06-T02, not by you |
| 3 | `lib/domain/time/wall_time.dart` | new | `checkLocalWallTimeExists(int y, int mo, int d, int h, int mi)` and the private `_hhmm` formatter. Pure domain: no clock, no Flutter |
| 4 | `lib/core/time/app_clock.dart` | new | The four-line file. The single `package:clock` reader in `lib/` |
| 5 | `tool/policy_allowlist.txt` | **touched** | One line added to `[exempt]`. The reason goes in the commit message (`00-README` §7.4) |

`lib/core/time/ticker.dart` (`minuteTickProvider`, R25) is **not** this task's — it is a Riverpod
provider and lands in N12. Do not create the file "while you are in the folder".

### 5.2 The signatures

```dart
// lib/core/time/app_clock.dart — the single allowlisted reader of wall-clock time.
import 'package:clock/clock.dart';           // clock 1.1.2 (decision-record §5.1)
import '../../domain/time/instant.dart';

/// Every timestamp in the app originates here. Repositories and controllers
/// call this; pure domain functions take the result as a parameter.
Instant appNow() => Instant(clock.now().millisecondsSinceEpoch);
```

```dart
// lib/domain/time/wall_time.dart
/// Did the wall-clock time the user typed actually exist in the device zone?
/// Dart moves a nonexistent local time forward with no exception — that is
/// Dart correcting the user, so we surface it.
List<Warning> checkLocalWallTimeExists(int y, int mo, int d, int h, int mi) {
  final built = DateTime(y, mo, d, h, mi);
  if (built.hour == h && built.minute == mi && built.day == d) return const [];
  return [
    Warning(WarningCode.timeDoesNotExistLocally,
        'The clock skipped ${_hhmm(h, mi)} that night (clocks went forward). '
        'Saved as ${_hhmm(built.hour, built.minute)}.',
        fieldPath: 'time'),
  ];
}
```

```dart
// lib/domain/validation/warning.dart — the shape N06-T02 completes
final class Warning {
  final WarningCode code;
  final String message;     // what we OBSERVED, never what to do
  final String? fieldPath;  // for scroll-to-field, not for editing
  const Warning(this.code, this.message, {this.fieldPath});
}

enum WarningCode {
  timeDoesNotExistLocally,   // the first of eleven; N06-T02 adds the other ten
}
```

```
# tool/policy_allowlist.txt — the [exempt] section, after this task
[exempt]
lib/core/time/app_clock.dart       :: time.dart_clock
```

The format is `<path> :: <rule id>`, matched by `01-architecture.md`'s
`exempt.contains('$from :: $id')`. R56 fixes the day-one total at **four**; this is the first, and
the other three arrive with `lib/core/ui/` in N09.

### 5.3 The details that are easy to get wrong

1. **`DateTime.now(` appears in this file ZERO times, and the anchor test's name says "exactly
   one".** This is not a typo in either place, and it is the single trap in this task.
   `05` §2.8, verbatim: *"`DateTime.now(` appears in exactly one file: `lib/core/time/app_clock.dart`
   — and today it appears there zero times, because `clock.now()` does the reading. The allowlist
   entry exists so the rule has exactly one reviewable exception point."*
   So write the assertion as the **conjunction that is actually true**, under the test name as given:
   - the set of non-generated files under `lib/` containing `DateTime.now(` is a **subset of**
     `{lib/core/time/app_clock.dart}` — today, empty; and
   - `clock.now(` appears in **exactly one** non-generated file under `lib/`, and it is
     `lib/core/time/app_clock.dart`.

   Together those are "one wall-clock reader", which is what the test is named for.
   `expect(hits.length, 1)` on `DateTime.now(` alone is red forever and will be "fixed" by somebody
   adding a pointless `DateTime.now()` to satisfy it.
2. **Skip `*.g.dart`, and match case-insensitively in `.drift` files too.** `05` §2.8 imposes both
   scan-scope requirements on the gate; your test inherits them or it disagrees with the gate it is
   cross-checking. Also exclude `tool/check_policy.dart` itself — it contains the banned literals as
   *data* and is not scanned by itself (CONVENTIONS §1).
3. **`12` §1.4 says a source scan belongs in the gate, not in `test/policy/`.** The plan critique
   fixed this anchor at `test/policy/one_clock_test.dart` anyway, and the reason is that the gate has
   no row for `clock.now(` — only for `DateTime.now(`. The durable fix is a `time.ambient_clock` row
   in `tool/check_policy.dart` plus its proving case in `test/policy/gate_rules_test.dart`, which
   N03-T07's rule-inventory assertion will demand. If you add the row, keep this test as the
   behavioural cross-check on `appNow()` itself; do not delete it and do not let the two drift apart.
4. **`Warning` and `WarningCode` do not exist yet, and you need them.** `lib/domain/validation/`
   is N06-T02's, two epics away, but `checkLocalWallTimeExists` returns `List<Warning>` by CONVENTIONS
   §2.2 and DST-3 (N04-T08) asserts `w.single.code == WarningCode.timeDoesNotExistLocally`. Create
   `warning.dart` here with `Warning` and **one** enum member. Adding the other ten in N06-T02 is
   additive and breaks nothing. What you must **not** do: invent a second warning type, return a
   `bool`, return a `String?`, or give `checkLocalWallTimeExists` a different signature — every one of
   those is a rename that N06 then has to undo across the validators. Note in the commit message that
   N06-T02's *"eleven members"* assertion stays red until N06, which is correct.
5. **`Warning` has no `fix()`, no `corrected` field and no callback — build it that way from the
   first line.** `05` §7.5: the API surface for mutation does not exist, so no amount of call-site
   carelessness produces one. It is tempting to add "and here is the time we would have used"; that is
   safety rule 4 with a friendly face.
6. **The *ambiguous* hour is deliberately NOT warned about.** `checkLocalWallTimeExists(2026, 10, 25, 1, 30)`
   returns `const []`. The displayed time still matches what the user typed, so nothing was silently
   corrected from the shepherd's point of view, and the 60 minutes of ambiguity are unambiguous in the
   exported UTC column anyway. `05` §2.9 lists warning about it as an **anti-pattern**: it is one hour
   a year with zero visible effect, and noise at 3am is a defect.
7. **The predicate checks hour, minute and day — not month and not year.** That is `05` §7.5's
   implementation as printed and it is sufficient: a spring-forward shift moves the clock forward by
   an hour, so it can roll the day but never the month. Do not "harden" it into a full equality check
   that also compares `built.year` and `built.month` without understanding why — a 23:30 gap on
   31 December is the one case where the day rolls the month, and a naive full check would then warn
   correctly but with a message naming the wrong date. If you touch this, add the case to the test
   table rather than changing the check silently.
8. **The DoD's "returns false in the spring-forward gap" is shorthand.** The function returns
   `List<Warning>`: **empty** when the time exists, **one warning** when it does not. There is no
   `bool`-returning variant and adding one gives the caller a way to check without surfacing.
9. **There is no second clock abstraction, and this is the task where somebody adds one.**
   No `abstract class Clock`, no `SystemClock`, no `clockProvider`, no `Clock` parameter on a
   repository. Two clock seams are worse than none, because a test that fakes one does not fake the
   other (decision #46, `05` §1.3). CONVENTIONS §3.5 puts the clock explicitly *not* in the provider
   graph.
10. **`clock.now()` returns a *local* `DateTime`, and that is fine.** `millisecondsSinceEpoch` is
    zone-independent, so `appNow()` is a true instant regardless of the device zone. Do not "fix" it
    to `clock.now().toUtc().millisecondsSinceEpoch` — same number, more code, and it invites a reader
    to think the zone mattered.
11. **`lib/core/time/app_clock.dart` imports `../../domain/time/instant.dart` — a relative import.**
    `lib/core/` may import `lib/domain/` (CONVENTIONS §1.1's `_mayImport`). The reverse would be a
    `layer.domain` failure; `wall_time.dart` therefore imports **nothing** from `lib/core/`.
12. **In tests you install time with `withClock(Clock.fixed(...))`, and in widget tests you do not.**
    The binding already runs every `testWidgets` body inside a `FakeAsync` zone whose clock is
    `package:clock`'s ambient one, so `tester.pump(const Duration(hours: 25))` really moves
    `appNow()`. Wrapping a widget test in `Clock.fixed` freezes it and every elapsed-time readout
    silently measures 0 h and passes (decision #113, `12` §2.2). The harness helper is `atFixed`, and
    it carries that warning in its own doc comment.

### 5.4 The full test set

**`test/policy/one_clock_test.dart`** — the anchor's home. Zone-agnostic, no `@Tags`.

| Case | What it pins |
|---|---|
| `'DateTime.now( appears in exactly one non-generated file under lib/'` | **the anchor**, as the conjunction in §5.3.1: `DateTime.now(` hits ⊆ `{lib/core/time/app_clock.dart}`, and `clock.now(` hits `== ['lib/core/time/app_clock.dart']` |
| `'the [exempt] allowlist names app_clock.dart and only app_clock.dart for time.dart_clock'` | parse `tool/policy_allowlist.txt`; the `[exempt]` section contains `lib/core/time/app_clock.dart :: time.dart_clock` and no second entry against that rule id |
| `'no file under lib/domain/ imports package:clock'` | the D3/R24 half of the same property, cross-checking `layer.domain` from the test side |
| `'there is no second clock abstraction'` | source scan of `lib/`: no `abstract class Clock`, no `SystemClock`, no `clockProvider` |

**`test/domain/time/wall_time_test.dart`** — the zone-agnostic half of `checkLocalWallTimeExists`.

| Case | What it pins |
|---|---|
| `'an ordinary afternoon time exists and produces no warning'` | `checkLocalWallTimeExists(2026, 7, 1, 14, 30)` is empty in **any** zone |
| `'the warning carries the field path and both times'` | when it fires, `fieldPath == 'time'`, the message contains the typed `HH:mm` and the shifted `HH:mm`, and `code == WarningCode.timeDoesNotExistLocally` |
| `'a Warning cannot mutate anything'` | source read: no `fix`, no `apply`, no `corrected`, no callback field on `Warning` |
| `'the message is an observation, not an instruction'` | it contains no `should`, no `try`, no imperative — the `ContentPolicy` scan in N06-T09 will assert this globally; assert it here for the one message that exists today |

**`test/core/time/app_clock_test.dart`** — `appNow()` under a pinned clock.

| Case | What it pins |
|---|---|
| `'appNow returns the ambient clock as an Instant'` | `05` §2.8 verbatim: `withClock(Clock.fixed(DateTime.utc(2026, 3, 4, 3, 20)), () => expect(appNow(), Instant(DateTime.utc(2026, 3, 4, 3, 20).millisecondsSinceEpoch)))` |
| `'appNow is zone-independent'` | the same assertion passes unchanged under `TZ=Pacific/Chatham` — the epoch millis do not move |
| `'appNow inside the ambiguous hour yields one of the two candidate instants'` | pin `Clock.fixed(DateTime.utc(2026, 10, 25, 0, 30))` and `Clock.fixed(DateTime.utc(2026, 10, 25, 1, 30))`; both produce a valid `Instant`, exactly one hour apart, with no throw and no correction |

The **spring-forward gap** case — `checkLocalWallTimeExists(2026, 3, 29, 1, 30)` returning exactly
one warning naming `01:30` and `02:30` — is **DST-3**, and it lives in
`test/domain/uk_zone/ambiguous_hour_test.dart` with N04-T08, because it only fires under
`TZ=Europe/London`. Do not put a zone-dependent assertion in any of the three files above; under
`Pacific/Chatham` that call returns empty and the test would go green for the wrong reason.

## 6. Constraints that bind this task

- **The five safety rules** — rule 4 (never silently correct an entry), held at **caught by a test on the source text**. Dart itself violates it on our behalf by shifting a nonexistent local time with no exception; `checkLocalWallTimeExists` is the surfacing. The rule that would drop to *documented* here is the `Warning`-has-no-writer property — build it right in this commit, not in N06.
- **`layer.domain`** — `wall_time.dart` and `warning.dart` import `dart:*` and `lib/domain/` only. **`app_clock.dart` is in `lib/core/`**, which may import `package:clock` and `lib/domain/`; putting `appNow()` under `lib/domain/` would be a `layer.domain` failure and is the most likely wrong instinct here.
- **The `[exempt]` line is a one-way door in review terms** — `00-README` §7.4: it *"deletes a rule for one file, forever, silently, and the reason goes in the commit message that adds it."* R56 caps day-one exemptions at four; a fifth is a review conversation.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'DateTime.now( appears in exactly one non-generated file under lib/'` passes, and was seen to fail first for the stated reason
- [ ] exactly one call site, and the allowlist line names it
- [ ] `checkLocalWallTimeExists` returns false in the spring-forward gap
- [ ] no domain function reads the clock — every one takes `now`
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/policy/one_clock_test.dart
fvm flutter test test/domain/time/wall_time_test.dart test/core/time/app_clock_test.dart
TZ=Pacific/Chatham fvm flutter test test/domain/time test/core/time
dart tool/check_policy.dart

# 05 §2.8's two shell greps, run before you push
grep -rn --include='*.dart' --exclude='*.g.dart' 'DateTime\.now(' lib/ \
  | grep -v '^lib/core/time/app_clock\.dart:' \
  && { echo 'POLICY FAIL: DateTime.now() outside lib/core/time/app_clock.dart'; exit 1; }
grep -rniE --include='*.dart' --include='*.drift' --exclude='*.g.dart' \
  "current_timestamp|current_date|current_time|date\('now'\)|datetime\('now'\)" lib/ \
  && { echo 'POLICY FAIL: SQL-side time function'; exit 1; }

make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(core): appNow(), the one wall-clock reader in the app`
