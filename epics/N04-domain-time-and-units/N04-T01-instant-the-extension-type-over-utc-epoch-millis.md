# N04-T01 — `Instant` — the extension type over UTC epoch millis

| | |
|---|---|
| **Epic** | [N04 — Domain: time and units](epic.md) · `00-README` §9 step 2 (1 of 3) |
| **Task** | 1 of 8 |
| **Depends on** | N03-T07 |
| **Commit** | one commit · `feat(domain): Instant as an extension type over UTC epoch millis` |

## 1. Why this task exists

`Instant` as an extension type over `int` epoch millis, with ordering, arithmetic,
`compareTo` and **no `Instant.now()`**. There is exactly one wall-clock reader in the app and it is
not on this type — which is what stops every later file quietly acquiring one.

## 2. Sources

| Document | Section | What it binds here |
|---|---|---|
| `docs/engineering/05-domain-correctness.md` | §2.1, §2.3 | the instant/civil-date rule, and the type printed verbatim — copy it, do not re-derive it |
| `docs/engineering/05-domain-correctness.md` | §1.2 (D1–D4), §2.9 | the four import bans, and the measured DST facts this type must satisfy |
| `docs/engineering/CONVENTIONS.md` | §2.2, §1.1 rule 1, §4.1 | the exact member list, layer rule `layer.domain`, the test-mirrors-source naming rule |
| `docs/research/00-tech-decisions.md` | §2.E #29, #30 | instants are `INTEGER` UTC epoch millis; the cost of that, stated |
| `docs/engineering/12-testing.md` | §1.2, §2.1 | the domain tier, and why a pure domain test never installs a clock |

## 3. Skills to load

| Skill | Why, in one line |
|---|---|
| `shed-domain` | pure-Dart value types, `now` as a parameter, no Flutter and no clock package |
| `shed-testing` | the domain tier is the thickest and this is its first file |

## 4. TDD

**Red.** Write this test first, run it, and confirm it fails **for the reason below** — not on a missing import and not on a compile error somewhere else.

- **File** — `test/domain/time/instant_test.dart`
- **Test** — `'Instant exposes no now() and orders by epoch millis'`
- **Why it is red today** — `lib/domain/time/instant.dart` does not exist, so there is no type to order, no arithmetic to check and nothing to assert the absence of a `now()` on.

```bash
fvm flutter test test/domain/time/instant_test.dart   # expect: failing, for the reason above
```

**Green.** The minimum code that passes, and nothing beyond it — the extension type, the operators and the ordering. The absence half of the assertion is
made by **reading the source of `lib/domain/time/instant.dart`** for a `now` declaration and by three
sorted `Instant`s coming back in epoch order; there is no runtime API-surface reflection available
(see §5.3).

**Refactor.** With the suite green, fold any duplication into the smallest shared helper the layer rules allow. Nothing new is added in this step.

## 5. What you build

`00-README` §8's order runs schema → domain → data → wiring → controller → UI → ARB → tests. This task
reaches **step 2 (domain)** and **step 7 (tests)** and nothing else. Step 1 is skipped deliberately —
this epic stores nothing; `lib/core/db/converters.dart`, where `InstantConverter` wraps this type, is
N07's file. Say so in the commit message.

### 5.1 The files, in order

| # | File | New? | What changes, and why |
|---|---|---|---|
| 1 | `test/domain/time/instant_test.dart` | new | The anchor, written first. Mirrors `lib/domain/time/instant.dart` per CONVENTIONS §4.1 |
| 2 | `lib/domain/time/instant.dart` | new | The whole task. One extension type, six instance members, two static comparator getters, one factory. No other file in `lib/` changes |

Nothing else. In particular: **do not** touch `lib/core/db/`, do not add an `InstantConverter` here
(R21 puts all three converters in one file, N07's), and do not create `lib/domain/time/` barrel or
`index.dart` — there is no `lib/src/`, no `utils.dart` and no barrel file convention in this tree
(CONVENTIONS §4.1).

### 5.2 The signature

`05` §2.3 prints this type in full and CONVENTIONS §2.2 fixes its member list. Both agree. Copy it:

```dart
// lib/domain/time/instant.dart
/// A moment in absolute time, as UTC milliseconds since the epoch.
/// Non-transparent extension type: a bare `int` cannot be passed where an
/// Instant is expected, and it costs no allocation on a 400-row flock list.
extension type const Instant(int epochMillis) {
  factory Instant.fromDateTime(DateTime d) => Instant(d.millisecondsSinceEpoch);

  DateTime get utc   => DateTime.fromMillisecondsSinceEpoch(epochMillis, isUtc: true);
  DateTime get local => DateTime.fromMillisecondsSinceEpoch(epochMillis);

  Instant  plus(Duration d)      => Instant(epochMillis + d.inMilliseconds);
  Duration difference(Instant o) => Duration(milliseconds: epochMillis - o.epochMillis);
  bool     isBefore(Instant o)   => epochMillis < o.epochMillis;
  bool     isAfter(Instant o)    => epochMillis > o.epochMillis;
  int      compareTo(Instant o)  => epochMillis.compareTo(o.epochMillis);

  static int Function(Instant, Instant) get ascending  => (a, b) => a.compareTo(b);
  static int Function(Instant, Instant) get descending => (a, b) => b.compareTo(a);
}
```

Banned spellings, from CONVENTIONS §2.2: `Instant.now()`, `Instant.fromUtc()`. The representation
getter is `epochMillis` — not `.value`, not `.raw`, not `.millis`.

### 5.3 The details that are easy to get wrong

1. **`implements Comparable<Instant>` does not compile.** An extension type may only `implements` a
   supertype of its *representation* type, and `int` implements `Comparable<num>`, not
   `Comparable<Instant>`. You get `extension_type_implements_not_supertype`. Do not fight it: there is
   no free `.sort()`, which is why `Instant.ascending` and `Instant.descending` exist as static
   getters returning comparator functions. `05` §2.3 says so in as many words.
2. **`implements int` is worse than wrong — it compiles.** If you write
   `extension type const Instant(int epochMillis) implements int`, then `someInstant + 1`,
   `someInstant * 2` and `Grams(4000).compareTo(someInstant)` all become legal. The whole point of the
   type is that they are not. Keep it **non-transparent**.
3. **Extension types erase at runtime.** `Instant`, `Grams`, `MilliCelsius` and every id in
   `lib/domain/ids.dart` are all `int` after compilation. `x is Instant` is true for any `int`;
   `switch (x) { case Instant(): … }` never discriminates; `identical(Instant(0), Grams(0))` is true.
   Consequence, applied for the rest of the project: build extension types for **canonical** values
   only, never for display values, and never write a runtime type test over one.
4. **There is no runtime reflection to assert "no `now` member" with.** `dart:mirrors` is unavailable
   under Flutter, and every test in this project imports `package:flutter_test` (decision #4 — even
   the pure domain ones). So assert the absence by reading the one named file's source text:
   `File('lib/domain/time/instant.dart').readAsStringSync()` and match for a `now` declaration. Read
   one *named* file, never walk a tree — a scan over `lib/` belongs in `tool/check_policy.dart`, not
   in a test (`12` §1.4).
5. **The gate does not catch `Instant.now()`.** N03-T06's `time.dart_clock` row matches the literal
   `DateTime.now(`. A hand-rolled `factory Instant.now() => Instant(clock.now()…)` would trip
   `layer.domain` (a `package:clock` import under `lib/domain/`) — but a
   `factory Instant.now() => Instant(DateTime.now().millisecondsSinceEpoch)` trips `time.dart_clock`
   only because of the `DateTime.now(` inside it. Do not rely on the gate for this. The anchor test is
   the mechanism.
6. **`difference` is `this − other`.** `now.difference(penned)` is positive when `now` is later. DST-1
   in N04-T08 asserts exactly 9 hours across the spring-forward; flip the operands and you get −9 and
   a test that reads as though it passed for a different reason.
7. **`.local` reads the OS zone rules at the moment you call it, not at construction.** The same
   `Instant` renders as two different `DateTime`s on two phones. That is deliberate (`05` §2.7:
   a bundled IANA snapshot frozen at build time ages badly; the phone's own rules do not). It is also
   why every assertion in a zone-agnostic file must be **relational** — "these two are exactly one
   hour apart" — never an absolute wall-clock value.
8. **`plus(Duration)` is absolute-time arithmetic, and that is the right tool here.**
   `Instant.plus(const Duration(days: 7))` adds 168 hours, not seven calendar days. Across the UK
   spring-forward those differ by an hour and the difference lands in a withdrawal period. Do not add
   a `plusDays` to this type — calendar arithmetic belongs on `LocalDate` (N04-T02) and nowhere near a
   withdrawal.
9. **No `toString()` override that formats.** D4 bans `package:intl` and `AppLocalizations` from the
   domain; a type that formats is a type with a locale. Formatting lives in
   `lib/core/ui/formatters.dart`, the only `intl` call site outside `lib/data/`.
10. **You write no `==` and no `hashCode`.** They come from `int`, which is exactly what you want:
    `Instant(1) == Instant(1)` is true and an `Instant` is a safe `Map` key. Adding your own is dead
    code the analyzer will not flag.

### 5.4 The full test set — `test/domain/time/instant_test.dart`

Zone-agnostic by construction: this file must pass under `TZ=Pacific/Chatham` as well as
`TZ=Europe/London`, so every assertion below is relational or UTC-anchored. No `@Tags` on this file.

| Case | What it pins |
|---|---|
| `'Instant exposes no now() and orders by epoch millis'` | **the anchor.** The source of `lib/domain/time/instant.dart` contains no `now` declaration; `[t3, t1, t2]..sort(Instant.ascending)` yields `[t1, t2, t3]` |
| `'fromDateTime is zone-independent'` | `Instant.fromDateTime(DateTime.utc(2026, 3, 4, 3, 20))` and `Instant.fromDateTime(DateTime.utc(2026, 3, 4, 3, 20).toLocal())` are equal |
| `'plus and difference are absolute, not civil'` | `t.plus(const Duration(days: 7)).difference(t).inHours == 168`, for a `t` on either side of a transition |
| `'difference is this minus other'` | `later.difference(earlier)` is positive; `earlier.difference(later)` is its negation |
| `'isBefore, isAfter and compareTo agree'` | the three-way consistency, including the equal case: `t.isBefore(t)` and `t.isAfter(t)` are both false and `t.compareTo(t) == 0` |
| `'descending is the exact reverse of ascending'` | sort the same list both ways, assert one is the reverse of the other |
| `'equality and hashCode come from the representation'` | `Instant(1) == Instant(1)`; `{Instant(1): 'a'}[Instant(1)] == 'a'` |
| `'the two candidate instants of the repeated hour are exactly one hour apart'` | **the ambiguous-hour case, zone-free.** `Instant(DateTime.utc(2026, 10, 25, 0, 30).millisecondsSinceEpoch)` and `Instant(DateTime.utc(2026, 10, 25, 1, 30).millisecondsSinceEpoch)` differ by `const Duration(hours: 1)` and both round-trip through `.utc`. `Instant` is unperturbed by the repeat; that is the property, and it needs no `TZ` to state |
| `'a negative epoch is a real instant'` | `Instant(-1)` orders before `Instant(0)`; nothing clamps at the epoch |
| `'const Instant is a compile-time constant'` | `const a = Instant(0);` compiles — the representation constructor is `const`, so a 400-row flock list allocates nothing |

The wall-clock forms of the repeated hour (`DateTime(2026, 10, 25, 1, 30)` with no `isUtc`) are
DST-2's, in `test/domain/uk_zone/ambiguous_hour_test.dart` — N04-T08. They must not appear in this
file, because they would make it pass or fail on the runner's `TZ`.

## 6. Constraints that bind this task

- **`layer.domain`** — this file may import `dart:*`, `package:meta` and `package:collection` and nothing else. Not `package:flutter`, not `package:drift`, not `package:*riverpod`, not `package:intl`, and **not `package:clock`** (D3, R24).
- **Offline purity** — nothing here can reach a network, and nothing here may be given a reason to.
- **Vocabulary** — one word per concept (`CLAUDE.md`). The banned words are banned in the commit message too: no `draft`, no `save()`, no `sync`, no `Error` as a failure name.

## 7. Definition of Done

- [ ] `'Instant exposes no now() and orders by epoch millis'` passes, and was seen to fail first for the stated reason
- [ ] no `now()`, no `DateTime` in the public surface
- [ ] arithmetic is absolute, never civil
- [ ] decision #2's storage shape — `INTEGER` UTC epoch millis — is what this type wraps
- [ ] the diff carries no raw hex, no magic size, no banned word and no banned gesture
- [ ] `make check` and `make test` are green
- [ ] one commit, in project vocabulary

## 8. Verification

```bash
fvm flutter test test/domain/time/instant_test.dart
TZ=Pacific/Chatham fvm flutter test test/domain/time/instant_test.dart   # must be identically green
dart run tool/check_policy.dart                                          # layer.domain over the new file
dart analyze lib/domain/time/instant.dart
make check
make test
```

## 9. Close out — required, in this order, before the commit

1. **`/simplify`** — reuse, simplification, efficiency and altitude over the diff. Quality only.
2. **`/code-review`** — over the diff; resolve every finding before committing.
3. **Commit** — `feat(domain): Instant as an extension type over UTC epoch millis`
