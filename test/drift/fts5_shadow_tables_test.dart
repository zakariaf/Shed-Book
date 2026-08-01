// test/drift/fts5_shadow_tables_test.dart — the day-one unverified claim,
// checked.
//
// THE QUESTION: does SchemaVerifier choke on FTS5 shadow tables? 00-README §9
// step 3 names it as the reason the freeze is early — "discovering that
// SchemaVerifier chokes on FTS5 shadow tables at v4 with real data is a
// different problem than discovering it in week one with none".
//
// THE ANSWER, measured on drift 2.34.2 / drift_dev 2.34.5 / sqlite3 3.5.0 with
// zero rows: it does NOT choke. A schema containing search_fts and its four
// shadow tables (_data, _idx, _docsize, _config) round-trips through
// schemaAt(1) and migrateAndValidate(1) without complaint.
//
// That answer is written down HERE rather than only in a commit message, because
// the next person to ask it will be at v4 with real data and will need to know
// whether it was ever true.
@Tags(<String>['migration'])
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';

import 'generated/schema.dart';

void main() {
  test('SchemaVerifier accepts a schema containing FTS5 shadow tables', () async {
    final SchemaVerifier verifier = SchemaVerifier(GeneratedHelper());
    final InitializedSchema schema = await verifier.schemaAt(1);
    final AppDatabase db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 1);
  });

  test('the shadow tables are actually there, so the case above is not vacuous', () async {
    // Without this, "SchemaVerifier accepts it" would pass on a schema that
    // never created an FTS5 table at all — which is exactly the shape a future
    // "simplification" of search.drift would leave behind.
    final SchemaVerifier verifier = SchemaVerifier(GeneratedHelper());
    final InitializedSchema schema = await verifier.schemaAt(1);
    final AppDatabase db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    final Set<String> tables =
        (await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get())
            .map((QueryRow r) => r.read<String>('name'))
            .toSet();

    expect(tables, contains('search_fts'));
    for (final String shadow in <String>[
      'search_fts_data',
      'search_fts_idx',
      'search_fts_docsize',
      'search_fts_config',
    ]) {
      expect(tables, contains(shadow), reason: shadow);
    }
  });

  test('the index is empty on a fresh database, which is why this is cheap now', () async {
    // Zero rows is the whole reason this question is answerable in week one. At
    // v4 with a season of notes in it, the same check is a migration nobody
    // wants to run twice.
    final SchemaVerifier verifier = SchemaVerifier(GeneratedHelper());
    final InitializedSchema schema = await verifier.schemaAt(1);
    final AppDatabase db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    final QueryRow count = await db
        .customSelect('SELECT COUNT(*) AS n FROM search_docs')
        .getSingle();
    expect(count.read<int>('n'), 0);
  });
}
