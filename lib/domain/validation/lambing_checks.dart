import 'package:shed_book/domain/birth_type.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/time/recorded_time.dart';
import 'package:shed_book/domain/units/grams.dart';
import 'package:shed_book/domain/validation/warning.dart';

/// The plausibility band, **NOT a limit**. Both bounds are inclusive-pass:
/// 1.0 kg and 10.0 kg do not warn.
///
/// Derived from AHDB's optimum birthweights for 70–85 kg ewes to a terminal
/// sire, widened downward for hill breeds. **PROVISIONAL** against
/// decision-record §7.1 open question 12.
///
/// One named constant at one site — not two literals at the check, not a pair of
/// parameters — precisely so that open question 12 can be answered by editing
/// one line.
///
/// It produces an observation and never a block. A 9 kg lamb is stored as 9 kg;
/// nothing anywhere clamps, rounds or substitutes a weight.
const ({Grams min, Grams max}) kPlausibleBirthWeight = (min: Grams(1000), max: Grams(10000));

/// Everything questionable about one lambing and its lambs. **It cannot fix any
/// of it**: nothing in scope writes, there is no repository here, and the return
/// type has no arm that could carry a repaired input.
///
/// **The signature deviates from 05 §7.5 guarantee 1, deliberately, and the
/// deviation is the only one that compiles.** That document spells the entry
/// point `List<Warning> checkLambing(Lambing lambing, List<Lamb> lambs)`, and 12
/// §10.4 calls it that way. `Lambing` and `Lamb` are drift row classes generated
/// into `lib/core/db/database.g.dart`; layer rule 1 gives `lib/domain/` only
/// `{lib/domain/, dart:*, meta, collection}`, and D2 bans `package:drift`
/// outright — the gate's `layer.domain` rule fails the build before `analyze`
/// reaches it. Named parameters keep everything the documents actually bind (the
/// `check<Thing>` → `List<Warning>` shape, one function per file, no class, no
/// `Validator` suffix) and invent no type name, so CONVENTIONS §2 needs no new
/// row. 05 §6.8 already sets the precedent: the domain takes plain records,
/// never rows. 12 §10.4's property — a query with no writer, the row unchanged
/// afterwards — never depended on the name.
///
/// [now] is a **parameter**. `package:clock` is banned here (D3, R24) and the
/// gate proves it; a validator that reads a clock cannot be tested at a
/// boundary, and [WarningCode.lambingInFuture]'s trigger *is* a boundary.
///
/// The ambiguous hour is deliberately **not** warned about (05 §2.9's
/// anti-pattern list). 01:30 on 25 October happens twice, the displayed time
/// still matches what the shepherd typed, and noise at 3am is a defect.
List<Warning> checkLambing({
  required BirthType? declaredBirthType, // nullable: R6
  required int lambCount,
  required RecordedTime time,
  required LocalDate storedLocalDate,
  required LocalDate seasonStart,
  required Instant now,
  required List<Grams?> birthWeights,
  required List<({LocalDate? deathDate, bool isDead})> lambOutcomes,
}) {
  final List<Warning> warnings = <Warning>[];

  // `expectedLambCount`, NEVER `.code`. BirthType.quintPlus.code is 5, so
  // comparing against the code fires on every set of sextuplets — the app
  // inventing a fact. A null expected count means the type is open-ended and the
  // question does not arise.
  //
  // A null declared type is the NORMAL state, not an omission: the row is
  // created on screen entry (decision #11), and birth type is derived from the
  // tally strokes (P8). Warning about it would be the app nagging at 03:20.
  final int? expected = declaredBirthType == null ? null : expectedLambCount(declaredBirthType);
  if (expected != null && expected != lambCount) {
    warnings.add(
      Warning(
        WarningCode.birthTypeLambCountMismatch,
        'Birth type is ${declaredBirthType!.name} but $lambCount lambs are recorded.',
        fieldPath: 'birth_type',
      ),
    );
  }

  // The 2-minute grace absorbs a device clock a minute or two ahead of the phone
  // that wrote the row. At zero, every auto-captured lambing warns about itself
  // on a fast clock.
  if (time.effective.isAfter(now.plus(const Duration(minutes: 2)))) {
    warnings.add(
      Warning(WarningCode.lambingInFuture, 'This time is in the future.', fieldPath: 'time'),
    );
  }

  if (LocalDate.of(time.effective).compareTo(seasonStart) < 0) {
    warnings.add(
      Warning(
        WarningCode.lambingBeforeSeasonStart,
        'This is before the season start (${seasonStart.iso}).',
        fieldPath: 'time',
      ),
    );
  }

  // ABSOLUTE time, not civil days. A civil +3 across the spring-forward is 71
  // hours, so a civil implementation fires an hour early on the one weekend of
  // the year that is also peak lambing.
  if (time.capturedAt.difference(time.effective) > const Duration(days: 3)) {
    warnings.add(
      Warning(
        WarningCode.lambingLongBeforeCapture,
        'Recorded more than 3 days after the time entered.',
        fieldPath: 'time',
      ),
    );
  }

  for (final Grams? weight in birthWeights) {
    // A null weight is "not weighed", which is not a value and not a problem.
    if (weight == null) {
      continue;
    }
    if (weight.value < kPlausibleBirthWeight.min.value ||
        weight.value > kPlausibleBirthWeight.max.value) {
      warnings.add(
        Warning(
          WarningCode.implausibleBirthWeight,
          '${_kilograms(weight)} kg is outside the usual range for a lamb.',
          fieldPath: 'birth_weight',
        ),
      );
    }
  }

  for (final ({LocalDate? deathDate, bool isDead}) outcome in lambOutcomes) {
    final LocalDate? died = outcome.deathDate;
    // Equal dates are a stillborn or a same-day loss, which is ordinary and
    // common. Only strictly-before is impossible.
    if (died != null && died.compareTo(storedLocalDate) < 0) {
      warnings.add(
        Warning(
          WarningCode.deathBeforeBirth,
          'The death date is before the lambing.',
          fieldPath: 'death_date',
        ),
      );
    }
  }

  // Shown, never applied. 05 §6.9: if the device zone changed between insert and
  // read, do NOT recompute historical rows — `local_date` is a record of the
  // shepherd's day as it was lived.
  final LocalDate fromTime = LocalDate.of(time.effective);
  if (storedLocalDate.compareTo(fromTime) != 0) {
    warnings.add(
      Warning(
        WarningCode.localDateDisagrees,
        'This lambing is recorded on ${storedLocalDate.iso}. '
        'The time given falls on ${fromTime.iso}.',
        fieldPath: 'local_date',
      ),
    );
  }

  return warnings;
}

/// `0.4`, `0.999`, `10.001` — enough digits to say which side of the band the
/// value fell, and no trailing zeros.
///
/// Not `package:intl`: D4 bans it here. This is a number inside an observation
/// the domain records, not the string a shepherd reads — a screen renders the
/// weight itself through `lib/core/ui/formatters.dart`.
String _kilograms(Grams g) {
  final String fixed = g.inKilograms.toStringAsFixed(3);
  final String trimmed = fixed.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.endsWith('.') ? '${trimmed}0' : trimmed;
}
