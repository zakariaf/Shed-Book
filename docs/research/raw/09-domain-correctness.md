# 09 — Domain modelling, units, time, and encoding the safety rules

**Shed Book** · offline-only lambing notebook · Flutter 3.44.6 / Dart 3.12.2 · researched 2026-07-27

> This is the part of the app that has nothing to do with Flutter and everything to do with not
> being wrong about a sheep. Every mechanism below is chosen so that the *wrong* thing is hard or
> impossible to write, not so that a code reviewer remembers to look for it.

**Everything in this document was verified.** Every Dart snippet was compiled and run against the
real Dart 3.12.2 SDK on this machine in a throwaway package (`dart analyze` clean, 48 tests green).
Every package version was read off its live pub.dev page today. Every agricultural definition is
quoted from a levy board, an extension service, or a regulator — not from memory. Where I could not
verify something, I say so.

---

## Bottom line

| # | Decision | Why | Confidence |
|---|---|---|---|
| 1 | **Withdrawal period is a `sealed class` with three states**: `WithdrawalDays(n)` / `WithdrawalNotApplicable` / `WithdrawalNotRecorded`. Private generative constructor; the only entry point is `WithdrawalDays.asEnteredByUser(days:, target:)`. | A nullable `int?` conflates *"the label says 0 days"* with *"I didn't look"*. Those are different facts with different consequences. A sealed union makes every call site handle all three, and the countdown UI physically cannot render for `NotRecorded`. | High |
| 2 | **`WithdrawalTarget { meat, milk }`** — a treatment carries 0..n withdrawal entries, not one. | One product routinely prints two different numbers. One column is a modelling bug that becomes a food-safety bug on a dairy flock. | High |
| 3 | **Clear date = `ceilToNextLocalMidnight(treatmentInstant + N × 24 h)`**, computed in *absolute* time, never civil days. Display the exact elapse instant next to the date. | VICH: the withdrawal period is the minimum period **between the last administration and the production of foodstuffs**, expressed in whole days rounded **up**. Civil-day arithmetic across a spring-forward yields **167 h for a 7-day period** — measured, below. | High |
| 4 | **Canonical mass = integer grams. Canonical temperature = integer milli-°C.** Convert only at the display edge. | Measured: storing 0.1 kg silently rewrites **132 of 241** pound entries at 1 dp; storing 0.1 °C silently rewrites **89 of 201** Fahrenheit entries. Both are violations of safety rule 4 caused purely by a storage choice. Grams and milli-°C: zero failures. | High |
| 5 | **Instants → `INTEGER` UTC epoch millis. Civil dates → `TEXT` `YYYY-MM-DD`.** Never a `DateTime` for a civil date; never a date string for an instant. | A withdrawal *clears on a date*; a lambing *happened at a moment*. The classic bug is a `DateTime` doing both jobs badly. | High |
| 6 | **Denormalise `local_date TEXT` next to every event instant, written at insert time.** | The lambing-spread histogram groups by the shepherd's civil day. SQLite cannot do that correctly without a tz database, and Dart can. Costs 10 bytes. | High |
| 7 | **Use `DateTime` + `toLocal()` for display and arithmetic. Use `package:timezone` only where `flutter_local_notifications` forces it.** | Contrarian: the community reflex "always use `package:timezone`" is *wrong here*. Its IANA snapshot is frozen at build time and this app never updates — after two years the OS zone is more correct than the bundled one. | High |
| 8 | **Inject time via `package:clock` (`clock.now()`), never `DateTime.now()`.** One lint-enforced ban. | 1.1.2, `tools.dart.dev`. Composes with `fake_async` for free. Makes every reminder, countdown and "hours since penned" testable without sleeping. | High |
| 9 | **Every statistic returns a `StatResult` carrying `value`, `definition`, `numerator`, `denominator`, `caveats`, `notComputableReason`.** `value` is `double?` — never 0 as a stand-in for "unknown". | Measured: the same season yields **120% / 100% / 80% / 200%** under four legitimate definitions. A headline number without its definition is a lie. | High |
| 10 | **Default lambing-% definition: lambs born alive ÷ ewes put to the ram.** | AHDB's house convention for all five of its lamb-loss KPIs; Penn State calls per-ewe-exposed "the more accurate method". | High |
| 11 | **Barren rate counts only ewes *explicitly marked barren*.** Absence of a lambing is never evidence of barrenness. | Inferring barren from missing data is a silent correction (rule 4) and inflates a commercially sensitive number. | High |
| 12 | **Assisted rate excludes unscored lambings from *both* numerator and denominator**, and reports coverage. | Sheep Genetics: *"a blank score indicates the lambing ease was not scored."* Treating blank as "unassisted" is exactly the silent inference the spec forbids. | High |
| 13 | **`birthDamId` is `final` with no `copyWith` that accepts it.** `LambDams.atBirth()` is the only constructor that sets it; `fosteredOnto()` copies it. | Makes "a foster changed the birth ewe's litter size" unrepresentable rather than merely tested-against. | High |
| 14 | **Terminology = closed `enum AnimalClass` (stable keys, in the DB/CSV/JSON) + user-editable `TermLabel(singular, plural)` overlay.** Nouns are never baked into ICU plural messages; they are `String` placeholders inside them. | NSA's own glossary shows these terms *overlap and conflict* (shearling by dentition, hogget by age, teg by year). There is no true taxonomy to canonicalise to. | High |
| 15 | **Contradictions are `List<Warning>` from pure functions. There is no `warnings` column and no `fix()` method.** | The mechanism is *absence*: a warning cannot be persisted because there is nowhere to persist it, and cannot mutate because it holds no writer. | High |
| 16 | **`RecordedTime` value type: `effective` + `capturedAt` + `originalEffective?` + `TimeSource`.** Provenance is part of the value, exported as its own columns. | Rule 5 becomes a type, not a convention. `provenanceLabel` can never be empty (exhaustive switch on the enum). | High |
| 17 | **Tag search: filter the in-memory flock list in Dart. FTS5 for notes only, behind a runtime capability probe.** | sqlite.org: FTS5 trigram *"substrings consisting of fewer than 3 unicode characters do not match any rows"* — so `"12"` finding `412` is impossible with trigram FTS5. 400 ewes in a list is sub-millisecond. | High |
| 18 | **Index every foreign key by hand; `PRAGMA foreign_keys = ON` on every connection.** | sqlite.org: SQLite creates no child-key index automatically, and FK enforcement is off by default. | High |
| 19 | **`Disclaimers.exportFooter` is a `const` in exactly one file, referenced (never re-typed) everywhere — including by the banned-phrase allowlist.** Guarded by a test. | Rule 3. The guard caught a real duplication while I was writing it. | High |
| 20 | **Reject `decimal` / `fixed` / any float for measurements. Reject `equatable`. Reject `freezed` for the safety-critical types.** | Integer canonical units are exact, allocation-free and dependency-free. Hand-written sealed classes give a *private* generative constructor; a generated `freezed` union does not. | Medium-High |

---

## 0. What I verified, and how

A throwaway Dart package was created outside the repo, containing every snippet in this document.
Results referenced below come from actually running it:

```
$ dart --version
Dart SDK version: 3.12.2 (stable) on "macos_arm64"

$ TZ=Europe/London dart test
00:00 +48: All tests passed!

$ dart analyze
No issues found!
```

Where a number appears in this document (167 h, 132/241, 120%/100%/80%/200%), it is program output,
not an estimate. The DST results were produced with `TZ=Europe/London`, the primary target market.

---

# Part 1 — The five safety rules as structural mechanisms

Spec §12 lists five rules and says they "should be visible in the code review checklist". A
checklist is the weakest available mechanism: it depends on a tired human at 11pm noticing an
absence. Each rule below is instead converted into something the compiler, the schema, or a test
enforces without anyone remembering.

The hierarchy I applied, strongest first:

1. **Unrepresentable** — the type system cannot express the wrong state.
2. **Unconstructible** — the value exists but there is no public path to a wrong one.
3. **Unpersistable** — the wrong value exists in memory but the schema has no column for it.
4. **Untestable-away** — a test fails on the source text itself.
5. **Documented** — last resort.

---

## 1.1 "Never default a medicine withdrawal period"

> §12.1: *"The user reads it off the bottle. The app stores what they typed and shows its source as
> 'as entered by you.'"*
> §7.5: *"A wrong withdrawal number puts meat or milk into the food chain."*

### The failure mode the type must prevent

The naive model is `int? withdrawalDays`. It has three defects, in increasing severity:

1. `withdrawalDays ?? 0` is one careless keystroke away, and *reads as reasonable*.
2. **`0` is a real label value.** Many products genuinely print a zero-day withdrawal. A nullable
   int cannot distinguish "the label says zero" from "not recorded", so any code that treats null
   as zero is indistinguishable from code that is correct.
3. "Not applicable" (the label states no withdrawal for this species/route) is a third distinct
   fact, and it also collapses.

Nullable-int is therefore not a weak model, it is a *lossy* one. No amount of care at call sites
recovers information the type discarded.

### The type

```dart
/// What the withdrawal applies to. A single product routinely carries two
/// different numbers on the label; one field per treatment is a modelling bug.
enum WithdrawalTarget { meat, milk }

/// A withdrawal period is a THREE-STATE value.
sealed class WithdrawalPeriod {
  const WithdrawalPeriod();
}

/// The user read a number off the bottle. [days] MAY be 0 — that is a real
/// label value, not a fallback.
final class WithdrawalDays extends WithdrawalPeriod {
  final int days;
  final WithdrawalTarget target;

  /// No default. No optional parameter. No `int days = 0`.
  const WithdrawalDays._(this.days, this.target);

  /// The ONLY way to build one. Throws rather than coercing.
  factory WithdrawalDays.asEnteredByUser({
    required int days,
    required WithdrawalTarget target,
  }) {
    if (days < 0)    throw ArgumentError.value(days, 'days', 'must be >= 0');
    if (days > 1000) throw ArgumentError.value(days, 'days', 'implausible');
    return WithdrawalDays._(days, target);
  }
}

/// The label explicitly states no withdrawal applies. Distinct from zero days
/// and distinct from "I did not look".
final class WithdrawalNotApplicable extends WithdrawalPeriod {
  const WithdrawalNotApplicable();
}

/// The user deliberately skipped it. The app must never invent one, and must
/// never show a countdown or a clear date for this state.
final class WithdrawalNotRecorded extends WithdrawalPeriod {
  const WithdrawalNotRecorded();
}
```

Four mechanisms are stacked here:

| Mechanism | Level | What it stops |
|---|---|---|
| `sealed` + exhaustive `switch` | unrepresentable | forgetting the not-recorded case — [dart.dev: *"the compiler is aware of any possible direct subtypes… this allows the compiler to alert you when a switch does not exhaustively handle all possible subtypes"*](https://dart.dev/language/class-modifiers) |
| private `WithdrawalDays._` | unconstructible | any construction path that is not the named factory |
| **required named** `days:` with no default | unconstructible | `WithdrawalDays()` compiling at all |
| throwing on `days < 0` | unconstructible | a coerced value entering the system quietly |

And the plumbing:

| Mechanism | Level |
|---|---|
| `withdrawal_days INTEGER NULL` **plus** `withdrawal_state TEXT NOT NULL CHECK (withdrawal_state IN ('days','n/a','not_recorded'))` **plus** `CHECK ((withdrawal_state='days') = (withdrawal_days IS NOT NULL))` | unpersistable |
| A source-scanning test (below) | untestable-away |

Note the schema shape: the state discriminator is `NOT NULL`, so a row with no opinion cannot exist,
and the paired `CHECK` makes `days` present *exactly* when the state says so. Drift supports column
checks directly — `integer().check(...)`, per the
[drift tables docs](https://drift.simonbinder.eu/dart_api/tables/) — but the *cross-column* check
above needs a raw `customConstraints`/`.drift` table.

### The status type

The output has the same disease if you let it. `LocalDate? clearDate` re-introduces the null.

```dart
sealed class WithdrawalStatus { const WithdrawalStatus(); }

final class ClearsOn extends WithdrawalStatus {
  /// First civil date on which the animal is clear for the WHOLE day.
  final LocalDate date;
  /// The exact instant the label's period elapses. Shown alongside the date so
  /// the shepherd can check our arithmetic against their own.
  final Instant elapsesAt;
  const ClearsOn(this.date, this.elapsesAt);
}

final class NoWithdrawal      extends WithdrawalStatus { const NoWithdrawal(); }
final class WithdrawalUnknown extends WithdrawalStatus { const WithdrawalUnknown(); }
```

`WithdrawalUnknown` is what the treatment card renders when nothing was entered. It is a *state with
a name and a widget*, not an empty string. The countdown widget takes a `ClearsOn`, so it is
type-impossible to show a countdown for an unrecorded period.

### Provenance string

Rule 12.1 requires the words "as entered by you". That string must live with the disclaimer
constants (§1.3), not in the ARB — a translator can drop or soften an ARB string, and the app has no
mechanism to notice.

### The tests that prove it

Verified passing:

```dart
test('construction guards', () {
  expect(() => WithdrawalDays.asEnteredByUser(days: -1, target: WithdrawalTarget.meat),
      throwsArgumentError);
});

test('zero-day withdrawal is a real value, not "missing"', () {
  final s = computeWithdrawalStatus(
      treatedAt: localAt(2026, 3, 3, 20, 0),
      period: WithdrawalDays.asEnteredByUser(days: 0, target: WithdrawalTarget.meat)) as ClearsOn;
  expect(s.date.iso, '2026-03-04'); // clear all day tomorrow; today is partial
});

test('not recorded never yields a date', () {
  expect(computeWithdrawalStatus(
      treatedAt: localAt(2026, 3, 3, 20, 0), period: const WithdrawalNotRecorded()),
      isA<WithdrawalUnknown>());
});
```

Plus the source-level guard, which runs in CI and **passed after being self-tested against planted
offenders**:

```dart
test('SAFETY RULE 1: no fallback or default for a withdrawal period', () {
  final patterns = <RegExp>[
    RegExp(r'withdrawal\w*\s*[:=]\s*(0|1|const\s+Withdrawal)', caseSensitive: false),
    RegExp(r'withdrawal\w*\s*\?\?', caseSensitive: false),
    RegExp(r'int\s+withdrawal\w*\s*=\s*\d'),
    RegExp(r'WithdrawalDays\s*\('),   // the private ctor, called from outside
  ];
  // ... scan lib/**.dart except withdrawal.dart itself; expect no hits
});
```

---

## 1.2 "Never give veterinary advice" — what it means in code

> §12.2: *"No suggested doses, no diagnosis from symptoms, no 'you should' text anywhere."*

This one is genuinely ambiguous until you draw the line. Here is the line I propose, and it is a
line about **who supplied the number**:

### The computation rule

> **The app may arithmetic-transform a number the user supplied. The app may never originate a
> number that is a clinical decision.**

| Allowed — arithmetic on user data | Forbidden — origination |
|---|---|
| Counting down N days from the N *the user typed* | Suggesting N for a named product |
| "She has been penned 26 hours" (from the timestamp we captured) | "Ready to turn out" as a clinical claim (it is a *user-set threshold*, and must be labelled as such) |
| Average litter size across her recorded seasons | "This ewe should be culled" |
| "4.1 kg" from grams the user weighed | "That is light for a twin" |
| Losses by cause, exactly as the user categorised them | "These losses indicate a nutritional deficiency" |
| Colostrum volume the user recorded | "She needs 215 ml of colostrum" |

That last row is not hypothetical. AHDB's own guidance says *"Make sure lambs receive 50 ml/kg of
colostrum within the first four to six hours of life"*
([Reducing Lamb Losses, p.16](https://projectblue.blob.core.windows.net/media/Default/About%20AHDB/Reducing%20Lamb%20Losses%202020.pdf)).
The app has the birthweight. Multiplying is one line of code and would be *helpful*. It is a dose
suggestion and it is banned. Likewise AHDB's *"Birth weights more than 1 kg lighter than these
suggest undernutrition of the ewe during late pregnancy"* — the app has the birthweight and the
birth type and could render that sentence. It must not.

Note the subtlety in row 2: the pen board's "ready to turn out" badge (§7.4) is fine **because the
threshold is user-set**. It is the user's own rule played back. The label must say so — "past your
24 h threshold", not "ready".

### The content policy as executable code

Two halves: a banned-pattern list, and an allowlist where each exception carries a written reason.

```dart
abstract final class ContentPolicy {
  static final List<({RegExp pattern, String why})> bannedInUserFacingText = [
    (pattern: RegExp(r'\byou should\b', caseSensitive: false),
     why: 'imperative clinical advice'),
    (pattern: RegExp(r'\b(we|the app) recommends?\b', caseSensitive: false),
     why: 'app asserting judgement'),
    (pattern: RegExp(r'\brecommended (dose|dosage|amount|rate)\b', caseSensitive: false),
     why: 'dose suggestion'),
    (pattern: RegExp(r'\b\d+\s?(ml|mg|cc|iu)\s?/\s?kg\b', caseSensitive: false),
     why: 'a computed dose'),
    (pattern: RegExp(r'\b(diagnos|prognos)', caseSensitive: false),
     why: 'diagnosis'),
    (pattern: RegExp(r'\b(indicates?|suggests?) (a |an )?(problem|deficiency|infection|disease)\b',
       caseSensitive: false),
     why: 'clinical inference from data'),
    (pattern: RegExp(r'\b(normal|healthy|abnormal|too (low|high|light|heavy))\b',
       caseSensitive: false),
     why: 'clinical judgement on a user value'),
    (pattern: RegExp(r'\bcall (the |your )?vet\b', caseSensitive: false),
     why: 'instruction, even a safe-sounding one'),
    (pattern: RegExp(r'\b(default|typical|usual|standard) withdrawal\b', caseSensitive: false),
     why: 'implies the app knows a withdrawal period'),
    (pattern: RegExp(r'\b(compliance|regulatory|statutory|official) record\b',
       caseSensitive: false),
     why: 'safety rule 3'),
  ];

  /// Reviewed exceptions. Keys REFERENCE the single definition; they never
  /// re-type the string, or the "defined in exactly one place" guard fails.
  static final Map<String, String> allowlist = {
    Disclaimers.exportFooter: 'This is the disclaimer itself (safety rule 3).',
  };
}
```

`call the vet` is banned deliberately. It *sounds* like the safe thing to say, and it is still the
app making a clinical call about a specific animal at a specific moment. If the store listing needs
a general statement, it belongs in a static About screen, not in a data-driven string.

### The CI check, and its self-test

The check scans string literals in `lib/**.dart` and message values in `lib/l10n/*.arb`. Crucially,
it is **self-tested in both directions** — a guard that never fires is indistinguishable from a
guard that is broken.

```dart
test('the guard actually catches things (self-test)', () {
  const offenders = [
    'You should give 2 ml/kg of colostrum.',
    'A low birth weight indicates a problem with ewe nutrition.',
    'Default withdrawal for this product is 28 days.',
    'This is your official record for compliance.',
  ];
  for (final o in offenders) {
    expect(ContentPolicy.bannedInUserFacingText.any((r) => r.pattern.hasMatch(o)), isTrue);
  }
});

test('the guard does not reject legitimate app copy (self-test)', () {
  const ok = [
    'Birth type is twin but 3 lambs are recorded.',
    'Withdrawal period as entered by you from the product label.',
    '412 · 3 seasons · avg 2.0 · assisted twice',
    'Clear on 11 Mar. Period ends 10 Mar 20:00.',
    'Recorded automatically at 03:21.',
  ];
  for (final s in ok) {
    expect(ContentPolicy.bannedInUserFacingText.where((r) => r.pattern.hasMatch(s)), isEmpty);
  }
});
```

Output: `guard rejects all 4 planted offenders`, and zero false positives on the five real strings.

**Gotcha found while building this** (belongs in Pitfalls too): a naive `file.contains('some long
phrase')` source scan **misses long strings**, because Dart wraps them across adjacent string
literals and the phrase is never contiguous in the source text. The guard must extract string
literals and join them before matching. My first version of the disclaimer guard failed for exactly
this reason.

### The other half of rule 2: the bundled content

§11 ships "roughly 40 authored terms — lambing ease scale descriptions, common death causes, common
malpresentations, common treatment routes". Two of those lists are where advice leaks in.

- **Lambing ease descriptions.** Use the descriptive scale, not an interpretive one. SRUC's
  technical note gives exactly the spec's 1–5:
  1 No assistance · 2 Slight assistance by hand · 3 Severe assistance · 4 Non-surgical veterinary
  assistance · 5 Veterinary assistance, surgery required
  ([SRUC TN747](https://www.sruc.ac.uk/media/3ixfnvl5/tn-747-recording-traits-of-lambing.pdf); SRUC
  adds a 6th, "Elective caesarean"). These are descriptions of *what the operator did*, containing
  no judgement. Adopt them verbatim; they are generic husbandry vocabulary and match the spec's
  scale exactly.
- **Death causes.** The spec's list (starvation, hypothermia, watery mouth, joint ill, crushed,
  stillborn, unknown, other) is a *vocabulary the user picks from*, which is fine. It becomes advice
  the moment the app infers one. Never pre-select a cause from age-at-death or birthweight.

---

## 1.3 "Never present the app as a compliance record" — where the string lives

> §12.3: *"It is a notebook… the export should say so in its footer."*

### Single definition, referenced everywhere

```dart
/// The ONLY place these strings exist. Not in the ARB (they must not be
/// translated away or dropped by a translator), not inlined at call sites.
abstract final class Disclaimers {
  static const String exportFooter =
      'Shed Book is a personal notebook. It is not a statutory medicine '
      'record, holding register, or movement record, and must not be '
      'presented as one. All entries are as recorded by the user.';

  static const String withdrawalProvenance = 'as entered by you';

  static const String withdrawalCaveat =
      'Withdrawal period as entered by you from the product label. '
      'Shed Book does not know any product and suggests no value. '
      'Check the label.';
}
```

`abstract final class` (Dart 3) is the right shape: it cannot be instantiated *or* extended, so
nobody can subclass it and shadow the string.

### Making it undroppable, per format

The mechanism is not "remember to append the footer". It is: **the writer cannot be constructed
without it, and a golden test reads the produced bytes back.**

| Format | Where the footer goes | Why there |
|---|---|---|
| **CSV** | A final row: `# <disclaimer>` (a single field, first column). | A leading `#` is ignored by every importer I know of, but survives a plain-text read and a print-out. Alternative — a comment header — gets cut when someone pastes the data range. |
| **PDF flock book** | Page footer on **every** page, not just the last. | Inspectors and vets see loose pages. |
| **Medicine record PDF** | Page footer **plus** a boxed statement under the title. | This is the one someone will hand to an inspector. It must be unmissable on page 1. |
| **JSON backup** | Top-level `"_disclaimer"` key, first. | Restores round-trip it; and someone will open it in a text editor. |

The structural bit:

```dart
final class ExportEnvelope {
  final String disclaimer;
  final Instant generatedAt;
  final String appVersion;
  const ExportEnvelope._(this.disclaimer, this.generatedAt, this.appVersion);

  /// No other constructor. `disclaimer` is not a parameter.
  factory ExportEnvelope.standard({required Instant now, required String appVersion}) =>
      ExportEnvelope._(Disclaimers.exportFooter, now, appVersion);
}

// Every writer signature takes it. There is no writer that does not.
String writeLambCsv(ExportEnvelope env, List<LambRow> rows);
Future<Uint8List> writeMedicinePdf(ExportEnvelope env, List<TreatmentRow> rows);
```

And the guards:

```dart
test('SAFETY RULE 3: the export disclaimer exists in exactly one place', () {
  // counts files whose EXTRACTED LITERALS match /statutory\s+medicine|holding\s+register/
  // expects exactly 1, and expects it to be policy/disclaimers.dart
});

// Golden tests, one per format:
test('every export artifact carries the footer', () {
  expect(writeLambCsv(env, rows),      contains(Disclaimers.exportFooter));
  expect(writeEweCsv(env, rows),       contains(Disclaimers.exportFooter));
  expect(writeTreatmentCsv(env, rows), contains(Disclaimers.exportFooter));
  expect(jsonEncode(backup(env, db)),  contains('_disclaimer'));
  // PDFs: assert the text layer, not the bytes
});
```

The single-definition test **caught a real duplication during authoring** — the banned-phrase
allowlist had re-typed the disclaimer text. The fix was to make the allowlist key
`Disclaimers.exportFooter` rather than a literal, which is also the correct design.

### One more place the string belongs

The **Export screen** itself (§9.11) and the free-tier/purchase copy. If the App Store description
implies statutory recording, no footer saves you. Put a one-liner on the export screen above the
buttons.

---

## 1.4 "Never silently correct a user's entry" — warning vs mutation

> §12.4: *"If a birth type of 'twin' has three lambs attached, flag it; do not fix it."*

### The type

```dart
/// Advisory only. There is no `fix()`, no `corrected` field, no `apply()`.
/// A Warning cannot mutate anything because it holds nothing mutable and
/// exposes no writer.
final class Warning {
  final WarningCode code;
  final String message;      // what we observed, never what to do
  final String? fieldPath;   // for scroll-to-field, not for editing
  const Warning(this.code, this.message, {this.fieldPath});
}

enum WarningCode {
  birthTypeLambCountMismatch,
  lambingBeforeSeasonStart,
  lambingInFuture,
  lambingLongBeforeCapture,
  implausibleBirthWeight,
  timeDoesNotExistLocally,
  fosterToSelf,
  deathBeforeBirth,
  duplicateTagInFlock,
}

/// Marker: a value that has been looked at by the validator. Carries the
/// UNCHANGED value plus advisories. There is deliberately no way to get a
/// "cleaned" value out of it.
final class Reviewed<T> {
  final T value;             // byte-identical to what the user supplied
  final List<Warning> warnings;
  const Reviewed(this.value, this.warnings);
  bool get hasWarnings => warnings.isNotEmpty;
}
```

Read the negative space. `Warning` has no reference to a repository, no `T corrected`, no callback.
`Reviewed<T>` has no `T get cleaned`. The API surface for mutation does not exist, so no amount of
call-site carelessness produces one.

### The four structural guarantees

1. **Validators are pure top-level functions** taking plain data and returning `List<Warning>`. They
   take no DAO, no `Ref`, no repository. They *cannot* write because they hold no writer.
2. **The schema has no `warnings` column.** Warnings are recomputed on read. A derived value that is
   never persisted can never diverge from its source, and can never be mistaken for user data on
   export.
3. **Warnings never gate the save.** The save button is always live. This is a 3am requirement
   (§5: "assume the phone dies… every write is committed immediately") *and* a correctness one: a
   blocked save produces a lost record, which is worse than a flagged one.
4. **The message describes an observation.** `'Birth type is twin but 3 lambs are recorded.'` — no
   verb directed at the user, no "should".

### How it surfaces at 3am

Not a modal. Not a red field border alone. A persistent, tappable **amber strip** under the field,
60 pt tall, tapping it scrolls to the field. It reappears every time the record is opened, because
the record is still contradictory. It never blocks, never auto-dismisses, never nags twice within a
screen.

### Verified

```
twin with three lambs warns and does not change the type
  "Birth type is twin but 3 lambs are recorded."
quint+ can never contradict          ← BirthType.quintPlus has no expected count
```

```dart
int? expectedLambCount(BirthType t) => switch (t) {
      BirthType.single    => 1,
      BirthType.twin      => 2,
      BirthType.triplet   => 3,
      BirthType.quad      => 4,
      BirthType.quintPlus => null, // 5+ : open ended, cannot contradict
    };
```

The `null` for `quintPlus` matters: "quad or more" in the spec means the fifth case is open-ended, so
a contradiction is *undefined*, not *false*. Encoding that as `5` would produce a false warning for
every set of sextuplets.

### Rule 4 also has a *storage* dimension, and it is the one people miss

Storing 4.31 kg as `43` decigrams-of-a-kilogram and displaying `9.5 lb` when the user typed `9.4 lb`
is a silent correction. It is invisible in code review, because the code contains no "fix"
anywhere — the corruption is in the *choice of canonical unit*. See Part 2, where this is measured.

Likewise, `DateTime(2026, 3, 29, 1, 30)` in Europe/London **silently returns 02:30** with no
exception. That is Dart correcting a user's entry. See Part 3.

---

## 1.5 "Timestamps are honest" — a provenance-carrying value type

> §12.5: *"Auto-captured time is labelled as such; edited time is labelled as edited."*

```dart
enum TimeSource { autoCaptured, userEntered, userEdited }

final class RecordedTime {
  /// The value that counts. Always UTC epoch millis.
  final Instant effective;

  /// The moment the row was first written. Never changes. Never editable.
  final Instant capturedAt;

  /// Present only when [source] is userEdited: what the app originally held.
  final Instant? originalEffective;

  final TimeSource source;

  const RecordedTime._(this.effective, this.capturedAt, this.originalEffective, this.source);

  /// Auto-captured: effective == the moment of the write.
  factory RecordedTime.capture(Instant now) =>
      RecordedTime._(now, now, null, TimeSource.autoCaptured);

  /// The user typed a time at creation (a deferred entry).
  factory RecordedTime.entered({required Instant effective, required Instant now}) =>
      RecordedTime._(effective, now, null, TimeSource.userEntered);

  /// Preserves the FIRST effective value ever held, across any number of
  /// edits. There is no setter and no way to clear [originalEffective].
  RecordedTime editedTo(Instant newEffective) =>
      RecordedTime._(newEffective, capturedAt, originalEffective ?? effective,
          TimeSource.userEdited);

  bool get isEdited => source == TimeSource.userEdited;

  /// Never returns an empty string: the label is part of the value.
  String get provenanceLabel => switch (source) {
        TimeSource.autoCaptured => 'recorded automatically',
        TimeSource.userEntered  => 'time entered by you',
        TimeSource.userEdited   => 'time edited by you',
      };
}
```

Three fields, three distinct facts, none derivable from the others:

- `effective` — *when the lambing happened* (what the shepherd cares about)
- `capturedAt` — *when we found out* (immutable audit anchor, and the thing that makes the
  success criterion "more than half of entries within five minutes of the event" measurable)
- `originalEffective` — *what we first thought*, preserved across an unbounded chain of edits

The distinction between `userEntered` and `userEdited` is not pedantry: a deferred entry typed at
7am for a 3:20am lambing was never wrong, whereas an edited one was. The spec's §15 success metric
("more than half of entries are made within five minutes of the event") is computable *only* from
`capturedAt − effective`, and only if `capturedAt` is genuinely immutable.

### Verified

```
auto-captured time reports itself as auto-captured
  "recorded automatically"
editing preserves the original across MANY edits
  effective 2026-03-04 03:30, originally 2026-03-04 07:00, "time edited by you"
a deferred entry is labelled entered, not auto-captured   ← capturedAt − effective = 3h45m
provenance label is never empty for any source
```

The `provenanceLabel` test iterates `TimeSource.values`, so adding a fourth source without a label
fails the switch at compile time *and* fails the test.

### How it survives export

The single most common way provenance is lost is a CSV with one `date` column. The export must
carry all four facts as separate columns, in every shape:

| CSV column | Content | Notes |
|---|---|---|
| `event_time_local` | `2026-03-04T03:20:00.000+00:00` | ISO 8601 **with offset** — what the shepherd saw |
| `event_time_utc` | `2026-03-04T03:20:00.000Z` | unambiguous, sortable, machine-safe |
| `time_source` | `auto` \| `entered` \| `edited` | the stable key, never the localised label |
| `time_recorded_at_utc` | `2026-03-04T07:05:00.000Z` | when the row was written |
| `time_originally_utc` | `2026-03-04T07:00:00.000Z` or empty | only for `edited` |

Rules:

- **Both** local-with-offset and UTC. Local-only is ambiguous on the DST fall-back hour; UTC-only is
  unreadable to a shepherd who wants to see "03:20".
- `time_source` is the **enum key**, not the label. A translated CSV is not machine-readable, and
  the terminology overlay must never touch it (see Part 6).
- **PDF**: append a marker to the time — `03:20` vs `03:20 †` — with a footer legend
  `† time edited by the user`. A PDF with no legend and no marker is a PDF that lies by omission.
- **JSON backup**: the whole `RecordedTime` object, all four fields, so a restore is lossless.

---

# Part 2 — Value objects and units

> §7.10: *"Units: kg / lb, °C / °F."*

## 2.1 The canonical-storage rule

> **One canonical unit is stored. Display units are computed at the widget boundary and are never
> assigned to a variable that flows back toward the database.**

The bug this prevents is the **display-unit round trip**: the user enters 9.5 lb; you store 9.5 with
a unit flag; they switch to kg and see 4.309; they open the edit screen, which pre-fills 4.3 (1 dp);
they save without touching it; now the record is 4.3 kg = 9.48 lb. The value drifted because nobody
edited it. That is a silent correction of a user's entry (rule 4) with no line of code to blame.

Concretely:

- The DB column stores canonical units only. There is no `unit` column on a measurement.
- The unit preference lives in `Settings` and affects **rendering and parsing only**.
- The form's controller is seeded from the canonical value each time it opens; on save it parses the
  *typed text* into canonical, it does not re-derive from the old canonical.
- Extension types make the compiler enforce the boundary.

## 2.2 What precision does a lamb birthweight actually need?

**The domain range.** AHDB's optimum birthweights for 70–85 kg ewes to a terminal sire:
single **4.5–6.0 kg**, twin **3.5–4.5 kg**, triplet **>3.5 kg**; hill breeds run **1.0–1.5 kg
lighter**
([Reducing Lamb Losses, p.16](https://projectblue.blob.core.windows.net/media/Default/About%20AHDB/Reducing%20Lamb%20Losses%202020.pdf)).
So the plausible band is roughly **1.5 kg to 8.0 kg**, with warnings outside ~1.0–10.0 kg.

**What the recording standard asks for.** SRUC's technical note says simply *"Record actual birth
weight (kg)"*
([TN747](https://www.sruc.ac.uk/media/3ixfnvl5/tn-747-recording-traits-of-lambing.pdf)) — kg, no
stated precision.

**What the kit gives.** I could not find a primary-source specification for a shepherd's lamb scale
(searches returned antique Salter spring balances; see Sources for the failed attempts). What is
uncontroversial: the field kit is a hanging spring balance or a digital luggage/hook scale, and the
practical readable resolution is **0.1 kg**, occasionally 0.05 kg or 50 g on a digital hook scale.
Nobody in a lambing shed reads a lamb to the gram. **Treat this as an open question worth 20 minutes
with a real shepherd** (see Open Questions) — but note that it does not change the answer below,
because the constraint that fixes the canonical unit is *not* scale resolution.

**The constraint that actually fixes it is lb↔kg round-tripping**, and it is much tighter than
scale resolution. I measured it.

### The experiment (real output)

```
grams: lb entry at 0.1 lb survives round-trip at 1 dp          PASS  (241 values, 0 failures)
grams: lb entry at 0.01 lb survives round-trip at 2 dp         PASS  (2401 values, 0 failures)
grams: lb+oz entry survives round-trip to nearest ounce        PASS  (400 combos, 0 failures)
grams: kg entry at 0.01 kg is exact                            PASS

COUNTEREXAMPLE: storing 0.1 kg (hectograms) corrupts a lb entry
  0.1kg storage corrupts 132/241 lb values, e.g. (1.0 -> 1.1, 1.2 -> 1.1, 1.4 -> 1.3, 1.6 -> 1.5)

milliCelsius: F entry at 0.1 F survives round-trip at 1 dp     PASS  (201 values, 0 failures)

COUNTEREXAMPLE: storing 0.1 C (deciCelsius) silently rewrites F entries
  0.1C storage rewrites 89/201 F values, e.g. (90.2 -> 90.1, 90.4 -> 90.3, 90.6 -> 90.7, ...)

COUNTEREXAMPLE: 0.01 C (centiCelsius) is the minimum that works
  0.01C storage rewrites 0/201 F values
```

Read the 0.1 kg line again. A user in an imperial county types **1.2 lb** for a tiny hill triplet and
the app shows them **1.1 lb** on the next screen. That is a rule-4 violation produced entirely by a
storage decision, in **55% of possible entries**. It would never appear in a code review.

**Conclusion:** the canonical unit must be fine enough that the *display* rounding, not the storage
rounding, is what the user sees.

- **Mass: integer grams.** 1 lb ≡ 453.59237 g exactly (international avoirdupois pound), so grams is
  not an exact lb divisor — but the residual error is < 0.5 g ≈ 0.0011 lb, three orders of magnitude
  below any display. Grams also makes 0.1 kg exactly representable, needs no float in the DB, sorts
  and sums exactly in SQL, and fits any lamb in a `SMALLINT`'s worth of range.
- **Temperature: integer milli-°C.** 0.01 °C is the *minimum* that survives a 1 dp °F round trip;
  0.001 °C gives headroom for a 2 dp display without re-migrating. Millidegrees also keeps the
  affine conversion (`°F = °C·9/5 + 32`) away from the rounding boundary.

## 2.3 The value types (compiled and tested)

```dart
/// Canonical mass unit: whole grams. Non-transparent extension type so a raw
/// `int` can never be passed where a mass is expected.
extension type const Grams(int value) {
  static const double _gPerLb = 453.59237;     // exact by definition
  static const double _gPerOz = 28.349523125;  // exact by definition

  factory Grams.fromKilograms(double kg) => Grams((kg * 1000).round());
  factory Grams.fromPounds(double lb)    => Grams((lb * _gPerLb).round());
  factory Grams.fromPoundsOunces(int lb, double oz) =>
      Grams((lb * _gPerLb + oz * _gPerOz).round());

  double get inKilograms => value / 1000.0;
  double get inPounds    => value / _gPerLb;
  int    get wholePounds => inPounds.floor();
  double get remainderOunces => (value - wholePounds * _gPerLb) / _gPerOz;
}

/// Canonical temperature: thousandths of a degree Celsius.
extension type const MilliCelsius(int value) {
  factory MilliCelsius.fromCelsius(double c)    => MilliCelsius((c * 1000).round());
  factory MilliCelsius.fromFahrenheit(double f) => MilliCelsius(((f - 32) * 5 / 9 * 1000).round());
  double get inCelsius    => value / 1000.0;
  double get inFahrenheit => value / 1000.0 * 9 / 5 + 32;
}
```

**Why extension types and not classes.** They are
[*"essentially zero cost… static-only and compiled away at run time"*](https://dart.dev/language/extension-types)
— no allocation for a value that appears on every lamb row in a 400-ewe flock list. Non-transparent
(no `implements int`) means `Grams` is *"a completely new type, distinct from its representation
type"*, so `weighLamb(4310)` will not compile.

**Three constraints I hit and verified**, which belong in the Pitfalls section too:

1. `extension type const Grams(int value)` **is** valid — the `const` modifier compiles on Dart
   3.12.2. Confirmed by `dart analyze`.
2. **An extension type can only `implements` a supertype of its representation type.**
   `extension type Instant(int) implements Comparable<Instant>` fails with
   `extension_type_implements_not_supertype` because `int` implements `Comparable<num>`, not
   `Comparable<Instant>`. So no `@override int compareTo`, and no free `.sort()`. Provide a plain
   `compareTo` method and explicit comparators.
3. **They erase at runtime.** `Grams` and any other `extension type X(int)` are the *same* runtime
   type — [*"at run time, there is absolutely no trace of the extension type"*](https://dart.dev/language/extension-types).
   `is`/`switch` on runtime type will not discriminate them. Consequence: **never build an extension
   type for a display unit.** There is exactly one canonical mass type and exactly one canonical
   temperature type, and pounds/Fahrenheit exist only as `double` returns from a getter, consumed
   immediately by a formatter.

### Rounding: use `round()`, and say so

`(kg * 1000).round()` is banker's-rounding-free half-away-from-zero in Dart, which is what a user
expects. Do **not** use `toInt()` (truncates toward zero — systematically light) and do not use
`ceil()`/`floor()`.

## 2.4 The 3am consequence: own the decimal separator

Parsing `"4,3"` versus `"4.3"` is a real hazard — a German or French keyboard produces a comma, and
`double.parse('4,3')` throws. `NumberFormat.decimalPattern(locale).parse` handles it but then
`'4.3'` may throw in a comma locale, which is worse (a UK shepherd whose phone is set to French).

**Do not use the OS keyboard for weights.** §7.1 already mandates a giant in-app numeric keypad for
tag entry; use the same component for weight, with one decimal key that always emits `.`. Benefits:
one code path, no locale ambiguity, no keyboard-dismissal jank, and 60×60 pt targets by
construction. This is a case where the offline/3am constraint makes the *simpler* engineering choice
also the correct one.

For belt-and-braces on any free-text numeric field, normalise before parsing and **reject** on
ambiguity rather than guessing:

```dart
double? parseUserNumber(String raw) {
  final s = raw.trim().replaceAll(' ', '');
  final commas = ','.allMatches(s).length, dots = '.'.allMatches(s).length;
  if (commas > 0 && dots > 0) return null;      // ambiguous: reject, don't guess
  if (commas > 1 || dots > 1)  return null;
  return double.tryParse(s.replaceAll(',', '.'));
}
```

Returning `null` (→ a `Warning`) rather than guessing is rule 4 again: guessing that `4,3` means
`43` would be a silent correction.

---

# Part 3 — Time modelling

This is the hardest correctness area in the app, and the one where a plausible-looking line of code
is wrong by exactly one hour, once a year, in a way that puts meat in the food chain.

## 3.1 The rule: instants vs civil dates

> **If it is *a moment that happened*, it is an instant. If it is *a square on a calendar*, it is a
> civil date. A civil date is not a `DateTime` and an instant is not a date string.**

| Field | Kind | Storage | Why |
|---|---|---|---|
| `Lambing.datetime` | **instant** | `INTEGER` UTC epoch ms | A birth happened at a moment. Ordering, "hours since", and the colostrum reminder are all elapsed-time questions. |
| `Lambing.local_date` | **civil date** (denormalised) | `TEXT 'YYYY-MM-DD'` | Grouping key for the spread histogram. Written at insert from the device zone. |
| `Pen.entered_at`, `turned_out_at` | **instant** | `INTEGER` epoch ms | "Hours since penned" is elapsed physical time. |
| `Treatment.date` | **instant** | `INTEGER` epoch ms | The withdrawal clock starts at the moment of last administration (VICH). A date alone loses up to 24 h of safety margin. |
| `Treatment.clear_date` | **derived civil date** | *not stored* | Recompute. Storing it means a stale value survives an edit of `date` or `withdrawal_days`. |
| `Lamb.death_date` | **civil date** | `TEXT 'YYYY-MM-DD'` | The user usually knows the day, not the minute. Forcing a time invents precision. |
| `Season.start_date` | **civil date** | `TEXT 'YYYY-MM-DD'` | "The season starts on 1 March" is a calendar fact. |
| `Reminder.due_at` | **instant** | `INTEGER` epoch ms | Fired by the OS at an absolute moment. |
| `Note.created_at`, all `capturedAt` | **instant** | `INTEGER` epoch ms | Audit anchors. |
| `Ewe.dob` | **civil date** (usually just a year) | `TEXT` `'YYYY'`/`'YYYY-MM'`/`'YYYY-MM-DD'` | Almost never known to the day. A partial date is a real state; do not pad it to 1 January. |

**Why epoch millis and not drift's `DateTime` columns.** Drift offers two modes:
integer unix **seconds** (default), or ISO-8601 text
([drift datetime guide](https://drift.simonbinder.eu/guides/datetime-migrations/)). Both are worse
here than an explicit `INTEGER` + type converter:

- The integer mode is **seconds** and, per the docs, *"drift always returns a non-UTC value. So even
  when UTC date times are stored, this information is lost when retrieving rows."*
- The text mode is more faithful but stores a *local* value with an offset for local `DateTime`s,
  which mixes instant and civil semantics in one column — exactly the confusion this section exists
  to prevent.
- The mode is a **global build-flag decision** (`store_date_time_values_as_text`) that applies to
  every `DateTime` column in the app, and *"toggling this behavior is not compatible with existing
  database schemas"*. Committing the whole app's time model to a build flag is a bad trade.

Instead: `IntColumn` + a converter to `Instant`, and `TextColumn` + a converter to `LocalDate`. The
semantics are visible in the *Dart type of the column*, which is the whole point.

## 3.2 The types

```dart
extension type const Instant(int epochMillis) {
  factory Instant.fromDateTime(DateTime d) => Instant(d.millisecondsSinceEpoch);
  DateTime get utc   => DateTime.fromMillisecondsSinceEpoch(epochMillis, isUtc: true);
  DateTime get local => DateTime.fromMillisecondsSinceEpoch(epochMillis);
  Instant  plus(Duration d)        => Instant(epochMillis + d.inMilliseconds);
  Duration difference(Instant o)   => Duration(milliseconds: epochMillis - o.epochMillis);
  bool     isBefore(Instant o)     => epochMillis < o.epochMillis;
  bool     isAfter(Instant o)      => epochMillis > o.epochMillis;
  int      compareTo(Instant o)    => epochMillis.compareTo(o.epochMillis);
}

final class LocalDate implements Comparable<LocalDate> {
  final int year, month, day;
  const LocalDate(this.year, this.month, this.day);

  factory LocalDate.parse(String iso) { /* strict YYYY-MM-DD, throws otherwise */ }

  /// The civil date on which [i] fell, in the device's current local zone.
  factory LocalDate.of(Instant i) {
    final d = i.local;
    return LocalDate(d.year, d.month, d.day);
  }

  String get iso => '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  /// Calendar arithmetic, done in UTC so no DST can perturb it.
  LocalDate plusDays(int n) {
    final d = DateTime.utc(year, month, day).add(Duration(days: n));
    return LocalDate(d.year, d.month, d.day);
  }

  int daysUntil(LocalDate o) => DateTime.utc(o.year, o.month, o.day)
      .difference(DateTime.utc(year, month, day)).inDays;

  /// Start-of-day instant for this civil date in the device's local zone.
  Instant startOfDayLocal() => Instant.fromDateTime(DateTime(year, month, day));

  @override int compareTo(LocalDate o) => iso.compareTo(o.iso);   // ISO sorts lexically
  @override bool operator ==(Object o) => o is LocalDate && o.iso == iso;
  @override int get hashCode => Object.hash(year, month, day);
  @override String toString() => iso;
}
```

`LocalDate.plusDays` and `daysUntil` route through `DateTime.utc` deliberately: UTC has no DST, so
adding `Duration(days: n)` there is exactly *n* calendar days. Doing the same on a *local* `DateTime`
is the bug in §3.3. `LocalDate` also sorts by string, so `ORDER BY local_date` in SQL is correct and
index-friendly with zero conversion.

`Instant` as an extension type is a compile-time-checked `int`: it costs nothing per row, and
`someInt` cannot be passed where an `Instant` is expected.

## 3.3 What Dart actually does across a DST transition (measured)

Run with `TZ=Europe/London`. UK clocks go forward 2026-03-29 and back 2026-10-25.

```
probe: DateTime.add adds ABSOLUTE time, not civil days
  20:00 26-Mar + Duration(days:7)  = 2026-04-02 21:00:00.000  (offset 1:00)
  civil +7 days keeping 20:00      = 2026-04-02 20:00:00.000  (offset 1:00)
  elapsed absolute for civil +7    = 167:00:00.000000     ← ONE HOUR SHORT
  elapsed absolute for Duration +7 = 168:00:00.000000

probe: autumn fall-back
  +Duration(7d) = 2026-10-29 19:00 ; civil+7 = 2026-10-29 20:00
  elapsed civil = 169:00:00.000000 ; elapsed dur = 168:00:00.000000

probe: hours since penned across spring forward
  penned Sat 22:00, now Sun 08:00 → the wall clock says 10 h
  DateTime.difference = 9:00:00.000000
  via epoch millis    = 9:00:00.000000

probe: nonexistent and ambiguous local times
  DateTime(2026,3,29,1,30)  => 2026-03-29 02:30:00.000 (offset 1:00)   ← SILENTLY MOVED
  DateTime(2026,10,25,1,30) => 2026-10-25 01:30:00.000 (offset 1:00)   ← one of two
```

The behaviour matches the documented contract:
[`DateTime.add`](https://api.dart.dev/stable/dart-core/DateTime/add.html) — *"If the resulting
DateTime has a different daylight saving offset than `this`, then the result won't have the same
time-of-day as `this`, and may not even hit the calendar date 50 days later… Be careful when working
with dates in local time."*
And [`DateTime`](https://api.dart.dev/stable/dart-core/DateTime-class.html) — *"the difference
between two midnights in local time may be less than 24 hours times the number of days between them,
if there is a daylight saving change in between."*

Three actionable facts:

1. **`Duration` arithmetic on `DateTime` is absolute-time arithmetic.** It is the *right* tool for
   elapsed-time questions and the *wrong* tool for calendar questions.
2. **`DateTime.difference` is absolute.** `Instant.difference` (epoch subtraction) gives the same
   answer. Good — one semantic, no surprises.
3. **A nonexistent local time is silently moved forward with no exception.** This is Dart correcting
   a user's entry, and it must be caught (§3.6).

## 3.4 The withdrawal period: days or hours? — and what the bottle means

This is a domain question with a food-safety consequence, so it deserves the primary source.

**VICH** (the international veterinary-medicines harmonisation body, whose members include EMA, FDA,
JMAFF) defines it as:

> *"A withdrawal period (also called withholding period, or for milk or eggs sometimes discard time)
> is the minimum period between the last administration of a veterinary medicinal product to an
> animal and the production of foodstuffs from that animal, i.e. slaughter, taking milk or eggs or
> honey for human consumption…"*
>
> *"Withdrawal periods are expressed in days (for tissues, milk and eggs), milkings (normally based
> on 12 hour milking intervals) or degree days (for fish). Where the calculated withdrawal period is
> a fraction of a day or milking, **it is rounded up to the next full day or milking.**"*
>
> — [VICH, *Withdrawal periods for veterinary medicinal products*, Aug 2020](https://vichsec.org/wp-content/uploads/2024/10/Report%20on%20calculation%20of%20withdrawal%20periods%20-final%20August%202020.pdf)

Three things follow, and they are not obvious:

1. **It is fundamentally an elapsed-time quantity** — a residue-depletion curve as a *function of
   time after the last administration* — that has been *rounded up* to whole days for the label.
   It is not "N sleeps".
2. **The clock starts at the last administration**, i.e. at a *moment*, not at midnight. Corroborated
   by [NADIS](https://www.nadis.org.uk/disease-a-z/cattle/medicine-usage/): *"the specific amount of
   time after the last dose of the medicine has been administered before levels in the meat or milk
   have fallen below the maximum residue level"*, and by
   [Fimea](https://fimea.fi/en/veterinary/withdrawal_period_and_mrl/what_is_a_withdrawal_period):
   *"the minimum period of time from administering the last dose of medication and the production of
   meat or other animal-derived products for food."*
3. **The regulator already rounded up**, so a second rounding in the same direction is safe; rounding
   in the *other* direction eats the regulator's margin.

### The recommendation

> **Compute `elapsesAt = treatmentInstant + N × 24 h` in absolute time. Then take the first local
> civil midnight at or after `elapsesAt` as the "clear on" date. Show both.**

```dart
WithdrawalStatus computeWithdrawalStatus({
  required Instant treatedAt,
  required WithdrawalPeriod period,
}) => switch (period) {
      WithdrawalNotRecorded()   => const WithdrawalUnknown(),
      WithdrawalNotApplicable() => const NoWithdrawal(),
      WithdrawalDays(:final days) => () {
          final elapsesAt   = treatedAt.plus(Duration(hours: days * 24));
          final dayOfElapse = LocalDate.of(elapsesAt);
          final clear = elapsesAt.epochMillis == dayOfElapse.startOfDayLocal().epochMillis
              ? dayOfElapse
              : dayOfElapse.plusDays(1);
          return ClearsOn(clear, elapsesAt);
        }(),
    };
```

Verified:

```
treated 2026-03-03 20:00, 7 d -> elapses 2026-03-10 20:00, clear all day 2026-03-11
midnight treatment: no extra day is added                 -> 2026-03-10
zero-day withdrawal is a real value, not "missing"        -> 2026-03-04
SAFETY: civil-day arithmetic under-counts across a spring-forward
  civil +7d = 2026-04-02 20:00 (only 167 h elapsed)
  absolute  = 2026-04-02 21:00 (168 h elapsed)
```

### Honest about the trade-off

The evening-treatment case gives **11 March**, whereas a shepherd counting on their fingers from
3 March gets **10 March**. The app is a day more conservative than the folk method. Two options:

- **(A, recommended) Show both facts.** *"Clear on **Wed 11 Mar** · 7 days from Tue 3 Mar 20:00 ends
  Tue 10 Mar 20:00."* The date is the safe one; the sentence underneath is the arithmetic, so a
  shepherd who disagrees can see exactly why and is not left thinking the app is broken.
- **(B, rejected) A setting for "count whole days from the day of treatment."** Rejected: it is a
  setting whose wrong value puts meat in the food chain, buried in a screen nobody visits at 3am,
  and it would let the app produce a number that is *less* conservative than the label. There is no
  version of "configurable food safety" that is a good idea in a €12 notebook app.

**Never** compute the clear date with civil-day arithmetic (`LocalDate.plusDays(N)` on the treatment
date). Measured above: it under-counts by an hour across a spring-forward, and the treatment date
alone already discards up to 24 h of the period.

### Milk, hours, and milkings — flag it, do not guess

VICH: milk periods are also expressed in **milkings** (12 h intervals). Sheep dairying exists in the
target market (Lacaune, East Friesian crosses; artisan cheese). The spec's model has one
`withdrawal_days_user_entered` field, which cannot represent *"6 milkings"* or two different numbers
for meat and milk on the same bottle.

Minimum viable fix, already in the type above: `WithdrawalTarget { meat, milk }`, with a treatment
holding a **list** of withdrawal entries. v1 can render only the meat one on the ewe card and still
have the schema right. Adding `WithdrawalMilkings(int)` as a fourth sealed subtype in v2 is then a
compile-error-guided change, not a migration.

## 3.5 "Hours since penned" across a DST transition

The pen board (§7.4) shows hours since penned and a "past your threshold" badge.

**Recommendation: absolute elapsed time.** `clock.now().difference(enteredAt)` on instants. The
question being asked is a welfare question — how long has this ewe and her lambs been in a 4×4
pen — and the answer is physical hours, not wall-clock hours.

Measured consequence: penned Sat 22:00, checked Sun 08:00 across the spring-forward reads **9 h**
though the wall clock advanced 10. Once a year, one hour, in the direction of turning out *later*
(more conservative). Acceptable, and correct.

The same reasoning applies to every reminder in §7.6 — colostrum window, navel dip, turn out, second
dose — all elapsed-time from an instant. AHDB's colostrum guidance is *"within the first four to six
hours of life"* ([Reducing Lamb Losses, p.16](https://projectblue.blob.core.windows.net/media/Default/About%20AHDB/Reducing%20Lamb%20Losses%202020.pdf)),
which is elapsed hours. (The app schedules the reminder; it does **not** display the guidance — that
is rule 2.)

Where the badge threshold is 24 or 48 h, use `Duration(hours: 24)`, not "the next day".

## 3.6 Editable timestamps for deferred entries

§7.2: *"the time is editable afterwards for deferred entries."* This is the flow that saves the app —
the 7am reconstruction is exactly the scenario in §2 — and it is where invalid times enter.

**Warn, never block.** Every check below produces a `Warning`, and the save button stays live.

```dart
List<Warning> checkLambingTime({
  required Instant effective,
  required Instant now,
  required LocalDate seasonStart,
}) {
  final w = <Warning>[];
  if (effective.isAfter(now)) {
    w.add(const Warning(WarningCode.lambingInFuture, 'This time is in the future.',
        fieldPath: 'time'));
  }
  if (LocalDate.of(effective).compareTo(seasonStart) < 0) {
    w.add(Warning(WarningCode.lambingBeforeSeasonStart,
        'This is before the season start (${seasonStart.iso}).', fieldPath: 'time'));
  }
  if (now.difference(effective) > const Duration(days: 3)) {
    w.add(const Warning(WarningCode.lambingLongBeforeCapture,
        'Recorded more than 3 days after the time entered.', fieldPath: 'time'));
  }
  return w;
}
```

**Can a lambing be in the future?** No, but *warn* rather than block. Reasons: the device clock can
be wrong (a phone that lost its battery in a cold shed comes back at an epoch default); a user in a
different zone on holiday; and blocking a save at 3am is worse than an odd record. Also, a lambing
*could* legitimately be "in the future" by a minute if the clock ticked between capture and save.
Use a small grace: warn only beyond ~2 minutes ahead.

**Before the season start?** Warn. It usually means the wrong season is selected, which is a real and
recoverable mistake — but a genuinely early lamb also happens, and the app must not out-argue the
shepherd.

**Nonexistent wall-clock times.** Measured above: `DateTime(2026, 3, 29, 1, 30)` in Europe/London
silently returns 02:30. This is Dart correcting the user, so we detect it:

```dart
/// Did the wall-clock time the user typed actually exist in the device's zone?
List<Warning> checkLocalWallTimeExists(int y, int mo, int d, int h, int mi) {
  final built = DateTime(y, mo, d, h, mi);
  if (built.hour == h && built.minute == mi && built.day == d) return const [];
  return [Warning(WarningCode.timeDoesNotExistLocally,
      'The clock skipped ${_hhmm(h, mi)} that night (clocks went forward). '
      'Saved as ${_hhmm(built.hour, built.minute)}.', fieldPath: 'time')];
}
```

Verified:

```
DST gap: 01:30 on 2026-03-29 does not exist in Europe/London
  "The clock skipped 01:30 that night (clocks went forward). Saved as 02:30."
DST gap check is silent on a normal night     ← including 2026-10-25 01:30 (ambiguous)
```

The **ambiguous** hour (fall-back, 01:30 occurring twice) is deliberately *not* warned about. Dart
picks one of the two instants, but the *displayed* time still matches what the user typed, so
nothing is silently corrected from the user's point of view. Warning about it would be noise at 3am
for a one-hour-per-year, zero-visible-effect condition. The 60 minutes of ambiguity are recorded in
the exported UTC column regardless.

**Also warn on:** `death_date` before the lambing date (`WarningCode.deathBeforeBirth`), and
birthweight outside ~1.0–10.0 kg (`implausibleBirthWeight`, band justified from AHDB above).

## 3.7 `package:timezone` vs `DateTime` — the contrarian call

The Flutter community reflex is *"`DateTime` is not timezone-aware, always use `package:timezone`."*
**For this app that is wrong for display and right only at the notification boundary.**

**Verified facts.** `timezone` **0.11.1**, published 28 days ago by the verified publisher
`labs.dart.dev`, all six platforms, 586 likes. It embeds the IANA database *in the compiled library*
(default variant 361 kB, `all` 443 kB, `10y` 85 kB) — [*"the recommended way to initialize a time
zone database for non-browser environments"*](https://pub.dev/packages/timezone), no network.
Changelog: 0.11.0 changed `Location.offset` from `int` to `Duration` (**breaking**); 0.11.1 made
`Etc/UTC` the default zone; 0.10.2 raised the SDK floor to `^3.10.0`; database 2025c as of 0.10.2.
It depends on `http ^1.6.0` (used only by `browser.dart`) and `path`.

**The argument against using it for storage/display in this app:**

1. **A single device, a single user, one zone.** There is no cross-zone display problem to solve.
   Data is written and read by the same person standing in the same shed.
2. **The bundled tz database is frozen at build time; this app never phones home.** A shepherd who
   buys it in 2026 and is still using it in 2031 has a five-year-stale tz snapshot. `DateTime`'s
   `toLocal()` uses the **OS** zone rules, which the phone updates. For an app whose entire premise
   is *"it cannot break… no server means no outage, no API deprecation"* (§4.3), deliberately
   embedding a decaying copy of government DST policy is the wrong trade.
3. **`DateTime` already gets the two things that matter right**, as measured in §3.3: `difference` is
   absolute, and `Duration` addition is absolute. Everything the domain needs is absolute-time
   arithmetic plus one civil-date type we wrote ourselves.

**Where `timezone` is unavoidable:** `flutter_local_notifications.zonedSchedule` takes a
`tz.TZDateTime`. Reminders are §7.6 and non-negotiable, so `timezone` will be a dependency
regardless. Confine it:

```dart
// The ONLY place tz appears in the app.
tz.TZDateTime scheduleTimeFor(Instant when) =>
    tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, when.epochMillis);
```

Set `tz.local` once at startup from the OS via **`flutter_timezone` 5.1.0** (`wolverinebeach.net`,
published 60 days ago, all platforms, no network) after `initializeTimeZones()`. Mitigate database
staleness by **rescheduling all pending reminders on every app launch** — cheap (tens of
notifications), and it means a stale rule can only be wrong for reminders scheduled between two
launches, which for a shepherd checking the shed nightly is hours.

Also note for the offline-permission story: `timezone` pulls `http`, but `http` is a **pure-Dart
package with no Android library module**, so it contributes no `<uses-permission>` to the merged
manifest. I did not independently verify the merged manifest — **the packaging agent should confirm
with `flutter build apk --analyze-size` / `aapt dump permissions` that the release APK declares no
`android.permission.INTERNET`.**

## 3.8 Injecting a clock

**Ban `DateTime.now()` in `lib/`.** Every timestamp, countdown, "hours since", and reminder in the
app derives from a clock, so exactly one seam is needed.

**Use `package:clock` 1.1.2** (`tools.dart.dev`, 254 likes, all platforms). API per
[the README](https://github.com/dart-lang/clock): a top-level `clock` getter, `clock.now()`,
`clock.stopwatch()`, `Clock.fixed()`, and `withClock()` to override. It composes with
**`fake_async` 1.3.3** (`dart.dev`), which *automatically* overrides `clock` inside `FakeAsync().run`
— so `async.elapse(Duration(days: 8))` advances a withdrawal countdown with no sleeping and no
custom test harness.

```dart
// production
final t = RecordedTime.capture(Instant.fromDateTime(clock.now()));

// test
withClock(Clock.fixed(DateTime(2026, 3, 4, 3, 20)), () {
  final t = RecordedTime.capture(Instant.fromDateTime(clock.now()));
  expect(t.effective.local, DateTime(2026, 3, 4, 3, 20));
});
```

Enforce with a custom analyzer entry plus a source-scan test (same machinery as the withdrawal
guard): `RegExp(r'DateTime\.now\(\)')` over `lib/**.dart`, allowlisting only the composition root.

**Why not pass `Instant now` as a parameter everywhere?** Do both. Pure domain functions
(`computeWithdrawalStatus`, `checkLambingTime`) take `now` as an explicit parameter — that is what
makes them pure and trivially testable, and every such function above does. `clock.now()` is called
only at the *edge*, in the repository/controller that constructs the parameter. The `clock` package
is the safety net for the edges, not a substitute for parameterising the core.

---

# Part 4 — The statistics (§7.8)

> *"a wrong denominator makes the headline number a lie."*

## 4.1 What the industry actually means — sourced

### AHDB (UK levy board), *Reducing Lamb Losses for Better Returns*, p.5 — verbatim

> **A** Empty ewes at scanning – number of empty ewes at scanning / the total number of ewes/ewe
> lambs put to the tup × 100
> **B** Lambs scanned … Scanning percentage = (number of lambs scanned / number of ewes put to the
> tup) × 100
> **C** Lambing percentage (**lambs born alive**) − when compared with lambs scanned, this indicates
> how many lambs have been lost during pregnancy through absorption or abortion…
> **D** Lambs turned out …
> **E** Rearing percentage = (number of lambs reared / number of ewes put to the tup) × 100

Two things to take from this:

1. **AHDB's denominator is always "ewes put to the tup."** Every one of the five measures.
2. **AHDB's "lambing percentage" means lambs born *alive*.** Not all lambs born.

Their industry targets (same page): empty at scanning <2%; scanning→birth losses <5%; birth→turnout
<5%; turnout→weaning <3%; scanning→rearing <13%.

### Penn State Extension — verbatim formulas

> Pregnancy Rate: `# of ewes pregnant ÷ number of ewes exposed to a ram × 100`
> Lambs Born Per Ewe Lambing (prolificacy): `# lambs born ÷ # ewes lambing × 100`
> Lambs Born Per Ewe Exposed (lambing percentage): `# lambs born ÷ # ewes exposed × 100` —
> **"the more accurate method for examining lambing percentage"**
> Lamb Survival: `number of lambs alive at one month ÷ number of lambs born × 100` — target 95%

— [*Does Your Flock Meet Your Performance Expectations?*](https://extension.psu.edu/does-your-flock-meet-your-performance-expectations)

### Sheep Ireland — the other convention

> *"Number of Lambs born should include both alive and dead lambs"*
> — [How to Record a Lambing Event](https://www.sheep.ie/how-to-record-a-lambing-event/)

So AHDB says *born alive* and Sheep Ireland says *born including dead*, for the same phrase, in
neighbouring countries in the app's primary market. **This is not an implementation detail the app
can pick a side on quietly.** It is why §7.8 says "with the definition configurable" — and the spec
is right.

### Teagasc / the Irish convention

Weaning rate is expressed as **lambs reared per ewe put to the ram** — the same denominator as AHDB.

## 4.2 The demonstration: one season, four legitimate answers

Toy season: 5 ewes to the ram; 3 lambed (412 twins, 128 single, 205 triplets of which 1 stillborn
and 1 died at 2 days); 1 recorded barren; 1 with no recorded outcome. Real program output:

```
 120%  6/5  lambs born (alive and dead) per ewe put to the ram
 100%  5/5  lambs born alive per ewe put to the ram
  80%  4/5  lambs reared per ewe put to the ram
 200%  6/3  lambs born (alive and dead) per ewe lambed
```

**120, 100, 80, 200 — from identical data.** A shepherd who tells a neighbour "we did 200%" and a
shepherd who says "we did 80%" may have had exactly the same season.

**Therefore: the number and its definition are one value, and the type enforces it.**

```dart
enum LambCount {
  born,       // all lambs delivered, alive or dead  (Sheep Ireland convention)
  bornAlive,  // excludes stillborn                  (AHDB convention)
  reared,     // alive at the end of the season      (AHDB rearing %)
}

enum FlockDenominator {
  ewesPutToRam,  // AHDB + Penn State "more accurate" method
  ewesLambed,    // prolificacy / litter size
}

typedef LambingPercentageDefinition = ({LambCount count, FlockDenominator per});

/// A number can never leave the domain layer without the definition that
/// produced it and the counts it was built from.
final class StatResult {
  final double? value;            // null == not computable, NEVER 0
  final String definition;        // human-readable, exported verbatim
  final int numerator;
  final int denominator;
  final String? notComputableReason;
  final List<String> caveats;
  const StatResult({...});
}
```

UI and export contract:

- The definition string is rendered **under every headline number**, always, not behind an info icon.
- `numerator/denominator` is rendered too ("6 / 5"). It is the cheapest possible way for a shepherd
  to sanity-check a number that looks wrong, and it costs no screen real estate at 18 pt.
- The **CSV/PDF export carries the definition string verbatim** alongside the value. A percentage in
  a spreadsheet with no definition is the exact failure this section exists to prevent.
- **Default: `(count: bornAlive, per: ewesPutToRam)`** — AHDB's convention, and Penn State's "more
  accurate" denominator. The setting exists (§7.10 `percentage_definition`) but the default must be
  the conservative, industry-standard one.

## 4.3 Every statistic, with its edge cases

All are **pure top-level functions** over plain record types. No DB types, no `BuildContext`, no
clock — so the whole of §7.8 is testable in milliseconds with no fixtures.

### Lambing percentage

Numerator per `LambCount`; denominator per `FlockDenominator`.

| Edge case | Behaviour | Why |
|---|---|---|
| `Season.ewes_to_ram` not entered | `value: null`, `notComputableReason: "Number of ewes put to the ram has not been entered for this season."` | **Never fall back to `ewesLambed`.** That would silently change the definition and inflate the number by 30–60%. Never return 0. |
| More ewes lambed than were recorded as put to the ram | Compute anyway (>100% is normal for this metric), and attach a caveat: *"3 ewes have lambed but only 2 were recorded as put to the ram."* | Rule 4: flag, do not fix. Verified output: `300% + caveat`. |
| Denominator 0 | `value: null` | No division by zero, no `NaN` leaking into a PDF. |

### Average litter size

**Always lambs born ÷ ewes lambed, always by birth dam.** Not configurable — "litter size" has one
meaning. Teagasc: *flock litter size is lambs born per ewe lambing.*

### Barren rate

> **Only ewes the user has explicitly marked barren are counted.**

```dart
enum EweSeasonOutcome { lambed, recordedBarren, diedOrSoldBeforeLambing, notRecorded }
```

Rejected alternative: `(ewesToRam − ewesLambed) / ewesToRam`. That infers barrenness from *absence
of data*, which sweeps in ewes that died, were sold, aborted, or were simply never entered. It is a
silent inference (rule 4) about a commercially sensitive number (§4.5), and at 3am on night eleven
the absence of data is overwhelmingly likely to mean "not recorded yet".

Instead, report the shortfall separately and name it honestly. Verified caveat:

```
[1 ewes have no recorded outcome. They are not counted as barren.]
```

### Assisted rate

> **Denominator = lambings *with an ease score*. Both sides exclude unscored lambings. Coverage is
> always reported.**

The authority is explicit:

> *"Note: a blank score indicates the lambing ease was not scored."*
> — [Sheep Genetics, *Understanding Lambing Ease ASBVs*](https://www.sheepgenetics.org.au/globalassets/sheep-genetics/resources/lambing-ease-scoring-guideline.pdf)

Treating a blank as "1 — no assistance" would deflate the rate and is precisely the silent inference
rule 4 forbids. Verified:

```
50.0%  lambings scored 2 or higher, per lambing with an ease score
       | [1 of 3 lambings have no ease score and are excluded from both sides.]
```

With zero scores: `value: null`, not `0%`.

*Note on the scale:* SRUC and Sheep Genetics both record ease **per lamb**, not per lambing. The spec
puts it on the `Lambing`. For a notebook that is correct — per-lamb ease is a pedigree-recording
concern, and §13 explicitly excludes EBVs. Document the divergence so a future CSV consumer is not
misled; label the column `lambing_ease_1_5` and the definition string "per lambing".

### Losses by cause and age

```dart
enum AgeBucket { stillborn, sameDay, day1to2, day3to7, day8to30, over30, unknownAge }
```

| Edge case | Behaviour |
|---|---|
| Stillborn | Its **own bucket**, never "died at age 0". A stillborn lamb has no age at death. |
| Died, no `death_date` | `unknownAge` bucket, counted in the total. |
| Died, no cause | Counted in the total; tallied under `unattributed`, **not** under "unknown". "Unknown" is a cause the user can pick; "unattributed" is our word for a blank field. |
| `death_date` before birth date | `unknownAge`, plus `WarningCode.deathBeforeBirth` on the record. |
| Lamb that died before tagging | **Counted, fully.** Lamb identity is the row id, never the tag. `tag` is nullable at every layer. Anything else loses exactly the losses that matter most. |

Age is computed from **civil dates**: `LocalDate.of(lambingInstant).daysUntil(deathDate)`. Because
`death_date` has day resolution, the first bucket must be labelled *"born and died the same day"*,
not *"under 24 hours"* — the data does not support the second claim. Verified:

```
total=2 byCause={stillborn: 1, hypothermia: 1}
byAge={AgeBucket.stillborn: 1, AgeBucket.day1to2: 1}     ← born 22nd, died 24th
```

### Lambing spread

> §7.8: *"a simple bar chart of births per day, which tells you next year whether your tupping was
> tight."*

```dart
({List<({LocalDate date, int dayIndex, int births, int ewes})> bars,
  int? ewesInFirstCycleDays,
  int cycleDays}) lambingSpread(SeasonFacts s, {int cycleDays = 17})
```

Four decisions:

1. **Group by the denormalised local civil date**, not by UTC and not by a SQL date function. A
   00:05 lambing belongs to that day, and a 23:55 one to the day before.
2. **Dense, zero-filled.** A gap day must render as a zero bar, not be skipped — the *gaps* are the
   information ("your tupping was tight" is a statement about gaps).
3. **Anchored on the first lambing** with a `dayIndex`, so the §7.8 comparison against previous
   seasons overlays two curves that both start at day 0.
4. **Add "ewes lambed in the first 17 days."** The ewe oestrous cycle is ~17 days, so the share of
   ewes lambing within one cycle length is the direct, single-number answer to "was my tupping
   tight?". This is *arithmetic on user data*, not advice — present it as a fact
   (`"32 of 48 ewes lambed in the first 17 days"`), never as a judgement.

Verified: `bars=19, ewes in first 17 d = 2/3`, with `bars[2].births == 0` (zero-filled).

Give `cycleDays` a settings value (default 17) rather than hard-coding it.

### Charting note

The bar chart must be legible in a head torch: 18 pt minimum labels, no hover tooltips (there is no
hover), no thin gridlines, and a tap target per bar of at least 60 pt in the tap dimension. If bars
get thinner than that with a 60-day spread, make the *chart* horizontally scrollable inside the card
rather than shrinking the bars.

---

# Part 5 — Fostering data integrity

> §7.3: *"Each lamb is its own record, linked to its birth dam permanently… keeping birth dam and
> rearing dam as separate fields."*

This split is not an app convenience — it is the established recording model. Sheep genetic
evaluation uses **birth type** (how many were born together) and **rearing type** (how many the ewe
actually raised) as distinct traits, notated together as `TBR` (e.g. `TBR=22` = twin born, twin
reared), precisely because *"many ewes that produced triplets did not suckle all their lambs, which
was due either to lamb death losses or a management decision to reduce the size of the litter by
artificial rearing or fostering of one or more lambs to another ewe"*
([Genet Sel Evol 2015, PMC4489108](https://pmc.ncbi.nlm.nih.gov/articles/PMC4489108/)).

## The type

```dart
final class LambDams {
  final String birthDamId;
  final String? rearingDamId; // null = artificially reared (bottle / pet lamb)

  const LambDams._(this.birthDamId, this.rearingDamId);

  /// Set once, at birth. Rearing defaults to the birth dam because that is a
  /// FACT at that moment, not a guess.
  factory LambDams.atBirth(String birthDamId) => LambDams._(birthDamId, birthDamId);

  /// Two taps on the Foster screen. Note the return type: a NEW value.
  /// birthDamId is copied, never taken as a parameter.
  LambDams fosteredOnto(String newRearingDamId) => LambDams._(birthDamId, newRearingDamId);

  LambDams toBottle()        => LambDams._(birthDamId, null);
  LambDams backToBirthDam()  => LambDams._(birthDamId, birthDamId);

  bool get isFostered           => rearingDamId != null && rearingDamId != birthDamId;
  bool get isArtificiallyReared => rearingDamId == null;
}
```

**The mechanism is the missing parameter.** There is no `copyWith({String? birthDamId})`, no setter,
and no public constructor that takes both. `fosteredOnto` *physically cannot* change the birth dam,
because it has no way to name a different one. This is stronger than a test, because it holds for
code that has not been written yet.

Plumbing:

| Layer | Mechanism |
|---|---|
| Schema | `birth_dam_id TEXT NOT NULL REFERENCES ewe(id)`, `rearing_dam_id TEXT NULL REFERENCES ewe(id)`. Index **both** (SQLite creates no FK index for you — §8). |
| DAO | The foster method is `Future<void> setRearingDam(String lambId, String? eweId)`. There is no method that writes `birth_dam_id` outside lamb creation. |
| Test | The invariant below, run over every season. |

## The invariants

```dart
/// Must hold for every season, always.
bool fosteringPreservesLitterCounts(SeasonFacts s) {
  final byBirthDam = <String, int>{};
  for (final lg in s.lambings) {
    for (final l in lg.lambs) {
      byBirthDam[l.birthDamId] = (byBirthDam[l.birthDamId] ?? 0) + 1;
    }
  }
  return byBirthDam.values.fold(0, (a, b) => a + b) == lambsBornInSeason(s, LambCount.born);
}
```

Stated as rules:

1. **Every "born" count aggregates on `birthDamId`. Every "reared" count aggregates on
   `rearingDamId`. The two are never mixed in one query.** This is the single rule that makes
   double-counting impossible: a lamb has exactly one birth dam, so `Σ litterSize == total lambs`
   by construction.
2. **A fostered lamb is not counted in the receiving ewe's litter size**, ever. Her *reared* count
   goes up; her *born* count does not.
3. **`rearingDamId == null` means artificially reared** and belongs to *no* ewe's reared count. This
   is a third state, not a missing value — the pet-lamb flow in §7.3 depends on it.
4. **Death does not clear either dam.** A dead lamb keeps its birth dam (so the ewe's litter size
   stays right) and keeps its rearing dam (so the loss is attributed to whoever was rearing it).

Verified:

```
fostering cannot change the birth dam
born by dam: {412: 2, 128: 1, 205: 3} ; reared by dam: {412: 1, 128: 2, 205: 1}
a chain of fosters still points at the original birth dam   ← 412 → 128 → 205 → 77 → 90
```

Note `128` rears 2 (her own single + the foster) while having *born* 1, and the totals still
reconcile.

## Warnings, not blocks

`checkFoster` returns a `Warning` for fostering onto the ewe that is already rearing the lamb, and
nothing else. Deliberately **not** blocked:

- Fostering onto a ewe who has not lambed (a genuine practice with a ewe who lost her own lambs, and
  the app must not require her lambing to be recorded first — §7.1: *"never block an entry to make
  the user go and set something up first"*).
- Fostering more lambs onto a ewe than she has teats. Warn if you like; never block.

## The audit question

Should a foster write a history row? **Yes, and it is cheap.** A `foster_event(id, lamb_id,
from_ewe_id, to_ewe_id, recorded_time…)` table means the ewe card can say *"took a foster from 412
on 4 Mar"* — which is exactly the §7.7 retention feature. Two taps to perform, one row to store.

---

# Part 6 — The editable terminology map

> §7.10: *"Terminology: ewe / gimmer / shearling / theave / hogget — editable labels, because these
> vary by county, let alone by country."*

## The finding that shapes the design

These words are **not synonyms and not a clean taxonomy**. From the National Sheep Association's own
glossary ([Terms to know](https://nationalsheep.org.uk/terms-to-know/)):

- **Gimmer** — *"a female sheep in her second year but before she has her first lamb"* (defined by
  age + parity)
- **Shearling** — *"a young sheep between the January after its birth and its first two teeth
  (usually at 18 months)"* (defined by **dentition**)
- **Hogget** — *"a sheep between 1-2 years of age. Can also refer to the meat"* (defined by age, and
  overloaded with a meat term)
- **Teg** — *"a sheep that is two years old, or the fleece from a two-year-old sheep"* (NSA's
  definition; other regions use it for a sheep in its *second* year)

Three different measuring sticks — parity, dentition, age — for overlapping classes, with regional
disagreement inside one national body's glossary. **There is no canonical taxonomy to normalise to.**

That kills the naive design ("one enum, translate it") and it kills the other naive design ("free
text, no enum"). It leaves exactly one shape.

## The design

> **A closed enum of domain classes with stable machine keys (in the DB, CSV and JSON), plus a
> user-editable label overlay (singular + plural) that touches nothing but rendering.**

```dart
/// The DOMAIN concept. These keys are written to the database, to the JSON
/// backup and to CSV headers, and they never change — not when the user
/// renames a label, not when the app is translated.
enum AnimalClass {
  ewe,           // adult female that has lambed
  maidenFemale,  // gimmer / theave / shearling ewe / hogg — regional
  eweLamb,       // female under 1 year
  ram,           // tup
  ramLamb,
  wether,
  lamb,          // sex unknown / not yet sexed
}

final class TermLabel { final String singular, plural; const TermLabel(this.singular, this.plural); }

/// Resolution order: user override -> localised default. Never empty.
final class Terminology {
  final Map<AnimalClass, TermLabel> _defaults;   // from gen_l10n
  final Map<AnimalClass, TermLabel> _overrides;  // from the settings table

  TermLabel labelFor(AnimalClass c) {
    final o = _overrides[c];
    if (o != null && o.singular.trim().isNotEmpty && o.plural.trim().isNotEmpty) return o;
    return _defaults[c]!;  // a missing default is a programming error, not a runtime state
  }
}
```

Note `maidenFemale` as the key. It is deliberately a *neutral, unlovely* name that belongs to no
county, so that the default English label (`gimmer`) and a Yorkshire user's override (`theave`) and
a translator's `agnelle` are all *equal citizens* over one stable key. Naming the key `gimmer` would
privilege one dialect in the data format forever.

## Making it survive gen_l10n and plurals

The generated `AppLocalizations` is **compile-time only** — per
[the Flutter i18n guide](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization),
messages *cannot* be loaded or overridden at runtime; the class is generated from ARB and has no
mutation API. So terminology cannot be a locale, and cannot be an ARB override.

**The rule that makes them coexist:**

> **Never bake a domain noun into an ICU message. Pass it in as a `String` placeholder, and let ICU
> choose only the plural *category*.**

```jsonc
// lib/l10n/app_en.arb — the SENTENCE lives here; the NOUN does not.
"nAnimals": "{count, plural, =0{No {plural}} =1{1 {singular}} other{{count} {plural}}}",
"@nAnimals": {
  "placeholders": {
    "count":    { "type": "num" },
    "singular": { "type": "String", "example": "ewe"  },
    "plural":   { "type": "String", "example": "ewes" }
  }
}

// The DEFAULT labels also live in the ARB, so translators get a baseline:
"termEweSingular": "ewe",
"termEwePlural":   "ewes",
"termMaidenFemaleSingular": "gimmer",
"termMaidenFemalePlural":   "gimmers",
// ... one pair per AnimalClass
```

```dart
final l = terminology.labelFor(AnimalClass.ewe);
Text(AppLocalizations.of(context).nAnimals(count, l.singular, l.plural));
```

Placeholders inside plural variants are supported by gen_l10n (verified in the Flutter i18n docs).
The ICU engine picks `=0 / =1 / other` correctly for the locale; the noun is substituted from the
user's map. Renaming `ewe` → `yow` therefore cannot break pluralisation, because pluralisation never
knew the word.

Verified:

```
renaming changes only the label, never the key    ← AnimalClass.maidenFemale.name == 'maidenFemale'
pluralisation survives an arbitrary rename        ← "No yowes" / "1 yow" / "3 yowes"
a blank override falls back rather than showing an empty button
```

**The honest limitation:** this works cleanly for languages with two plural categories. Locales with
`few`/`many` (Polish, Russian, Irish) would need three or four noun forms, and this design supplies
two. For v1 (English/Irish-English) it is correct; document it, and note that adding
`TermLabel.few`/`.many` later is an additive change to the record and the ARB. Do **not** try to
derive a plural from the singular by appending "s" — `theave`→`theaves` works, `hogg`→`hoggs` works,
but the user must be able to type both anyway, and guessing is rule 4 again.

## Export headers — the rule that saves the backup

| Artifact | Uses | Why |
|---|---|---|
| **CSV header row** | **stable English keys** (`ewe_tag`, `birth_type`, `withdrawal_days_as_entered`, `animal_class`) | A header that changes when the user renames a label breaks every spreadsheet, script and re-import. Machine columns are a contract. |
| **CSV `animal_class` values** | **enum keys** (`maidenFemale`) | Same reason, and it makes the JSON backup and the CSV agree. |
| **PDF flock book** | the **user's** labels | It is for reading, by the person who chose the words. |
| **JSON backup** | enum keys, **plus a top-level `"terminology"` block** with the override map | A restore reproduces the shepherd's vocabulary exactly. Without the block, a restore silently reverts their labels — rule 4 at the backup layer. |

## Validation: reject, do not sanitise

```dart
TermOverrideResult validateOverride(String singular, String plural) {
  final s = singular.trim(), p = plural.trim();
  if (s.isEmpty || p.isEmpty) return TermOverrideRejected('Both the singular and the plural are needed.');
  if (s.length > 24 || p.length > 24) {
    return TermOverrideRejected('24 characters maximum, so it still fits the buttons at arm’s length.');
  }
  if (RegExp(r'[\n\r\t,"]').hasMatch(s) || RegExp(r'[\n\r\t,"]').hasMatch(p)) {
    return TermOverrideRejected('No commas, quotes or line breaks.');
  }
  return TermOverrideAccepted(TermLabel(s, p));
}
```

Stripping the comma silently would be a silent correction. Rejecting with a reason is not. (Trimming
surrounding whitespace is the one exception I would accept — it is invisible, universally expected,
and cannot change meaning.) The 24-character cap is a **3am** constraint, not a database one: a
label that overflows a 60 pt button in a head torch is a defect.

Also: **renaming must never be a setup step.** Defaults ship, Settings is optional, and §5's "no
onboarding after first run" holds.

---

# Part 7 — Contradiction detection

> §12.4: *"If a birth type of 'twin' has three lambs attached, flag it; do not fix it."*

## Where the check lives

**In `lib/domain/validation.dart` — a pure function, imported by the UI, invisible to the DAO.**

```
domain/validation.dart      pure functions: (data) -> List<Warning>
        ▲                   no DB import, no clock import, no Flutter import
        │
presentation/…              calls them on every rebuild; renders the strip
        │
data/…                      DOES NOT import validation.dart at all
```

The DAO never imports the validation library. That is enforceable with a dependency lint and it is
the strongest form of "guaranteed not to mutate": the code that could write has no reference to the
code that judges.

## The catalogue

| Check | Trigger | Message |
|---|---|---|
| `birthTypeLambCountMismatch` | expected count ≠ attached count, and expected is not open-ended | "Birth type is twin but 3 lambs are recorded." |
| `lambingInFuture` | `effective > now + 2 min` | "This time is in the future." |
| `lambingBeforeSeasonStart` | `LocalDate.of(effective) < seasonStart` | "This is before the season start (2026-03-01)." |
| `lambingLongBeforeCapture` | `capturedAt − effective > 3 d` | "Recorded more than 3 days after the time entered." |
| `timeDoesNotExistLocally` | round-tripping the typed wall time changes it | "The clock skipped 01:30 that night (clocks went forward). Saved as 02:30." |
| `implausibleBirthWeight` | outside ~1.0–10.0 kg (from AHDB's ranges) | "4 g is outside the usual range for a lamb." *(observation, not judgement)* |
| `deathBeforeBirth` | `death_date < lambing local date` | "The death date is before the lambing." |
| `duplicateTagInFlock` | tag matches another live animal | "412 is already in use." |
| `fosterToSelf` | target == current rearing dam | "That lamb is already on this ewe." |

## How it is surfaced

- **Recomputed on read, never stored.** The `Reviewed<T>` wrapper exists only in memory.
- **A 60 pt amber strip** under the offending field, tappable to scroll. Not a dialog — a dialog at
  3am is a 15-second penalty and a gloved-thumb hazard.
- **On the ewe card and the flock list**, a small persistent badge for records with warnings, so a
  contradiction found at 3am is still findable at 9am.
- **In the CSV export**, a `has_warnings` boolean column and a `warnings` column of joined codes —
  *codes*, not localised messages. The export tells the truth about the data's condition without
  claiming to have fixed anything.
- **Never blocks a save. Never auto-dismisses. Never appears twice for one field.**

## Why the birth-type check specifically cannot mutate

Three independent reasons, any one of which suffices:

1. `checkBirthTypeAgainstLambs(BirthType type, int lambsAttached)` receives `type` **by value** —
   `BirthType` is an enum, immutable, and the function has no reference to the record it came from.
2. It returns `List<Warning>`. `Warning` has no field that is a birth type and no method that
   accepts one.
3. The library it lives in has no import path to any writer.

Verified: `expect(type, BirthType.twin)` after the call — unchanged, by construction.

---

# Part 8 — Search and recall semantics

> §8: *"Search — '412' returns her whole life in under a second."*
> §7.7: *"Full-text offline search across every note, tag, and treatment."*

## What "her whole life in under a second" actually is

A "whole life" for a ewe in a 400-ewe flock, over five seasons, is on the order of:

| Rows | Estimate |
|---|---|
| Lambings | 5 |
| Lambs (born to her) | ~10 |
| Lambs (reared by her, fostered in) | ~2 |
| Treatments | ~15 |
| Pen stays | ~5 |
| Notes | ~20 |
| Reminders | ~20 |
| **Total** | **~80 rows** |

Eighty rows across seven indexed tables is **sub-millisecond** in SQLite. The one-second budget is
not spent on the query; it is spent on (a) finding the ewe from partial keypad input, and (b) the
first frame. The engineering conclusion is therefore counter-intuitive:

> **The recall problem is a UI-latency problem with a trivial query behind it. Design for the frame,
> not the query plan.**

Concretely:

1. **Index every foreign key by hand.** SQLite *"does not automatically create an index on child key
   columns"* and *"in most real systems, an index should be created on the child key columns of each
   foreign key constraint"*
   ([sqlite.org/foreignkeys](https://www.sqlite.org/foreignkeys.html)). Missing FK indexes are the
   only way to make an 80-row fetch slow — a `DELETE` on a ewe would linear-scan every child table.
   Also `PRAGMA foreign_keys = ON` on **every** connection: FK constraints are *"disabled by default
   (for backwards compatibility)"*.
2. **One composite index per timeline query**: `(ewe_id, occurred_at_ms DESC)` on lambings,
   treatments, notes, pen stays. Then the ewe card is seven index-range scans with no sorts.
3. **Fetch the whole card in one transaction**, seven statements, synchronously against the open
   database. Do not `await` seven separate futures on seven separate frames.
4. **Precompute the §7.7 one-line summary** (*"3 seasons · avg 2.0 · assisted twice · prolapsed
   2025"*) into a `ewe_summary` row updated on write. It is the first thing on the card and must not
   wait for an aggregate. Writes are already immediate and rare relative to reads.

## Tag matching — the contrarian call

> §7.1: *"Partial tag matching — typing `12` surfaces 412, 128, 12."*

That is **infix** matching on a 2-character query. The reflex answer (FTS5) cannot do it:

- FTS5's default tokenizer supports **prefix** matching only; infix requires the trigram tokenizer.
- And per [sqlite.org/fts5](https://www.sqlite.org/fts5.html): *"Substrings consisting of fewer than
  3 unicode characters do not match any rows when used with a full-text query."*

So a trigram FTS5 index **cannot** make `"12"` find `412`. The spec's headline example is
unimplementable with the popular tool.

**Recommendation: keep the flock in memory and filter in Dart.**

```dart
// 400 ewes × ~120 bytes ≈ 48 KB. Loaded once at startup, kept in a provider,
// invalidated on write.
List<EweListItem> matchTag(List<EweListItem> flock, String query) {
  if (query.isEmpty) return flock;
  final exact  = <EweListItem>[];
  final prefix = <EweListItem>[];
  final infix  = <EweListItem>[];
  for (final e in flock) {
    final t = e.tag;
    if (t == query) { exact.add(e); }
    else if (t.startsWith(query)) { prefix.add(e); }
    else if (t.contains(query)) { infix.add(e); }
  }
  return [...exact, ...prefix, ...infix];  // ranked, not just filtered
}
```

Why this is right *here* and would be wrong in a normal app:

- The flock is bounded by the product definition: 20–400 ewes (§3). 400 string scans is a few
  microseconds — faster than any query round trip, and **synchronous**, so the list updates *in the
  same frame as the keystroke*. That is the 3am requirement.
- No `await`, no `StreamBuilder`, no loading state, no jank between digits.
- Exact-before-prefix-before-infix ranking is trivial in Dart and awkward in SQL.
- Recents (§7.1) and "in the pens" are the same in-memory list, sorted differently.

Free tier caps at ~15 ewes; the paid ceiling is a few hundred. If someone ever arrives with 5,000
animals, add a `LIKE '%q%'` fallback above a threshold. Do not build for that now.

## Full-text search over notes

This one **is** FTS5's job: unbounded free text, word-level matching, ranking.

```sql
CREATE VIRTUAL TABLE note_fts USING fts5(
  text,
  content='note',        -- external content: no duplicated text
  content_rowid='id',
  tokenize='unicode61'
);
-- plus AFTER INSERT / UPDATE / DELETE triggers on `note`, per sqlite.org
```

External-content tables avoid storing every note twice — important for a device-only app with no
cloud fallback.

**Verify FTS5 at runtime rather than trusting the docs.** I could **not** confirm from a primary
source that `package:sqlite3` 3.5.0's bundled build defines `SQLITE_ENABLE_FTS5` — the flags are
passed into the build hook from configuration I could not fetch. So:

```dart
// Startup capability probe + a CI test. Never assume a compile flag.
bool hasFts5(Database db) =>
    db.select("SELECT sqlite_compileoption_used('ENABLE_FTS5') AS x").first['x'] == 1;
```

If absent, degrade to `WHERE text LIKE '%q%'` over the notes table and show the same UI. A shepherd
with 2,000 notes will not notice the difference; a missing feature at 3am they would.

**Important packaging finding for whoever owns persistence:** `sqlite3_flutter_libs` is
**discontinued** — its pub.dev page reads `0.6.0+eol` with *"Not used anymore, update to version 3.x
of package:sqlite3 instead"*, and from 0.6.0 *"this package no longer does anything."*
`package:sqlite3` **3.5.0** now bundles the native library itself: *"Because this library uses hooks,
it bundles SQLite with your application and doesn't require any external dependencies or build
configuration."* Any tutorial or stale training data that tells you to add `sqlite3_flutter_libs` is
out of date.

---

# Rejected alternatives

| Rejected | In favour of | Why it lost |
|---|---|---|
| `int? withdrawalDays` | `sealed WithdrawalPeriod` | Conflates "label says 0" with "not recorded" with "not applicable". Lossy, not merely loose. One `?? 0` away from a food-safety incident. |
| `LocalDate? clearDate` | `sealed WithdrawalStatus` | Same disease on the output side; a null date renders as an empty string in a PDF someone hands to a vet. |
| Storing `clear_date` | Recomputing it | A stored derived value goes stale when `date` or `days` is edited, and there is no mechanism that guarantees the recompute fires. Zero cost to recompute. |
| Civil-day arithmetic for withdrawal (`treatmentDate.plusDays(N)`) | Absolute hours, then ceil to local midnight | **Measured: 167 h instead of 168 h across a spring-forward.** Also discards up to 24 h by dropping the time of administration. |
| A user setting for "count whole days from the day of treatment" | One conservative rule, plus showing the arithmetic | A food-safety setting buried in a settings screen is a defect with a UI. |
| Storing mass in 0.1 kg | Integer grams | **Measured: corrupts 132/241 pound entries.** A rule-4 violation with no code to blame. |
| Storing temperature in 0.1 °C | Integer milli-°C | **Measured: rewrites 89/201 Fahrenheit entries.** 0.01 °C is the minimum that works; milli gives headroom. |
| `double` for weights | `int` grams | Float in SQLite means `SUM` and `==` are approximate, and JSON round-trips can shift the last digit. There is no upside. |
| `package:decimal` / `package:fixed` | Integer canonical units | `fixed` 6.1.1 has **11 likes**; both allocate `BigInt`s to solve a problem an `int` already solves exactly. Extra dependency, extra surface, zero gain, in an app that must build unchanged in 2031. |
| Extension types for display units (`Pounds`, `Fahrenheit`) | Only canonical extension types | They **erase to the same runtime type**, so they give false confidence in any `is`/`switch`/serialisation path, and they invite storing a display value. |
| `package:timezone` for storage and display | `Instant` + `DateTime.toLocal()` | Its embedded IANA snapshot is frozen at build time and this app never updates. After a few years the OS zone is *more* correct. Contradicts the community default; correct here. |
| `DateTime` for civil dates | `LocalDate` | A `DateTime` for "the season starts 1 March" carries a spurious 00:00:00 that shifts under `toUtc()`, and invites `Duration` arithmetic that DST perturbs. |
| Drift's `DateTime` columns (either mode) | `IntColumn`+`Instant` / `TextColumn`+`LocalDate` converters | Integer mode is seconds and *"drift always returns a non-UTC value… this information is lost"*; text mode mixes instant and civil semantics; and the choice is a **global build flag** whose toggle breaks existing schemas. |
| `freezed` for `WithdrawalPeriod`, `RecordedTime`, `LambDams` | Hand-written sealed/final classes | `freezed` 3.2.5 is excellent and Flutter Favorite, but it generates *public* constructors and a `copyWith` that accepts **every** field — which would hand back the `birthDamId` parameter that Part 5 removes on purpose. Use `freezed` freely for DTOs and UI state; not for the four types whose safety comes from a missing constructor. |
| `equatable` | `final class` with hand-written `==`, or records | Four types need value equality. A dependency for that is not worth it, and records cover most cases natively in Dart 3. |
| Inferring barren from `ewesToRam − ewesLambed` | Explicit `EweSeasonOutcome.recordedBarren` | Sweeps in ewes that died, were sold, aborted, or were never entered. Silent inference on a commercially sensitive number. |
| Treating a blank ease score as "1 — unassisted" | Excluding unscored from both sides, with coverage reported | Sheep Genetics: *"a blank score indicates the lambing ease was not scored."* |
| A single global `lambingPercentage()` returning `double` | `StatResult` with definition + counts + caveats | **Measured: 120/100/80/200% from the same season.** A bare double is a lie waiting to be quoted. |
| FTS5 (trigram) for tag search | In-memory Dart filter | sqlite.org: trigram queries under 3 characters match nothing — so `"12"` finding `412` is impossible. And 400 rows in Dart is faster and synchronous. |
| FTS5 for everything | FTS5 for notes only, behind a capability probe | Right tool for unbounded prose, wrong tool for a bounded list of short numeric tags. |
| `sqlite3_flutter_libs` | `package:sqlite3` 3.5.0 | **Discontinued**: `0.6.0+eol`, *"this package no longer does anything."* |
| One `withdrawal_days` column | `WithdrawalTarget` + a list of entries | One bottle, two numbers. Wrong on any dairy flock, and the fix later is a data migration. |
| Terminology as a locale / ARB override | Stable enum keys + a runtime label overlay | The generated `AppLocalizations` is compile-time and has no runtime override API; and there is no canonical taxonomy to translate *to* (NSA's own glossary conflicts). |
| Baking the noun into the ICU plural message | Noun as a `String` placeholder inside the plural | A rename would break pluralisation for every renamed term. |
| Deriving a plural by appending "s" | Two user-entered forms | Guessing is a silent correction, and the user is already typing one word. |
| User labels as CSV headers | Stable English keys | A rename would break every downstream spreadsheet and re-import. |
| Blocking saves on a contradiction | Warning strip, save always live | §5: assume the phone dies; a blocked save is a lost record. |
| Storing warnings in a column | Recomputing on read | A stored warning goes stale and starts to look like user data. |
| `DateTime.now()` at call sites | `clock.now()` at edges, `Instant now` parameters in the core | Untestable countdowns; and `fake_async` integrates with `clock` for free. |
| The `csv` package (8.0.0) | *Undecided* — see Open Questions | Works and is popular (755k weekly), but its **uploader is unverified**, and the app needs total control of quoting plus a disclaimer row. A ~40-line RFC 4180 writer is auditable forever and adds no supply-chain surface to a decade-lived offline app. |

---

# Pitfalls

| # | Pitfall | Severity | Mitigation |
|---|---|---|---|
| 1 | `withdrawalDays ?? 0` appears in a null-safety cleanup and nobody notices — it *reads* as tidy code. | **Blocker** | Sealed type with a private constructor makes it not compile; the source-scan guard catches the string form; `?? ` next to `withdrawal` is a banned pattern. |
| 2 | Clear date computed with civil-day arithmetic. Off by 1 h across a spring-forward, silently. | **Blocker** | Absolute `Duration(hours: days * 24)`, then ceil to local midnight. Ship the DST regression test (`expect(elapsedCivil.inHours, 167)`) so a "simplification" fails CI. |
| 3 | Canonical unit chosen too coarse (0.1 kg / 0.1 °C). Silently rewrites over half of imperial entries. Invisible in review. | **Blocker** | Grams and milli-°C, with the exhaustive round-trip tests in CI. These tests are the *specification*, not a nicety. |
| 4 | Someone stores the display value "because the user entered lb". Values drift on every open-and-save. | High | No `unit` column on any measurement. A schema test asserts it. Extension types make the canonical type the only thing that fits the setter. |
| 5 | `DateTime(y, m, d, h, min)` for a DST-gap time returns a *different* time with no exception. | High | `checkLocalWallTimeExists` round-trip test on every editable timestamp. |
| 6 | Naive source-grep guards miss long strings, because Dart splits them across adjacent literals. **This bit me while writing the disclaimer guard.** | High | Extract string literals and join before matching — never `file.contains(longPhrase)`. |
| 7 | A guard that never fires is indistinguishable from a broken guard. | High | Every guard has a positive self-test (planted offenders) *and* a negative self-test (real app copy that must pass). |
| 8 | Headline percentage exported with no definition, quoted by a shepherd to a neighbour, off by 2.5×. | High | `StatResult` carries the definition; the CSV/PDF writers take the definition string as a required argument. |
| 9 | Barren rate inferred from missing lambings; ewes not yet recorded show up as barren on night three. | High | Only `EweSeasonOutcome.recordedBarren` counts; unrecorded ewes are reported as a separate caveat. |
| 10 | Blank ease score counted as "unassisted", deflating assisted rate. | High | Exclude from both sides; report coverage. Sheep Genetics is explicit. |
| 11 | Reared counts aggregated on `birthDamId`, or born counts on `rearingDamId` — a fostered lamb double-counts. | High | One rule, one invariant test (`fosteringPreservesLitterCounts`), and two clearly named aggregation functions. Never one function with a flag. |
| 12 | `copyWith` regenerated with `birthDamId` as a parameter (e.g. after adopting `freezed`) and a foster silently rewrites the birth dam. | High | Hand-written `LambDams`; if `freezed` is ever adopted for it, add a test asserting `copyWith` has no birth-dam parameter. |
| 13 | A lamb that died before tagging is dropped because the tag is the key. The worst losses vanish from the loss report. | High | Row id is identity; `tag` is nullable everywhere including the FTS index and the CSV. Test with a tagless dead lamb fixture. |
| 14 | The lambing spread groups by UTC date; a 00:05 lambing lands on the previous day, once per night, for a whole season. | Medium | Denormalised `local_date` written at insert. Test with 23:55 and 00:05 events. |
| 15 | Trigram FTS5 chosen for tag search; `"12"` returns nothing and the spec's headline example fails. | Medium | In-memory filter. If FTS5 is used anyway, the <3-char rule must be in the test suite. |
| 16 | `PRAGMA foreign_keys` left off (the SQLite default), and orphan lambs accumulate after a ewe delete. | Medium | Set it on every connection open, including in tests and after any `ATTACH`. Assert it in a schema test. |
| 17 | FK columns unindexed; deleting a season linear-scans every child table and the "delete a season" setting hangs. | Medium | Index every FK. Verify with `EXPLAIN QUERY PLAN` in a test for the delete path. |
| 18 | `SQLITE_ENABLE_FTS5` absent from the bundled build; note search throws on first use, in a shed, offline. | Medium | Runtime capability probe + `LIKE` fallback. Never assume a compile flag you have not read. |
| 19 | `timezone`'s bundled IANA snapshot goes stale over the app's decade-long life; a reminder fires an hour off after a DST-rule change. | Medium | Confine `tz` to the notification boundary; reschedule all pending reminders on every app launch. |
| 20 | `timezone` 0.11.0 changed `Location.offset` from `int` to `Duration` — a silent breaking change if you upgrade mid-project. | Medium | Pin, and read the changelog on every bump. Verified today from the pub.dev changelog. |
| 21 | `double.parse('4,3')` throws on a comma-locale keyboard; or worse, a locale-aware parse turns `'4.3'` into `43`. | Medium | Own the keypad. For any free-text numeric field, reject ambiguity rather than guessing. |
| 22 | ICU plural message contains a hard-coded noun; a terminology rename produces "3 ewes" for a user who renamed to "yow". | Medium | Noun as a placeholder inside the plural, never inside the literal. |
| 23 | The terminology override leaks into CSV headers or `animal_class` values; a rename breaks re-import. | Medium | Enum keys in machine columns; a golden test on the header row. |
| 24 | The JSON backup omits the terminology block; a restore silently reverts the shepherd's vocabulary. | Medium | Include `"terminology"`; round-trip test. |
| 25 | Warnings persisted to a column; they go stale and start looking like user data on export. | Medium | No column exists. A schema test asserts no table has a `warnings` column on an entity. |
| 26 | Extension type declared with `implements Comparable<Self>` — fails with `extension_type_implements_not_supertype`. | Low | Plain `compareTo` method + explicit comparators. Verified failure mode. |
| 27 | `toInt()` used instead of `round()` in a conversion; every weight is systematically light. | Low | Use `round()`; add a boundary test at `x.5`. |
| 28 | `AgeBucket.sameDay` labelled "under 24 hours" when `death_date` only has day resolution. | Low | Label it "born and died the same day". |
| 29 | Elective caesarean recorded as ease 5, indistinguishable from an emergency. | Low | SRUC's scale has a 6th value for it. Either adopt 1–6 or document that 5 covers both. Decide before data exists. |
| 30 | A stillborn lamb counted in "died at age 0", double-counting against a "first 24 h losses" figure. | Low | Its own bucket. |

---

# How this serves the 3am test and the offline-only constraint

**Offline-only actively improved the answers, it did not merely constrain them.**

| Decision | Networked-app default | Why offline flips it |
|---|---|---|
| Timezone handling | `package:timezone` everywhere | The bundled IANA DB is frozen at build; the OS DB is not, and this app never updates. `DateTime.toLocal()` **ages better**. |
| Tag search | Query the DB with an index | The flock is bounded (20–400) and there is no server round trip to amortise, so in-memory is faster **and synchronous** — the list updates in the same frame as the keystroke. |
| Statistics | Compute server-side, cache the result | Everything is a pure function over ≤ a few thousand rows. No caching, no invalidation bugs, no staleness. `dart test` runs the entire §7.8 in milliseconds. |
| Dependencies | Take the popular package | The app must build and run unchanged in 2031 with no CI, no company, and no ability to hotfix a shed. Prefer `int` over `decimal`; prefer 40 lines of CSV over an unverified-uploader package; prefer `dart:core` over a wrapper. |
| Backup format | The server has it | The CSV/PDF/JSON export **is** the backup, so provenance and definition strings must be in the file — there is nothing else to consult later. |
| Validation | Server-side re-validation | All validation is client-side and advisory. Nothing can be rejected after the fact, so nothing may be silently repaired either. |

**3am specifically:**

- **Warnings never block a save.** Every write commits immediately (§5). A contradiction is a strip,
  not a gate.
- **Every "not computable" state has a name and a widget.** No blank cells, no `NaN`, no `—` that
  might mean zero. At 3am on night eleven, ambiguity is a defect.
- **The app owns the numeric keypad**, so decimal separators, hit targets and locale are all one
  problem solved once.
- **Terminology defaults ship.** Renaming is optional, never a setup step (§5: no onboarding after
  first run).
- **Pure functions have no I/O**, so the ewe card renders from an in-memory snapshot in one frame —
  no spinner between "412" and her history.
- **The 24-character terminology cap** is a legibility constraint from the head-torch requirement,
  enforced by the validator.
- **`compareTo` on `LocalDate` is a string compare**, so `ORDER BY local_date` is index-friendly and
  the pen board and spread chart never sort in Dart.

---

# Package verification (all read from pub.dev on 2026-07-27)

| Package | Version | Published | Publisher | Verdict | Note |
|---|---|---|---|---|---|
| `clock` | **1.1.2** | 21 months ago | `tools.dart.dev` ✅ | **adopt** | 254 likes, all platforms. The only clock seam. |
| `fake_async` | **1.3.3** | 18 months ago | `dart.dev` ✅ | **adopt (dev)** | Auto-overrides `clock` inside `FakeAsync().run`. |
| `timezone` | **0.11.1** | 28 days ago | `labs.dart.dev` ✅ | **adopt-with-care** | Embedded IANA DB, no network. 0.11.0 breaking (`Location.offset` → `Duration`). Confine to notification scheduling. Pulls `http ^1.6.0` (pure Dart, browser-only path). |
| `flutter_timezone` | **5.1.0** | 60 days ago | `wolverinebeach.net` ✅ | **adopt** | Device IANA zone name for `tz.setLocalLocation`. No network. |
| `intl` | **0.20.3** | 32 days ago | `dart.dev` ✅ | **adopt** | Display edge only. `DateFormat` needs `initializeDateFormatting()` per locale. |
| `drift` | **2.34.2** | 12 days ago | `simonbinder.eu` ✅ | **adopt** | Column `check()` constraints; type converters for `Instant`/`LocalDate`. Avoid `DateTime` columns (see §3.1). |
| `sqlite3` | **3.5.0** | 8 days ago | `simonbinder.eu` ✅ | **adopt** | 3.x bundles SQLite via hooks; no build config. **FTS5 compile flag unverified — probe at runtime.** |
| `sqlite3_flutter_libs` | **0.6.0+eol** | 5 months ago | `simonbinder.eu` | **avoid — DISCONTINUED** | *"Not used anymore, update to version 3.x of package:sqlite3 instead."* Stale tutorials still recommend it. |
| `freezed` | **3.2.5** (4.0.0-dev.3 pre) | 5 months ago | `dash-overflow.net` ✅ | **adopt-with-care** | Flutter Favorite, 4.5k likes. Fine for DTOs/UI state. **Not** for the four safety types (public ctor + total `copyWith`). |
| `csv` | **8.0.0** | 4 months ago | *unverified uploader* ⚠️ | **undecided** | 755k weekly downloads, good API (BOM/Excel codec). But unverified publisher + a 40-line RFC 4180 writer is auditable forever. |
| `fixed` | **6.1.1** | 9 months ago | `onepub.dev` ✅ | **avoid** | 11 likes. `BigInt`-backed decimals solve nothing that integer grams does not solve exactly. |

---

# Open questions

1. **Lamb-scale resolution.** I could not find a primary source for what a shepherd's scale actually
   reads to (searches returned antique Salter spring balances). Grams as canonical is right either
   way — the binding constraint is lb↔kg round-tripping, not scale resolution — but the *input
   step* (0.1 kg? 0.05 kg? 50 g?) and the plausibility band should be checked with a real shepherd.
   Ties into spec Open Question 1 (observe one full night).
2. **Where does temperature appear at all?** §7.10 has a °C/°F setting but §10's data model has **no
   temperature field**. Either the setting is vestigial (drop it — an unused setting is a 3am tax) or
   there is an intended lamb/ewe body-temperature field that is missing from the model. Recommend
   deciding before schema v1; the milli-°C type is ready either way.
3. **Is the target market ever a dairy flock?** If yes, `WithdrawalTarget.milk` and possibly
   `WithdrawalMilkings` must be in the v1 *schema* even if not in the v1 UI. Retrofitting is a
   migration; shipping the sealed type now is free.
4. **Lambing ease: adopt SRUC's 6-point scale (with "elective caesarean") or the spec's 5?** Decide
   before any data exists. §7.2 says 1–5 as five big buttons, which is the 3am-correct answer; a
   sixth button may not fit. Recommend staying at 5 and documenting that 5 covers elective.
5. **Default lambing-% definition per region?** AHDB (UK) says lambs born *alive*; Sheep Ireland
   counts dead lambs in "born". Both are the primary market (spec Open Question 3). Recommend AHDB's
   as the default and make the first-run settings copy name both.
6. **Does the terminology map need `few`/`many` plural forms?** Only if the app is ever localised to
   a language with more than two plural categories. Not v1.
7. **Hand-written CSV writer or `csv` 8.0.0?** A packaging/security call, not a domain one — flagged
   because of the unverified uploader on a dependency that will not be updated for years.
8. **Does `package:sqlite3` 3.5.0's bundled build enable FTS5?** Unverified. The runtime probe makes
   it safe either way, but confirming it decides whether the `LIKE` fallback ever ships.

---

# Sources

Fetched and used:

**Agricultural / veterinary domain**
- AHDB, *Reducing Lamb Losses for Better Returns* (Sheep Manual 14) — KPI formulas p.5, birthweights p.16 — https://projectblue.blob.core.windows.net/media/Default/About%20AHDB/Reducing%20Lamb%20Losses%202020.pdf
- Penn State Extension, *Does Your Flock Meet Your Performance Expectations?* — https://extension.psu.edu/does-your-flock-meet-your-performance-expectations
- Sheep Ireland, *How to Record a Lambing Event* — https://www.sheep.ie/how-to-record-a-lambing-event/
- SRUC / Farm Advisory Service, *TN747 Recording traits of lambing* — https://www.sruc.ac.uk/media/3ixfnvl5/tn-747-recording-traits-of-lambing.pdf
- Sheep Genetics (MLA), *Understanding Lambing Ease ASBVs* — https://www.sheepgenetics.org.au/globalassets/sheep-genetics/resources/lambing-ease-scoring-guideline.pdf
- National Sheep Association, *Terms to know* — https://nationalsheep.org.uk/terms-to-know/
- Huisman & Brown et al., *Effects of birth-rearing type on weaning weights in meat sheep*, Genet Sel Evol 2015 — https://pmc.ncbi.nlm.nih.gov/articles/PMC4489108/
- AHDB, *Sheep KPI validation project* — https://ahdb.org.uk/sheep-kpi-validation-project
- AHDB, *Sheep KPI validation project: phase II* — https://ahdb.org.uk/sheep-kpi-validation-project-phase-ii

**Medicine withdrawal periods**
- VICH, *Withdrawal periods for veterinary medicinal products* (Aug 2020) — https://vichsec.org/wp-content/uploads/2024/10/Report%20on%20calculation%20of%20withdrawal%20periods%20-final%20August%202020.pdf
- Fimea (Finnish Medicines Agency), *What is a withdrawal period?* — https://fimea.fi/en/veterinary/withdrawal_period_and_mrl/what_is_a_withdrawal_period
- NADIS, *Medicine Usage* — https://www.nadis.org.uk/disease-a-z/cattle/medicine-usage/
- Merck Veterinary Manual, *Withholding Periods After Anthelmintic Treatment in Animals* — https://www.merckvetmanual.com/pharmacology/anthelmintics/withholding-periods-after-anthelmintic-treatment-in-animals
- EMA/CVMP, *Guideline on determination of withdrawal periods for milk, Rev.1* — https://www.ema.europa.eu/en/documents/scientific-guideline/adopted-guideline-determination-withdrawal-periods-milk-revision-1_en.pdf

**Dart / Flutter**
- https://api.dart.dev/stable/dart-core/DateTime-class.html
- https://api.dart.dev/stable/dart-core/DateTime/add.html
- https://dart.dev/language/extension-types
- https://dart.dev/language/class-modifiers
- https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization
- https://github.com/dart-lang/clock (README)
- https://github.com/simolus3/sqlite3.dart/blob/main/sqlite3/README.md

**SQLite / persistence**
- https://www.sqlite.org/fts5.html
- https://www.sqlite.org/foreignkeys.html
- https://drift.simonbinder.eu/dart_api/tables/
- https://drift.simonbinder.eu/guides/datetime-migrations/

**pub.dev package pages (versions read 2026-07-27)**
- https://pub.dev/packages/clock · https://pub.dev/packages/fake_async
- https://pub.dev/packages/timezone · https://pub.dev/packages/timezone/changelog
- https://pub.dev/packages/flutter_timezone · https://pub.dev/packages/intl
- https://pub.dev/packages/drift · https://pub.dev/packages/sqlite3 · https://pub.dev/packages/sqlite3_flutter_libs
- https://pub.dev/packages/freezed · https://pub.dev/packages/csv · https://pub.dev/packages/fixed

**Fetched but unusable** (recorded for honesty): `signetdata.com/technical/genetic-notes/recording-lambing-ease/` (403), `sheep101.info/QandA/WD.html` (403), `sheep101.info/sheepandlambs.html` (403), `noah.co.uk/topics/regulation/controls-on-veterinary-medicines/` (404), BVL *Determination of Withdrawal Periods* (404), `drift.simonbinder.eu/sql_api/fts5/` and `/examples/full_text_search/` (404), `sqlite3.dart/hook/build.dart` (defines not inlined — FTS5 flag unverified).

**Verification environment:** Dart SDK 3.12.2 (stable) macos_arm64, Flutter 3.44.6, `TZ=Europe/London`. All snippets compiled; 48 tests green; `dart analyze` clean.

---
---

# Addendum — independent second-pass research (2026-07-27)

*This section was produced by a separate research pass over the same brief, working from primary
sources only. Everything above was left untouched. Recorded here are the **six findings that pass did
not already contain**, each of which either (a) hardens a rule that was previously argued from
principle rather than from a citable authority, or (b) corrects a bucket boundary. Where this
addendum and the body above disagree, the disagreement is stated explicitly rather than merged.*

*Method note, for honesty: this pass had no web-search budget left, so discovery was done through
DuckDuckGo's HTML endpoint plus direct URL fetches, and two regulatory PDFs were fetched and their
text extracted locally with `pypdf`. No Dart was compiled in this pass — the snippets above remain the
verified ones.*

---

## A1. Rule 2 is a *shipping* constraint, not only an ethical one — App Store Guideline 1.4.2

Part 1.2 above argues "never give veterinary advice" from first principles and builds a banned-phrase
CI check. That is right, but it understates the stakes: for a **single developer**, computing a dose is
not merely distasteful, it is **not shippable**. From the
[App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), verbatim:

> **1.4.2** Drug dosage calculators must come from the drug manufacturer, a hospital, university,
> health insurance company, pharmacy or other approved entity, or receive approval by the FDA or one
> of its international counterparts. Given the potential harm to patients, we need to be sure that the
> app will be supported and updated over the long term.

> **1.4.1** Medical apps that could provide inaccurate data or information, or that could be used for
> diagnosing or treating patients may be reviewed with greater scrutiny. […] Apps should remind users
> to check with a doctor in addition to using the app and before making medical decisions.

Consequences for this app:

1. **The moment Shed Book multiplies a bodyweight by a mg/kg figure, it is a drug dosage calculator**,
   and 1.4.2 says a solo developer may not ship one. This is the hard edge that the "computation rule"
   in Part 1.2 was reaching for. Put the guideline number in the code-review checklist next to §12.2 —
   a reviewer who knows the rule is enforced by App Review will hold the line harder than one who
   knows only that it is impolite.
2. It **licenses** the arithmetic the app does need. Counting down from a number the user typed is not
   a dosage calculation; no number is originated. The line is *origination*, not *arithmetic*.
3. Guideline 1.4.1's "remind users to check with a doctor" has no clean veterinary analogue, and
   attempting one would itself breach §12.2 (`\bcall (the|your) vet\b` is on the banned list above,
   correctly). The export disclaimer in Part 1.3 is the right place for that duty to land instead —
   which is another reason it must be structurally undroppable.

**Add to the boundary table in Part 1.2** the two rows that Guideline 1.4.2 makes non-negotiable:

| The app MAY | The app MUST NOT |
|---|---|
| Multiply nothing involving a medicine | Compute a dose from a bodyweight, concentration, or rate — this *is* a dosage calculator (1.4.2) |
| Store `dose` as free text exactly as the user wrote it | Parse `dose` into a number and do arithmetic on it |

That second row is the sneaky one. A future "helpful" feature that parses `2 ml` out of the dose field
to total up a bottle's remaining volume crosses the line in a way that looks like inventory
management. If bottle-volume tracking is ever wanted, it must take a separate, explicitly user-entered
quantity and never derive one from the clinical dose string.

---

## A2. The EMA milk guideline settles "days or hours" with primary-source language

Part 3.4 recommends absolute-time arithmetic (`treatmentInstant + N × 24 h`, then ceil to local
midnight) and argues it from VICH's rounding convention. That recommendation is **correct and this
addendum does not change it** — but there is a stronger citation available, and it was not used.

[EMA/CVMP/SWP/735418/2012 *Guideline on determination of withdrawal periods for milk*, Rev. 1, §4.1.1](https://www.ema.europa.eu/en/documents/scientific-guideline/adopted-guideline-determination-withdrawal-periods-milk-revision-1_en.pdf)
— verbatim, from the PDF text:

> "For example, a milk withdrawal period of 108 hours means that all the milk up to and including the
> last milking before 108 hours after treatment must be discarded. Depending on the time of treatment
> in a 12-hours milking cycle the last milk to be discarded may be from the milking at any time point
> at or after 96 hours after treatment but earlier than 108 hours after treatment. In this example
> milk from the first milking at or after 108 hours is considered safe. Similarly, a milk withdrawal
> period of 12 hours means that all milkings within a 12 hour period from the last treatment must be
> discarded and only milk taken at or after 12 hours is considered safe."

And §4.1.2 on units:

> "The withdrawal period for milk is initially calculated in milkings and rounded up to the first
> higher full number of milkings. […] because a different milking frequency can be used in practice,
> the final unit of the milk withdrawal period should be real time. For this reason, the final
> withdrawal period is rounded up to multiples of 12 hours or whole days and expressed in hours or
> days, respectively."

Three things this pins down that were previously inferred:

1. **"at or after N hours" is the regulator's own phrasing.** The withdrawal period is elapsed real
   time measured from the treatment *instant*. This is direct evidence for the `Instant + Duration`
   model over any civil-day model — stronger than the VICH rounding argument, because it describes how
   the period is *read*, not how it was *derived*.
2. **"the final unit […] should be real time"** — explicitly. A label number is a duration, not a
   count of sleeps.
3. **Rounding is upward, twice** (to whole milkings, then to whole 12-hour or 24-hour multiples). The
   ceil-to-next-local-midnight step in Part 3.4 is therefore *consistent with the regulator's own
   conservatism*, not an extra layer of paranoia bolted on top. That is worth saying in the code
   comment, because the next developer's instinct will be to "fix" the apparent over-hold.

**Where this sharpens Part 3.4's `WithdrawalMilkings(int)` v2 note:** the EMA text says milkings are
converted to real time *for the label*, so the sealed subtype should be modelled as
`WithdrawalMilkings(count, assumedIntervalHours: 12)` and immediately projected to an instant. Storing
"6 milkings" without an interval is not resolvable to a clear time, and guessing the interval would be
originating a number.

---

## A3. NADIS's **sheep** page kills the lookup-table idea outright

Part 1.1 cites NADIS's *cattle* medicine-usage page. The **sheep** page carries a sentence that is the
single strongest justification for §12.1 anywhere in the sourced material, and it is not quoted above.
From [NADIS, *Sheep — Medicine Usage*](https://www.nadis.org.uk/disease-a-z/sheep/medicine-usage/),
on reading withdrawal periods off the product:

> "Check these each time a drug is purchased and administered. **These can change for the same medicine
> and differ between products with the same active ingredient.**"

This upgrades the argument from *"a bundled withdrawal table would be a maintenance burden"* to
**"a bundled withdrawal table is wrong by construction, and no maintenance schedule fixes it."** The
same trade name, bought twice, can carry two different numbers. Any lookup — shipped, learned from the
user's own history, or "helpfully" pre-filled from the last treatment of the same product — is
therefore capable of being confidently wrong.

Two concrete consequences, both worth adding to the checklist:

1. **The repeat-last-treatment shortcut (§7.5) must copy product, dose, route and batch, and leave the
   withdrawal field empty.** This is the highest-risk feature in the app for §12.1, because
   pre-filling everything *except* one field feels like an oversight to whoever implements it. Comment
   the omission at the call site with this NADIS quote, or it will be "fixed".
2. **Do not build a per-user learned default** ("you usually enter 28 for this product"). It fails for
   exactly the reason NADIS gives, and it fails silently.

The same page also states the statutory record-keeping duty — products and batch numbers, dates and
quantities, withdrawal periods, kept *"at least five years"*, *"durable, permanent"* and *"available
for inspection"*. That is useful for Part 1.3: Shed Book stores precisely those fields, which is
exactly **why** it is at risk of being mistaken for the statutory record, and why the disclaimer has to
be structural rather than a settings-screen paragraph. It also argues for the medicine-record PDF
carrying the disclaimer on *every* page — a shepherd hands an inspector one page, not a document.

---

## A4. Fostering: the industry models a **rear type**, and Part 5 should derive it

Part 5's type-level invariant (`birthDamId` `final`, no `copyWith` that accepts it) is the right
mechanism and this addendum does not weaken it. What is missing is the *other half* of the standard
industry model, which turns out to be the thing that keeps the counts honest.

[NSIP (US National Sheep Improvement Program), *Recording Orphan and Foster Lambs*](https://nsip.org/wp-content/uploads/2026/04/Recording-Orphan-and-Foster-Lambs-4-Aug-2020-RLB-Edits.pdf)
— verbatim, on grafting a lamb onto another ewe:

> "you will record the lamb as normal by recording the sire and dam of each lamb, the birth date the
> appropriate birth type (3) and birth weight. **The rearing type will be whatever that lamb will be
> raised on with its new foster ewe.**"

> "Using this method, the original biological dam will 'get credit' for having this lamb but she will
> **not** 'get credit' for raising this lamb, rather the foster ewe will be listed as having raised
> this lamb."

And the worked example, which is the fixture to encode:

> "Ewe ID 621234-2018-123456 has a set of triplets on March 3, 2020. We made the decision to have the
> ewe raise 2 of the lambs […] and we will artificially rear 1 […] each lamb will have a **Birth Type
> of 3 and a Rear Type of 2**."

For a bottle lamb, NSIP requires a *phantom foster ewe*, because — verbatim — *"This prevents the
biological dam of a bottle lamb from receiving credit for rearing it."*

[Sheep Ireland](https://www.sheep.ie/recording-foster-and-pet-lambs-properly-is-crucial/) independently:
*"Foster lambs should be assigned to the genetic dam"*, with the warning that *"If lambs are recorded
under the foster ewe's information, the foster ewes are given credit for rearing two lambs even though
she has only given birth to one."*

**What to add to Part 5:**

```dart
/// NSIP's "rear type": how many live lambs this lamb is being reared alongside.
/// DERIVED on read, never stored. Storing it would create a second source of
/// truth that every foster must remember to update — and the one it forgets is
/// the one that produces a wrong number on the ewe card.
int rearTypeOf(LambId id, FlockSnapshot s) {
  final lamb = s.lamb(id);
  if (lamb.rearingDamId == null) return 1;          // bottle — NSIP's phantom foster ewe,
                                                    // expressed as an honest null
  return s.lambs.where((l) => l.rearingDamId == lamb.rearingDamId && l.isAlive).length;
}
```

Three points that follow:

1. **`birth_type` is a property of the lambing event and fostering must not touch it.** NSIP is
   explicit: the grafted lamb keeps birth type 3. Part 5's invariant covers the *dam*; add the
   symmetric test for the *birth type*, because a plausible implementation of "move a lamb" recomputes
   the litter.
2. **Model bottle-rearing as `rearingDamId == null` plus the existing `petLamb` flag**, not as a fake
   ewe row. NSIP needs a phantom ewe because its schema has no nullable rearing dam; ours can, and a
   null is honest where a phantom row is a fabricated animal that will surface in flock counts.
   Distinguish *bottle* (null by intent) from *unknown* (null by omission) — they are different facts
   and the rearing-credit numbers differ.
3. **The conservation property is what makes double-counting impossible**, and it holds because
   fostering is an `UPDATE` of one nullable foreign key — never an `INSERT`, never a `DELETE`. Born
   counts aggregate `Lamb` rows by `birth_dam_id`; reared counts aggregate the *same rows* by
   `rearing_dam_id`. One row cannot appear twice in either. Any design that models a litter as a list
   on the ewe loses this the first time a transaction is interrupted:

```dart
test('conservation: total lambs is invariant under any sequence of fosters', () async {
  final total = await repo.countLambs();
  for (final move in randomFosterSequence(200)) { await repo.foster(move); }
  expect(await repo.countLambs(), total);
  expect((await repo.lambCountsByBirthDam()).values.fold(0, (a, b) => a + b), total);
});
```

---

## A5. A fourth legitimate lambing-percentage definition — and it inverts the denominator

Part 4.1 sources AHDB, Penn State, Sheep Ireland and Teagasc, and Part 4.2 demonstrates four answers
from one season. Add **OMAFRA (Ontario Ministry of Agriculture, Food and Rural Affairs)**, because it
is the clearest published statement of the *opposite* convention to AHDB's and it is stated as a bare
formula with no hedging.

From [ontario.ca, *Measuring sheep flock productivity*](https://www.ontario.ca/page/measuring-sheep-flock-productivity):

| Metric | Verbatim formula | Denominator |
|---|---|---|
| Lambing percentage | *"number of lambs born ÷ number of ewes lambing × 100"* | **ewes lambing** |
| Weaning percentage | *"number of lambs weaned ÷ number of ewes lambing × 100"* | **ewes lambing** |
| Conception rate | *"number of ewes lambing ÷ number of ewes bred × 100"* | ewes bred |
| Pregnancy rate | *"number of ewes scanned pregnant ÷ number of ewes bred × 100"* | ewes bred |
| Pre-weaning lamb mortality | *"(number of lambs born – number of lambs weaned) ÷ number of lambs born × 100"* | lambs born |

Set against AHDB's house convention — *"Lambs sold finished, store, breeding or retained as a
percentage of Ewes and Shearlings (and ewe lambs as appropriate) put to the ram last year"*
([AHDB lamb KPIs](https://ahdb.org.uk/key-performance-indicators-kpis-for-lamb-sector)) — and the BVA
*In Practice* formulation *"number of lambs reared/ewes to the tup"* — the picture is that **two
national bodies publish different denominators under near-identical names.**

Worked contrast on one flock (100 to the ram, 92 lambed, 165 born):

- OMAFRA lambing percentage: 165 / 92 = **179%**
- AHDB-style, per ewe to the ram: 165 / 100 = **165%**

Fourteen points apart, both correct, both called "lambing percentage" in ordinary speech. This
**reinforces rather than revises** the document's existing decisions: keep AHDB's *per ewe put to the
ram* as the default for the UK/Ireland target market, keep `StatResult.definition` non-nullable, and
keep the definition travelling with the number into the CSV header and the PDF caption.

One addition it does argue for: OMAFRA's *"number of lambs born"* explicitly includes stillborn and
mummified lambs. Since Part 4 already offers a born-alive numerator, make the stillborn treatment an
explicit part of the definition label (`"lambs born incl. stillborn"` vs `"lambs born alive"`) rather
than a footnote. Two shepherds comparing numbers will differ on this before they differ on the
denominator, because it is the less visible choice.

---

## A6. Align the mortality age buckets with what a vet will expect

Part 4.3's `AgeBucket { stillborn, sameDay, day1to2, day3to7, day8to30, over30, unknownAge }` is
well-reasoned, and its insistence that a day-resolution `death_date` cannot support a *"under 24
hours"* label is **correct and should stand**. But the boundaries are invented, and the published
Irish figures a shepherd or vet will have seen use different ones.

From [Teagasc, *Lamb mortality — the main causes and timing*](https://www.teagasc.ie/news--events/daily/lamb-mortality-the-main-causes-and-timing/):

| Timing | Share of mortality |
|---|---|
| 0 hours (at birth) | 43% |
| < 24 hours | 15% |
| Day 1–3 | 16% |
| Day 4–7 | 6% |
| > Day 7 (to weaning) | 20% |

with *"The first three days after birth account for 74% of lamb mortality."* Causes, same source:
infection 32%, dystocia 20%, diagnosis not reached 19%, other incl. hypothermia and starvation 14%,
necropsy not completed 6%, accidental 5%, congenital 4%.

Recommendation — a small change with real benefit:

- Shift the buckets to `{ stillbornOrAtBirth, sameDay, day1to3, day4to7, day8plus, unknownAge }` so a
  Shed Book season summary can be read **directly against the published figures**. `day1to2` +
  `day3to7` splits the literature's `day1to3` boundary and makes the comparison impossible without
  arithmetic the shepherd will not do.
- Keep Part 4.3's `sameDay` label exactly as it is. Teagasc's `0 h` and `<24 h` split is available to a
  research abattoir with a death time; it is **not** available from a civil `death_date`, and claiming
  it would be the silent precision inflation Part 4.3 correctly refuses. Only surface the finer split
  where a death *instant* actually exists.
- Note in the UI that "diagnosis not reached" is 19% of deaths even in a *studied* population. That is
  a good argument for Part 4.3's `unattributed` bucket being prominent rather than hidden — a shepherd
  seeing a large unattributed share is seeing something real, not a personal failing.

---

## Addendum sources (fetched 2026-07-27, this pass only)

**Platform policy**
- https://developer.apple.com/app-store/review/guidelines/ — Guidelines 1.4.1 and 1.4.2

**Medicines**
- https://www.ema.europa.eu/en/documents/scientific-guideline/adopted-guideline-determination-withdrawal-periods-milk-revision-1_en.pdf — EMA/CVMP/SWP/735418/2012 §4.1.1–4.1.2 (PDF text extracted locally)
- https://www.ema.europa.eu/en/glossary-terms/withdrawal-period — EMA glossary definition
- https://www.nadis.org.uk/disease-a-z/sheep/medicine-usage/ — **sheep** page: periods differ between products with the same active ingredient; 5-year durable records
- https://vichsec.org/wp-content/uploads/2024/10/Report%20on%20calculation%20of%20withdrawal%20periods%20-final%20August%202020.pdf — VICH (PDF text extracted locally; corroborates the body above)

**Fostering**
- https://nsip.org/wp-content/uploads/2026/04/Recording-Orphan-and-Foster-Lambs-4-Aug-2020-RLB-Edits.pdf — birth type vs rear type, phantom foster ewe, triplet worked example (PDF text extracted locally)
- https://www.sheep.ie/recording-foster-and-pet-lambs-properly-is-crucial/ — Sheep Ireland, assign to the genetic dam

**Statistics**
- https://www.ontario.ca/page/measuring-sheep-flock-productivity — OMAFRA formulas
- https://ahdb.org.uk/key-performance-indicators-kpis-for-lamb-sector — AHDB lamb KPI definitions
- https://bvajournals.onlinelibrary.wiley.com/doi/full/10.1002/inpr.331 — BVA *In Practice* (snippet only; article paywalled, HTTP 402)
- https://www.teagasc.ie/news--events/daily/lamb-mortality-the-main-causes-and-timing/ — mortality by timing and cause

**Consulted, no new material beyond the body above**
- https://www.merckvetmanual.com/management-and-nutrition/management-of-reproduction-sheep/measuring-reproductive-performance-of-sheep (names the metrics, publishes no formulas)
- https://www.sqlite.org/fts5.html · https://www.sqlite.org/lang_datefunc.html
- https://api.dart.dev/stable/dart-core/DateTime/add.html · https://api.dart.dev/stable/dart-core/DateTime/difference.html
- https://dart.dev/language/class-modifiers · https://dart.dev/language/extension-types
- https://drift.simonbinder.eu/guides/datetime-migrations/
- https://www.nist.gov/pml/special-publication-811/nist-guide-si-appendix-b-conversion-factors/nist-guide-si-appendix-b9 — lb→kg listed as 4.535 924 E-01 (7 s.f.); the exact 1959 definition is 0.453 592 37 kg, which is the value the body above uses

**Package pages re-read this pass (versions agree with the body above)**
- https://pub.dev/packages/clock (1.1.2) · https://pub.dev/packages/timezone (0.11.1, tzdata 2025c) · https://pub.dev/packages/flutter_timezone (5.1.0) · https://pub.dev/packages/drift (2.34.2) · https://pub.dev/packages/intl (0.20.3) · https://pub.dev/packages/freezed (3.2.5) · https://pub.dev/packages/flutter_local_notifications (22.2.0) · https://pub.dev/packages/decimal (3.2.5)

**Fetched but unusable this pass** (recorded for honesty): `ahdb.org.uk/knowledge-library/key-performance-indicators-for-the-sheep-industry` (404), `gov.uk/guidance/withdrawal-periods-for-medicines-in-food-producing-animals` (404), `bvajournals.onlinelibrary.wiley.com/doi/full/10.1002/inpr.331` (402 paywall — snippet only), `nist.gov/pml/owm/metric-si/unit-conversion` (references the tables but does not reproduce them).
