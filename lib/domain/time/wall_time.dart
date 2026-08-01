import 'package:shed_book/domain/validation/warning.dart';

/// Did the wall-clock time the user typed actually exist in the device zone?
///
/// Dart moves a nonexistent local time forward with no exception — that is Dart
/// correcting the user, so we surface it. Empty when the time exists; one
/// warning when it does not. There is deliberately no `bool`-returning variant:
/// one would give the caller a way to check without surfacing.
///
/// **The ambiguous hour is deliberately not warned about.**
/// `checkLocalWallTimeExists(2026, 10, 25, 1, 30)` returns `const []`. The
/// displayed time still matches what the shepherd typed, so nothing was
/// silently corrected from their point of view, and the 60 minutes of ambiguity
/// are unambiguous in the exported UTC column anyway. 05 §2.9 lists warning
/// about it as an anti-pattern: one hour a year, zero visible effect, and noise
/// at 3am is a defect.
///
/// The predicate checks hour, minute and **day** — not month and not year. A
/// spring-forward shift moves the clock forward by an hour, so it can roll the
/// day but never the month. If you ever harden it, add the 23:30-on-31-December
/// case to the table rather than changing the check silently.
///
/// This file imports nothing from `lib/core/` — the reverse direction is
/// `lib/core/time/app_clock.dart` importing this layer, and `layer.domain`
/// makes the other way round a build failure.
List<Warning> checkLocalWallTimeExists(int y, int mo, int d, int h, int mi) {
  final DateTime built = DateTime(y, mo, d, h, mi);
  if (built.hour == h && built.minute == mi && built.day == d) {
    return const <Warning>[];
  }
  return <Warning>[
    Warning(
      WarningCode.timeDoesNotExistLocally,
      'The clock skipped ${_hhmm(h, mi)} that night (clocks went forward). '
      'Saved as ${_hhmm(built.hour, built.minute)}.',
      fieldPath: 'time',
    ),
  ];
}

String _hhmm(int h, int mi) => '${h.toString().padLeft(2, '0')}:${mi.toString().padLeft(2, '0')}';
