// test/drift/snapshot_count_test.dart — a one-line guard against a version
// bumped by two (04 §2.10).
//
// If kSchemaVersion is 3 and drift_schemas/ holds two files, stepByStep has no
// callback for the skipped hop — and the failure lands on a shepherd's phone
// during an upgrade, months later, with no way to push a fix.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';

void main() {
  test('drift_schemas/ holds exactly kSchemaVersion snapshots', () {
    final List<String> snapshots =
        Directory('drift_schemas')
            .listSync()
            .whereType<File>()
            .map((File f) => f.uri.pathSegments.last)
            .where((String name) => name.startsWith('drift_schema_v') && name.endsWith('.json'))
            .toList()
          ..sort();

    expect(snapshots, hasLength(kSchemaVersion));
    expect(
      snapshots,
      List<String>.generate(kSchemaVersion, (int i) => 'drift_schema_v${i + 1}.json'),
      reason: 'every version from 1 to $kSchemaVersion has its snapshot, with no gap',
    );
  });
}
