import 'package:shed_book/domain/stats/season_counts.dart';
import 'package:shed_book/domain/time/local_date.dart';

/// One day of the season. Bar height is **lambs** ([births]); [ewes] is a
/// different unit in the same chart. Label both, and never sum across them.
typedef SpreadBar = ({LocalDate date, int dayIndex, int births, int ewes});

/// The whole chart, plus the one-number answer under it.
typedef LambingSpread = ({List<SpreadBar> bars, int? ewesInFirstCycleDays, int cycleDays});

/// Dense and zero-filled. **The day range is generated from the SEASON BOUNDS,
/// never from the rows**: the gaps are the information, because *"was my tupping
/// tight?"* is a statement about gaps.
///
/// **The signature deviates from 05 §6.9 by two required parameters, and the
/// deviation is what makes the documented behaviour reachable at all.** §6.9
/// prints `lambingSpread(List<DayBirths> rows, {int cycleDays = 17})`, and
/// N06-T06 §5.4 requires the range to come from the season's `start_date` and
/// `end_date` — *"generating it from `rows.first.date` to `rows.last.date` looks
/// dense and silently deletes the empty days at both ends, which is where a
/// loose tupping shows."* Those two statements cannot both hold: with only
/// `rows`, the ends are unknowable. The task's own anchor settles it — a season
/// running 1–20 March with two births must produce twenty bars — so the bounds
/// are parameters. 05 §6.9 needs amending; that is the owner's.
///
/// [dayIndex] is anchored at 0 on the **season's first day**. §6.9 rule 3 says
/// *"anchored on the first lambing"*; N06-T06's own case name says the season's
/// first day, and that is the one that works: anchoring on the first lambing
/// puts day 0 on a different civil day in each season, which is exactly what
/// stops §7.8's two curves overlaying.
///
/// **The range is generated with [LocalDate.plusDays], never by adding
/// `Duration(days: 1)` to a local `DateTime`.** `plusDays` routes through
/// `DateTime.utc` deliberately (05 §2.4), so `+1` is exactly one calendar day.
/// The local version yields 23 h across the UK spring-forward and 25 h across
/// the autumn one, so a season spanning 29 March 2026 produces a duplicated or a
/// skipped civil day — once a year, in the middle of lambing.
///
/// Rows are matched on the denormalised `local_date`, never on UTC and never via
/// a SQL date function: a 00:05 lambing belongs to that day and a 23:55 one to
/// the day before, and getting it wrong is a once-per-night off-by-one for a
/// whole season. A row outside the bounds is **dropped, not folded into the
/// nearest bar** — moving a lambing to a day it did not happen on is worse than
/// omitting it, and the disagreement it usually indicates is surfaced by
/// `localDateDisagrees` and applied by nothing.
///
/// [cycleDays] has a default **and the app must never use it**. The value comes
/// from `app_settings.cycle_days`, whose column default is 17; this default
/// exists only so a unit test can omit it. Two defaults that can drift apart is
/// one too many — 05 §6.9 explicitly permits making the parameter `required` and
/// deleting this, and if the column default ever moves, that is the change to
/// make rather than editing the 17 here.
LambingSpread lambingSpread(
  List<DayBirths> rows, {
  required LocalDate seasonStart,
  required LocalDate seasonEnd,
  int cycleDays = 17,
}) {
  // A season with no lambings is a NAMED STATE, not an error: empty bars, a null
  // first-cycle count, and a chart that renders its named empty state — never a
  // spinner, never a zero-height chart.
  if (rows.isEmpty) {
    return (bars: const <SpreadBar>[], ewesInFirstCycleDays: null, cycleDays: cycleDays);
  }

  final Map<String, DayBirths> byDate = <String, DayBirths>{
    for (final DayBirths r in rows) r.date.iso: r,
  };

  final int days = seasonStart.daysUntil(seasonEnd) + 1;
  final List<SpreadBar> bars = <SpreadBar>[
    for (int i = 0; i < days; i++)
      () {
        final LocalDate date = seasonStart.plusDays(i);
        final DayBirths? row = byDate[date.iso];
        return (date: date, dayIndex: i, births: row?.births ?? 0, ewes: row?.ewes ?? 0);
      }(),
  ];

  // "Ewes lambed in the first 17 days." The ewe oestrous cycle is about 17 days,
  // so the share lambing within one cycle length is the direct single-number
  // answer. It is presented as a FACT — "32 of 48 ewes lambed in the first 17
  // days" — never as a judgement.
  final int ewesInWindow = bars
      .where((SpreadBar b) => b.dayIndex < cycleDays)
      .fold<int>(0, (int sum, SpreadBar b) => sum + b.ewes);

  return (bars: bars, ewesInFirstCycleDays: ewesInWindow, cycleDays: cycleDays);
}
