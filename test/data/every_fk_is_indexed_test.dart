// test/data/every_fk_is_indexed_test.dart — SQLite creates no child-key index by
// itself, so every foreign key needs a hand-written one (decision #31).
//
// It lands in N07-T03 rather than at the end of the epic BECAUSE IT GROWS
// SILENTLY: T04, T05 and T06 each add tables, and each new foreign key is swept
// by this file the moment it exists. Written last, it would be a one-off audit
// of a schema already frozen.
//
// A composite PRIMARY KEY or uniqueKeys entry indexes its LEADING column only —
// {season, ewe} on ewe_seasons indexes `season` and does nothing for `ewe` —
// which is why the assertion is about the leading column specifically.
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';

import '../support/harness.dart';

/// The one allowlisted table, and its reason.
///
/// **A second entry here is a review conversation, not an edit.** An unindexed
/// foreign key is a full table scan on every parent delete and on every join,
/// and the only table for which that is genuinely free is one with a single row.
const Map<String, String> kNoIndexNeeded = <String, String>{
  'app_settings': 'a singleton — one row, so a scan is the whole table anyway',
};

void main() {
  test('every foreign key has an index whose leading column is the child key', () async {
    final AppDatabase db = testDatabase();

    final List<QueryRow> tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    expect(tables, isNotEmpty);

    int keysChecked = 0;

    for (final QueryRow table in tables) {
      final String name = table.read<String>('name');
      if (kNoIndexNeeded.containsKey(name)) {
        continue;
      }

      final List<QueryRow> foreignKeys = await db
          .customSelect('PRAGMA foreign_key_list($name)')
          .get();
      if (foreignKeys.isEmpty) {
        continue;
      }

      // Every index on this table, with its leading column — plus the rowid
      // alias, which is an index without being one.
      //
      // MEASURED: ewe_touches declares PRIMARY KEY(ewe) over an INTEGER column,
      // which SQLite makes an alias for the rowid rather than a separate index,
      // so PRAGMA index_list reports nothing for it. Treating that as "no index"
      // would demand a redundant one on the fastest lookup the table has.
      final Set<String> leadingColumns = <String>{};
      for (final QueryRow column in await db.customSelect('PRAGMA table_info($name)').get()) {
        if (column.read<int>('pk') == 1 && column.read<String>('type').toUpperCase() == 'INTEGER') {
          leadingColumns.add(column.read<String>('name'));
        }
      }

      final List<QueryRow> indexes = await db.customSelect('PRAGMA index_list($name)').get();
      for (final QueryRow index in indexes) {
        final List<QueryRow> columns = await db
            .customSelect("PRAGMA index_info('${index.read<String>('name')}')")
            .get();
        if (columns.isEmpty) {
          continue;
        }
        final QueryRow first = columns.reduce(
          (QueryRow a, QueryRow b) => a.read<int>('seqno') <= b.read<int>('seqno') ? a : b,
        );
        final String? column = first.read<String?>('name');
        if (column != null) {
          leadingColumns.add(column);
        }
      }

      for (final QueryRow key in foreignKeys) {
        final String childColumn = key.read<String>('from');
        keysChecked++;
        expect(
          leadingColumns,
          contains(childColumn),
          reason:
              '$name.$childColumn is a foreign key with no index leading on it. '
              'SQLite creates no child-key index by itself (decision #31), so a '
              'parent delete scans the whole child table.',
        );
      }
    }

    // Asserted so a refactor that stops finding foreign keys is visible: a sweep
    // that checks nothing passes.
    expect(keysChecked, greaterThan(0));
  });

  test('the allowlist has exactly one entry, and it carries its reason', () {
    expect(kNoIndexNeeded, hasLength(1));
    expect(kNoIndexNeeded.values.single, isNotEmpty);
  });
}
