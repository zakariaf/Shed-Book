// test/data/uk_zone/local_log_dst_test.dart
//
// THE TIME-SHAPED HALF, AND IT IS NOT OPTIONAL: every record and the lock carry
// a timestamp, and a log whose timestamps are ambiguous cannot answer the one
// question it exists for — what happened, and in what order.
@Tags(<String>['uk-zone'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/log/local_log.dart';

void main() {
  setUpAll(() {
    // FIRST AND LOUDLY, with a SUMMER date: a winter date's expected offset is
    // Duration.zero, which is also UTC's, so the guard would pass on the
    // ubuntu-latest runner and this file would go green in the wrong zone.
    expect(
      DateTime(2026, 7).timeZoneOffset,
      const Duration(hours: 1),
      reason:
          'Run this file with TZ=Europe/London. '
          'Found ${DateTime(2026, 7).timeZoneName} '
          '(${DateTime(2026, 7).timeZoneOffset})',
    );
  });

  test('a session started in the ambiguous hour records an unambiguous UTC instant', () {
    // 01:30 on 25 October 2026 happens TWICE. A local-time startedAt is
    // ambiguous by exactly one hour on the one night of the year when it is
    // hardest to reason about — and six weeks before lambing.
    final Directory dir = Directory.systemTemp.createTempSync('shed_log_dst_');
    addTearDown(() {
      LocalLog.instance.resetForTest();
      dir.deleteSync(recursive: true);
    });
    LocalLog.instance.resetForTest();

    // The FIRST reading of 01:30 — still BST.
    final DateTime firstReading = DateTime.utc(2026, 10, 25, 0, 30);

    withClock(Clock.fixed(firstReading), () {
      LocalLog.instance.attachTo(dir);
    });

    final Map<String, Object?> lock =
        jsonDecode(File('${dir.path}/${LocalLog.lockName}').readAsStringSync())
            as Map<String, Object?>;
    final String startedAt = lock['startedAt']! as String;

    expect(startedAt, endsWith('Z'), reason: 'a local timestamp is ambiguous that night');
    expect(
      DateTime.parse(startedAt).toUtc(),
      firstReading,
      reason: 'the lock recorded a different instant from the one the clock gave',
    );

    // And the two readings of the same wall time are DIFFERENT instants, which
    // is the whole reason the Z matters.
    final DateTime secondReading = DateTime.utc(2026, 10, 25, 1, 30);
    expect(secondReading.difference(firstReading), const Duration(hours: 1));
    expect(firstReading.toLocal().hour, secondReading.toLocal().hour);
  });

  test('records written either side of the repeated hour stay in order on disk', () {
    // The ordering claim. Sorting by a LOCAL timestamp puts the second 01:30
    // before the first; the file is append-only and the timestamps are UTC, so
    // neither the order nor the reading of it can go wrong.
    final Directory dir = Directory.systemTemp.createTempSync('shed_log_dst_');
    addTearDown(() {
      LocalLog.instance.resetForTest();
      dir.deleteSync(recursive: true);
    });
    LocalLog.instance.resetForTest();
    LocalLog.instance.attachTo(dir);

    withClock(Clock.fixed(DateTime.utc(2026, 10, 25, 0, 30)), () {
      LocalLog.instance.record('nav.before');
    });
    withClock(Clock.fixed(DateTime.utc(2026, 10, 25, 1, 30)), () {
      LocalLog.instance.record('nav.after');
    });

    final String contents = File('${dir.path}/${LocalLog.logName}').readAsStringSync();
    expect(contents.indexOf('nav.before'), lessThan(contents.indexOf('nav.after')));
    expect(contents, contains('2026-10-25T00:30'));
    expect(contents, contains('2026-10-25T01:30'));
  });
}
