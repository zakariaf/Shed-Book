// test/domain/uk_zone/media_shard_dst_test.dart
//
// The shard is a LOCAL civil month and the clocks change twice a year. Without
// TZ=Europe/London this file passes vacuously in UTC, which is exactly the bug
// it exists to catch.
@Tags(<String>['uk-zone'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/data/media_store.dart';

import '../../support/harness.dart';

void main() {
  setUpAll(() {
    // FIRST AND LOUDLY, and a SUMMER date: a winter date's expected offset is
    // Duration.zero, which is also UTC's — so the guard would pass on the
    // ubuntu-latest runner and the file would go green in the wrong zone.
    expect(
      DateTime(2026, 7).timeZoneOffset,
      const Duration(hours: 1),
      reason:
          'Run this file with TZ=Europe/London. '
          'Found ${DateTime(2026, 7).timeZoneName} '
          '(${DateTime(2026, 7).timeZoneOffset})',
    );
  });

  test('a photo taken at 00:30 BST on 1 April is filed under 2026/04, not 2026/03', () {
    // THE CASE THE UTC SHARD FAILS. 00:30 BST on 1 April 2026 is
    // 2026-03-31T23:30Z. A UTC shard files it under 2026/03 and silently
    // disagrees with the shepherd's own calendar — the directory is
    // human-legible, so it has to agree with the human.
    //
    // A SINGLE-INSTANT ASSERTION, which is the only kind atFixed permits.
    final String path = atFixed(
      DateTime.utc(2026, 3, 31, 23, 30),
      () => MediaStore().newRelativePath('jpg'),
    );

    expect(path, startsWith('2026/04/'), reason: 'the shard is the LOCAL civil month');
  });

  test('a photo taken at 00:30 GMT on 1 January is filed under the same month either way', () {
    // The control. In winter the local and UTC months agree, so this case
    // passing proves nothing on its own — it is here so the case above cannot
    // be "fixed" by a change that breaks the ordinary path.
    final String path = atFixed(
      DateTime.utc(2026, 1, 1, 0, 30),
      () => MediaStore().newRelativePath('jpg'),
    );

    expect(path, startsWith('2026/01/'));
  });

  test('the clocks-back night files by the local month too', () {
    // 25 October 2026, 01:30 — the hour that happens twice. Both candidates are
    // in October in both zones, so what this asserts is that the shard is
    // STABLE across the ambiguity rather than flipping with the offset.
    for (final DateTime candidate in <DateTime>[
      DateTime.utc(2026, 10, 25, 0, 30),
      DateTime.utc(2026, 10, 25, 1, 30),
    ]) {
      final String path = atFixed(candidate, () => MediaStore().newRelativePath('jpg'));
      expect(path, startsWith('2026/10/'), reason: '$candidate');
    }
  });
}
