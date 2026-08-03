// test/domain/uk_zone/csv_local_rendering_test.dart — the CSV's local column,
// under a real zone.
//
// `09 §2.5` gives every instant TWO columns and they are never collapsed into
// one: `*_at_utc` is exact and machine-readable, `*_at_local` is the one a
// shepherd recognises. The pair looks redundant until the clocks go back, which
// is what the first case is for — two instants an hour apart both render `01:30`
// locally, and only the UTC column can tell them apart.
//
// Tagged `uk-zone` because every assertion here is an absolute wall-clock value.
// CI runs `test/domain` a second time under `TZ=Pacific/Chatham` with
// `--exclude-tags uk-zone`, where these cases are correctly red.
//
// **THE RENDERING LIVES IN THE TEST, NOT IN `CsvWriter`.** `09 §2.5`'s first
// consequence bans a locale-aware formatter from the writer, and `_field` has no
// `DateTime` arm at all: formatting is the caller's decision, so these cases
// assert the shape the callers (T02) must produce and the writer must carry
// through untouched.
@Tags(<String>['uk-zone'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/data/csv_writer.dart';
import 'package:shed_book/domain/policy/export_envelope.dart';
import 'package:shed_book/domain/time/instant.dart';

/// `dd/MM/yyyy HH:mm`, zero-padded by hand.
///
/// Hand-rolling is the price of banning a locale formatter from the writer, and
/// the leading zero is the thing hand-rolling gets wrong — `1:5` instead of
/// `01:05`. `09 §2.5` fixes the format; this is the shape T02's callers build.
String localCsv(Instant i) {
  final DateTime d = i.local;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

/// ISO-8601, UTC, milliseconds, `Z` — exact, and never a local ISO string.
String utcCsv(Instant i) => i.local.toUtc().toIso8601String();

void main() {
  test('an instant inside the ambiguous hour renders its local time with the offset in force', () {
    // 25 October 2026, the clocks-back Sunday. 01:30 BST and 01:30 GMT are one
    // hour apart in absolute time and identical on a kitchen clock.
    final Instant bst = Instant.fromDateTime(DateTime.utc(2026, 10, 25, 0, 30));
    final Instant gmt = Instant.fromDateTime(DateTime.utc(2026, 10, 25, 1, 30));

    expect(localCsv(bst), '25/10/2026 01:30');
    expect(localCsv(gmt), '25/10/2026 01:30');

    // BOTH ARE CORRECT, and that is exactly why the ISO column sits beside the
    // local one. This case exists to prove the pair is never collapsed into one
    // column in a tidy-up — the local column alone cannot order these two
    // events, and a withdrawal that started at the wrong one of them clears a
    // day early.
    expect(utcCsv(bst), isNot(utcCsv(gmt)));
  });

  test('a local rendering never loses its leading zero', () {
    final Instant i = Instant.fromDateTime(DateTime.utc(2026, 1, 5, 1, 5));
    expect(localCsv(i), '05/01/2026 01:05');
    expect(localCsv(i), isNot(contains(' 1:5')));
  });

  test("the zone label in the trailer is the export instant's, not the current clock's", () {
    // Built at a fixed WINTER instant. The label is a constructor parameter, so
    // running this in July cannot make it say BST — which is the property R48
    // and R23 exist for: `package:timezone` is confined to the notification seam
    // and `appNow()` is the only wall-clock reader in the app.
    final Instant january = Instant.fromDateTime(DateTime.utc(2026, 1, 15, 12));
    final CsvWriter w = CsvWriter(
      ExportEnvelope.standard(now: january, appVersion: '1.0.0'),
      localZoneLabel: 'GMT (UTC+00:00)',
    );

    final String body = String.fromCharCodes(
      w.encode(<String>['a'], const <List<Object?>>[]).sublist(3),
    );

    expect(body, contains('GMT (UTC+00:00)'));
    expect(body, isNot(contains('BST')));
  });
}
