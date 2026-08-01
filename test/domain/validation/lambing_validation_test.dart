// test/domain/validation/lambing_validation_test.dart — checkLambing, and the
// seven codes it raises.
//
// Zone-agnostic and relational; the three time-shaped codes are pinned to
// absolute UK wall-clock values in test/domain/uk_zone/lambing_checks_dst_test.dart.
//
// Every case asserts the same thing twice over: which warning came back, and
// that nothing went in the other direction. 12 §10.4's point is that §12.4 is
// proved by THE RECORD BEING UNCHANGED, not by the warning appearing.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/birth_type.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/recorded_time.dart';
import 'package:shed_book/domain/units/grams.dart';
import 'package:shed_book/domain/validation/lambing_checks.dart';
import 'package:shed_book/domain/validation/warning.dart';

/// June: transition-free in Europe/London, Pacific/Chatham and UTC.
final Instant _now = Instant.fromDateTime(DateTime(2026, 6, 3, 20));
final LocalDate _today = LocalDate.of(_now);

/// The ordinary call: everything agrees, nothing is questionable. Each case
/// overrides exactly the one thing it is about, so a warning that appears is
/// attributable.
List<Warning> _check({
  BirthType? declaredBirthType = BirthType.single,
  int lambCount = 1,
  RecordedTime? time,
  LocalDate? storedLocalDate,
  LocalDate? seasonStart,
  Instant? now,
  List<Grams?> birthWeights = const <Grams?>[Grams(4500)],
  List<({LocalDate? deathDate, bool isDead})> lambOutcomes =
      const <({LocalDate? deathDate, bool isDead})>[],
}) => checkLambing(
  declaredBirthType: declaredBirthType,
  lambCount: lambCount,
  time: time ?? RecordedTime.capture(_now),
  storedLocalDate: storedLocalDate ?? _today,
  seasonStart: seasonStart ?? LocalDate(2026, 3, 1),
  now: now ?? _now,
  birthWeights: birthWeights,
  lambOutcomes: lambOutcomes,
);

void main() {
  test('a declared twin with three lambs returns birthTypeLambCountMismatch '
      'and changes nothing', () {
    // Spec §12.4's own worked example: "If a birth type of 'twin' has three
    // lambs attached, flag it; do not fix it."
    const BirthType declared = BirthType.twin;
    const int lambCount = 3;

    final List<Warning> warnings = _check(declaredBirthType: declared, lambCount: lambCount);

    expect(warnings.single.code, WarningCode.birthTypeLambCountMismatch);
    expect(warnings.single.message, 'Birth type is twin but 3 lambs are recorded.');
    expect(warnings.single.fieldPath, 'birth_type');

    // The other half, and the one that matters: nothing was changed to make the
    // two agree. There is no return path that could have.
    expect(declared, BirthType.twin);
    expect(lambCount, 3);
  });

  test('quintPlus with seven lambs is undefined, not a contradiction — no warning', () {
    // The case a `.code` implementation silently fails. BirthType.quintPlus.code
    // is 5, so comparing against it fires on every set of sextuplets — the app
    // inventing a fact. expectedLambCount returns null, and null means the
    // question does not arise.
    expect(_check(declaredBirthType: BirthType.quintPlus, lambCount: 7), isEmpty);
    expect(_check(declaredBirthType: BirthType.quintPlus, lambCount: 5), isEmpty);
  });

  test('a null declared birth type warns about nothing', () {
    // R6: declared_birth_type is nullable, and a lambing with none yet is the
    // NORMAL state — the row is created on screen entry (decision #11).
    // Warning about "you have not chosen a birth type" would be the app nagging
    // at 03:20, and P8 means there is no chooser to nag about anyway.
    expect(_check(declaredBirthType: null, lambCount: 3), isEmpty);
  });

  test('single with one lamb is silent', () {
    expect(_check(), isEmpty);
  });

  test('effective 3 minutes ahead of now raises lambingInFuture; '
      '1 minute ahead does not', () {
    // The 2-minute grace is not a rounding allowance: it absorbs a device clock
    // a minute or two ahead of the phone that wrote the row. Tighten it to zero
    // and every auto-captured lambing warns about itself on a fast clock.
    final List<Warning> ahead = _check(
      time: RecordedTime.entered(effective: _now.plus(const Duration(minutes: 3)), now: _now),
      storedLocalDate: LocalDate.of(_now.plus(const Duration(minutes: 3))),
    );
    expect(ahead.single.code, WarningCode.lambingInFuture);
    expect(ahead.single.message, 'This time is in the future.');

    expect(
      _check(
        time: RecordedTime.entered(effective: _now.plus(const Duration(minutes: 1)), now: _now),
        storedLocalDate: LocalDate.of(_now.plus(const Duration(minutes: 1))),
      ),
      isEmpty,
    );
  });

  test('a lambing the civil day before seasonStart raises lambingBeforeSeasonStart; '
      'on the start date it does not', () {
    final List<Warning> before = _check(seasonStart: _today.plusDays(1));
    expect(before.single.code, WarningCode.lambingBeforeSeasonStart);
    expect(before.single.message, 'This is before the season start (${_today.plusDays(1).iso}).');

    expect(_check(seasonStart: _today), isEmpty, reason: 'the start date itself is inside');
  });

  test('capturedAt 73 h after effective raises lambingLongBeforeCapture; 71 h does not', () {
    // Measured in ABSOLUTE time. A civil +3 across the spring-forward is 71
    // hours, and a civil-day implementation fires an hour early on the one
    // weekend of the year that is also peak lambing.
    final Instant effective = _now.plus(const Duration(hours: -73));
    final List<Warning> late = _check(
      time: RecordedTime.entered(effective: effective, now: _now),
      storedLocalDate: LocalDate.of(effective),
      seasonStart: LocalDate(2026, 3, 1),
    );
    expect(late.single.code, WarningCode.lambingLongBeforeCapture);
    expect(late.single.message, 'Recorded more than 3 days after the time entered.');

    final Instant justInside = _now.plus(const Duration(hours: -71));
    expect(
      _check(
        time: RecordedTime.entered(effective: justInside, now: _now),
        storedLocalDate: LocalDate.of(justInside),
        seasonStart: LocalDate(2026, 3, 1),
      ),
      isEmpty,
    );
  });

  test('Grams(999) and Grams(10001) raise implausibleBirthWeight; '
      'Grams(1000) and Grams(10000) do not', () {
    // Both bounds are INCLUSIVE-PASS. An off-by-one here fires an amber strip at
    // every 1.0 kg hill twin in the county.
    expect(
      _check(birthWeights: const <Grams?>[Grams(999)]).single.code,
      WarningCode.implausibleBirthWeight,
    );
    expect(
      _check(birthWeights: const <Grams?>[Grams(10001)]).single.code,
      WarningCode.implausibleBirthWeight,
    );
    expect(_check(birthWeights: const <Grams?>[Grams(1000)]), isEmpty);
    expect(_check(birthWeights: const <Grams?>[Grams(10000)]), isEmpty);
    expect(
      _check(birthWeights: const <Grams?>[null]),
      isEmpty,
      reason: 'not weighed is not a value',
    );
  });

  test('the band warns and never clamps: a 400 g lamb comes back as 400 g', () {
    // kPlausibleBirthWeight is a band, not a limit. There is no min/max applied
    // to the value anywhere, and the message is 05 §7.5's wording exactly.
    const Grams asTyped = Grams(400);
    final List<Warning> warnings = _check(birthWeights: const <Grams?>[asTyped]);

    expect(warnings.single.message, '0.4 kg is outside the usual range for a lamb.');
    expect(warnings.single.fieldPath, 'birth_weight');
    expect(asTyped.value, 400, reason: 'stored exactly as typed');

    // And it is one constant at one site, so open question 12 is answered by
    // editing one line.
    expect(kPlausibleBirthWeight.min, const Grams(1000));
    expect(kPlausibleBirthWeight.max, const Grams(10000));
  });

  test('a death date one day before the lambing raises deathBeforeBirth', () {
    final List<Warning> warnings = _check(
      lambOutcomes: <({LocalDate? deathDate, bool isDead})>[
        (deathDate: _today.plusDays(-1), isDead: true),
      ],
    );

    expect(warnings.single.code, WarningCode.deathBeforeBirth);
    expect(warnings.single.message, 'The death date is before the lambing.');

    expect(
      _check(
        lambOutcomes: <({LocalDate? deathDate, bool isDead})>[(deathDate: _today, isDead: true)],
      ),
      isEmpty,
      reason: 'a lamb that died on the day it was born is stillborn, not impossible',
    );
  });

  test('a stored local_date one day off raises localDateDisagrees '
      'and returns nothing corrected', () {
    // 05 §6.9: if the device zone changed between insert and read, do NOT
    // recompute historical rows — local_date records the shepherd's day as it
    // was lived. This validator's whole job is to say the two disagree and stop.
    final LocalDate stale = _today.plusDays(-1);
    final List<Warning> warnings = _check(storedLocalDate: stale);

    expect(warnings.single.code, WarningCode.localDateDisagrees);
    expect(warnings.single.message, contains(stale.iso));
    expect(warnings.single.message, contains(_today.iso));
    expect(warnings.single.fieldPath, 'local_date');
    expect(stale, _today.plusDays(-1), reason: 'unchanged');
  });

  test('no validator returns a value: the return type is List<Warning> and nothing else', () {
    // The compile is the assertion. There is no arm of any of these functions
    // that hands back a repaired input, because there is no type in the
    // signature that could carry one.
    final List<Warning> warnings = _check(declaredBirthType: BirthType.twin, lambCount: 3);
    expect(warnings, isA<List<Warning>>());
  });

  test('two independent contradictions raise two warnings, in catalogue order', () {
    // Warnings accumulate; none of them supersedes or cancels another, and the
    // order is fixed so a screen renders the same list twice.
    final List<Warning> warnings = _check(
      declaredBirthType: BirthType.twin,
      lambCount: 3,
      birthWeights: const <Grams?>[Grams(400)],
    );

    expect(warnings.map((Warning w) => w.code).toList(), <WarningCode>[
      WarningCode.birthTypeLambCountMismatch,
      WarningCode.implausibleBirthWeight,
    ]);
  });
}
