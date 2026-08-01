// test/design/uk_zone/formatters_dst_test.dart — the epic's only time-shaped
// code.
//
// A SEPARATE FILE, and that is forced rather than chosen. N09-T06 §5.4 asks for
// `group('DST', ..., tags: 'uk-zone')`, but flutter_test's `group` has no `tags`
// parameter — that is package:test's API, and flutter_test re-declares `group`
// as `group(Object, void Function(), {skip, retry})`. The tag has to be
// library-level, which means its own file, which is also the pattern every other
// uk-zone file in this project already uses.
//
// The `test` job runs `TZ=Europe/London --tags uk-zone` over the WHOLE suite, so
// a tagged file under test/design/ is picked up. An untagged DST case runs under
// the runner's own zone and proves nothing.
@Tags(<String>['uk-zone'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';

const String _gb = 'en_GB';

void main() {
  setUpAll(() {
    // FIRST AND LOUDLY. A summer date, because a winter date's expected
    // offset is Duration.zero, which is also UTC's — so the guard would pass
    // on the ubuntu-latest runner and the whole group would go green in the
    // wrong zone.
    expect(
      DateTime(2026, 7).timeZoneOffset,
      const Duration(hours: 1),
      reason:
          'Run this group with TZ=Europe/London. '
          'Found ${DateTime(2026, 7).timeZoneName} '
          '(${DateTime(2026, 7).timeZoneOffset})',
    );
    initializeDateFormatting(_gb);
  });

  test('this group requires TZ=Europe/London', () {
    expect(DateTime(2026, 7).timeZoneOffset, const Duration(hours: 1));
  });

  test('two instants one hour apart in the ambiguous 01:00 to 01:59 hour both '
      'render 01:30', () {
    // The clocks-back night, 25 October 2026. 01:30 happens twice, so two
    // DISTINCT instants render one local HH:mm.
    //
    // This is precisely why the provenance label is not optional, and why
    // the withdrawal clear date is computed in absolute time (decision #3)
    // and never in civil days.
    final Instant first = Instant(DateTime.utc(2026, 10, 25, 0, 30).millisecondsSinceEpoch);
    final Instant second = Instant(DateTime.utc(2026, 10, 25, 1, 30).millisecondsSinceEpoch);

    expect(
      second.epochMillis - first.epochMillis,
      const Duration(hours: 1).inMilliseconds,
      reason: 'the two instants really are an hour apart',
    );
    expect(formatShedTime(first, _gb), '01:30');
    expect(formatShedTime(second, _gb), '01:30');
  });

  test('formatShedDate renders one date for both of those instants', () {
    final Instant first = Instant(DateTime.utc(2026, 10, 25, 0, 30).millisecondsSinceEpoch);
    final Instant second = Instant(DateTime.utc(2026, 10, 25, 1, 30).millisecondsSinceEpoch);

    expect(formatShedDate(LocalDate.of(first), _gb), '25 Oct 2026');
    expect(formatShedDate(LocalDate.of(second), _gb), '25 Oct 2026');
  });

  test('the clocks-forward night has no local 01:30 and formatShedTime never '
      'invents one', () {
    // 29 March 2026: the local hour 01:00–01:59 does not exist. Dart's local
    // DateTime constructor rolls forward, so DateTime(2026, 3, 29, 1, 30) is
    // really 02:30 — and this asserts the presentation half does not paper
    // over that. checkLocalWallTimeExists() in lib/domain/time/wall_time.dart
    // is the domain half.
    final DateTime rolled = DateTime(2026, 3, 29, 1, 30);
    expect(rolled.hour, isNot(1), reason: 'the local 01:30 does not exist that night');

    final String rendered = formatShedTime(Instant.fromDateTime(rolled), _gb);
    expect(rendered, isNot('01:30'), reason: 'a time that did not happen was rendered');
    expect(rendered, '02:30');
  });

  test('a time in the ambiguous hour still renders as HH:mm with no offset suffix', () {
    // The app has no 12-hour path and no offset display. The disambiguation
    // lives in the record, not in the string.
    final Instant t = Instant(DateTime.utc(2026, 10, 25, 1, 30).millisecondsSinceEpoch);
    final String rendered = formatShedTime(t, _gb);

    expect(rendered, matches(RegExp(r'^\d{2}:\d{2}$')));
    expect(rendered, isNot(contains('GMT')));
    expect(rendered, isNot(contains('BST')));
    expect(rendered, isNot(contains('+')));
  });
}
