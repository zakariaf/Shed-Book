// test/data/host_sqlite_version_test.dart — 12 §3.2.
//
// It lands in N07-T01 because from N07-T03 onward a host below the floor fails
// as a mystery — a STRICT table that will not compile, or an FTS5 module that is
// not there — instead of as a named assertion with a number in it.
//
// If this fails, THE FIX IS THE RUNNER IMAGE, never the assertion. Lowering the
// floor to whatever the runner happens to ship is how STRICT stops being tested.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('the host sqlite is new enough for STRICT and FTS5', () {
    // STRICT needs >= 3.37.0. The floor is 3.41.0, which has headroom and is a
    // number CI can prove.
    expect(
      sqlite3.version.versionNumber,
      greaterThanOrEqualTo(3041000),
      reason:
          'found ${sqlite3.version.libVersion}. Fix the runner image — '
          'libsqlite3-dev is the one line between a working and a red CI '
          '(12 §3.2) — never this number.',
    );
  });
}
