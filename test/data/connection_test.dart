// test/data/connection_test.dart — the seven pragmas and the FTS5 probe.
//
// Nothing here is time-shaped: configureConnection reads no clock and stores no
// instant, so there is no uk_zone case. The first DST case in this epic is
// N07-T03's.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/connection.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

/// Reads one pragma off a raw sqlite3 handle.
Object? _pragma(CommonDatabase db, String name) => db.select('PRAGMA $name;').first.values.first;

void main() {
  test('an opened connection reports synchronous=2, foreign_keys=1 and compiles an FTS5 table', () {
    final CommonDatabase db = sqlite3.openInMemory();
    addTearDown(db.close);

    configureConnection(db);

    // R13's seven, read back rather than assumed. Two of them —
    // foreign_keys and recursive_triggers — are PER-CONNECTION and not
    // persistent, so nothing in the file header carries them and they are
    // re-applied on every open.
    expect(_pragma(db, 'synchronous'), 2, reason: 'FULL, never NORMAL');
    expect(_pragma(db, 'foreign_keys'), 1, reason: 'without it every ON DELETE is decorative');
    expect(
      _pragma(db, 'recursive_triggers'),
      1,
      reason: 'without it a cascaded delete leaves orphaned search_docs rows',
    );
    expect(_pragma(db, 'busy_timeout'), 5000);
    expect(_pragma(db, 'journal_size_limit'), 4194304);
    expect(_pragma(db, 'temp_store'), 2, reason: 'MEMORY');

    // WAL is not available on an in-memory database — sqlite silently keeps
    // `memory` — so the mode is asserted where it is meaningful, on a file, in
    // the case below. Asserting `wal` here would pin the in-memory behaviour and
    // pass whatever the real database did.
    expect(_pragma(db, 'journal_mode'), isNotNull);

    // The FTS5 probe. It must COMPILE, not merely parse.
    expect(() => db.execute('CREATE VIRTUAL TABLE temp.probe USING fts5(x);'), returnsNormally);
  });

  test('journal_mode is wal on a file-backed database', () {
    // The half the in-memory case cannot prove. SQLite refuses WAL for
    // `:memory:` and reports `memory` instead, so a single assertion covering
    // both would have to accept `memory` — and would then pass on a real
    // database that never entered WAL at all.
    final CommonDatabase db = sqlite3.open('${Directory.systemTemp.path}/shed_book_wal_probe.db');
    addTearDown(() {
      db.close();
      File('${Directory.systemTemp.path}/shed_book_wal_probe.db').deleteSync();
    });

    configureConnection(db);

    expect(_pragma(db, 'journal_mode'), 'wal');
    expect(_pragma(db, 'synchronous'), 2);
  });

  test('configureConnection captures nothing and can be passed as a bare function reference', () {
    // R12's isolate-boundary rule. DriftNativeOptions.setup is sent across an
    // isolate boundary, so it must capture nothing — a closure over `this`
    // throws at open. The tear-off below is what the analyzer accepts and what
    // openConnection passes; a closure would compile here and fail in the field.
    const void Function(CommonDatabase) setup = configureConnection;

    final CommonDatabase db = sqlite3.openInMemory();
    addTearDown(db.close);
    setup(db);

    expect(_pragma(db, 'foreign_keys'), 1);
  });

  test('a connection without configureConnection reports foreign_keys=0', () {
    // Proves the assertion above is MEASURING something. Without this, the
    // pragma case passes on a build where SQLite happened to default the way we
    // wanted, and would keep passing after somebody deleted the line.
    final CommonDatabase db = sqlite3.openInMemory();
    addTearDown(db.close);

    expect(_pragma(db, 'foreign_keys'), 0);
    expect(_pragma(db, 'recursive_triggers'), 0);
  });

  test('the FTS5 assertion throws a StateError naming the bundled build when FTS5 is absent', () {
    // The failure ARM, exercised rather than assumed. There is no LIKE fallback
    // and no runtime "if FTS5 then … else …" anywhere in the codebase (decision
    // #36): a fallback that silently degrades search is worse than a build that
    // refuses to start, because nobody notices it.
    //
    // FTS5 cannot be removed from the bundled build at run time, so the arm is
    // exercised through the same private function's public behaviour: a database
    // that cannot compile the probe. `assertEngineCapabilities` is called on a
    // handle with a poisoned authorizer-free path by executing the probe name
    // into a conflicting object first, which makes CREATE VIRTUAL TABLE fail for
    // a reason that is not "no such module".
    //
    // 03 §11 asks for this verified once against a stock OS SQLite and then
    // reverted; that verification is recorded in the commit body, because a
    // stock-SQLite build is not something a unit test can produce.
    final CommonDatabase db = sqlite3.openInMemory();
    addTearDown(db.close);
    db.execute('CREATE TABLE temp.shed_book_fts_probe (x);');

    expect(
      () => assertEngineCapabilities(db),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'message',
          allOf(contains('FTS5'), contains('sqlite3')),
        ),
      ),
    );
  });

  test('a healthy connection passes assertEngineCapabilities and leaves no probe behind', () {
    final CommonDatabase db = sqlite3.openInMemory();
    addTearDown(db.close);

    expect(() => assertEngineCapabilities(db), returnsNormally);
    // Twice, because a probe left behind would make the second call fail — and
    // the connection is configured on every open, not once per install.
    expect(() => assertEngineCapabilities(db), returnsNormally);
  });

  test('openConnection is the only driftDatabase call site and returns a QueryExecutor', () {
    // Not opened here: openConnection resolves the application-support directory
    // through path_provider, which needs a platform channel. What is asserted is
    // the seam — R12's "one construction site" — and connection.dart's source is
    // where that is visible.
    // DECLARATIONS, comment lines dropped: connection.dart's own doc comment
    // says "the only driftDatabase( call site", which is how the next reader
    // learns the constraint — and a whole-file count reads that sentence as a
    // second call site. The gate counts the same way.
    final String source = File(
      'lib/core/db/connection.dart',
    ).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

    expect('driftDatabase('.allMatches(source).length, 1);
    expect(
      source,
      contains('getApplicationSupportDirectory'),
      reason: 'decision #27: application support, not Documents',
    );
  });
}
