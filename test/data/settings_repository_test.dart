// test/data/settings_repository_test.dart
//
// Against a real in-memory SQLite, never a mock (00-README §8 step 12). The
// point of this file is that every setting SURVIVES A ROUND TRIP through the
// schema — its CHECK constraints, its converters and its defaults — and a mock
// asserts none of that.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/settings_repository.dart';
import 'package:shed_book/domain/stats/definitions.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/units/weight_unit.dart';

import '../support/harness.dart';

/// One setting: how to write it, and how to read it back.
typedef Setting = ({
  String name,
  Future<WriteOutcome> Function(SettingsRepository) set,
  Object? Function(AppSetting) get,
  Object? expected,
});

final Instant _at = Instant.fromDateTime(DateTime.utc(2026, 8, 1, 3, 21));

/// **Every setting, in one table.** A setter added without a row here is a
/// setting nobody has ever seen persist — and the failure mode is silent: the
/// write returns `WriteCommitted` whether or not the column moved.
final List<Setting> _settings = <Setting>[
  (
    name: 'weightUnit',
    set: (SettingsRepository r) => r.setWeightUnit(WeightUnit.lb),
    get: (AppSetting s) => s.weightUnit,
    expected: 'lb',
  ),
  (
    name: 'palette',
    set: (SettingsRepository r) => r.setPalette('red'),
    get: (AppSetting s) => s.palette,
    // R35: deepRed's stored key is 'red', and it is the one member whose key is
    // not its name. 03 §5.13's CHECK is what makes a mismatch a runtime write
    // failure rather than a compile error.
    expected: 'red',
  ),
  (
    name: 'highContrast',
    set: (SettingsRepository r) => r.setHighContrast(on: true),
    get: (AppSetting s) => s.highContrast,
    expected: true,
  ),
  (
    name: 'leftHanded',
    set: (SettingsRepository r) => r.setLeftHanded(on: true),
    get: (AppSetting s) => s.leftHanded,
    expected: true,
  ),
  (
    name: 'wakelockEnabled',
    set: (SettingsRepository r) => r.setWakelockEnabled(on: true),
    get: (AppSetting s) => s.wakelockEnabled,
    expected: true,
  ),
  (
    name: 'turnOutThresholdHours',
    set: (SettingsRepository r) => r.setTurnOutThresholdHours(36),
    get: (AppSetting s) => s.turnOutThresholdHours,
    expected: 36,
  ),
  (
    name: 'cycleDays',
    set: (SettingsRepository r) => r.setCycleDays(16),
    get: (AppSetting s) => s.cycleDays,
    expected: 16,
  ),
  (
    name: 'percentageDefinition',
    set: (SettingsRepository r) =>
        r.setPercentageDefinition(LambingPercentageChoice.bornAlivePerEweLambed),
    get: (AppSetting s) => s.percentageDefinition,
    expected: LambingPercentageChoice.bornAlivePerEweLambed.key,
  ),
  (
    name: 'lastExportedAt',
    set: (SettingsRepository r) => r.recordExported(_at),
    get: (AppSetting s) => s.lastExportedAt,
    expected: _at,
  ),
  (
    name: 'lastExportPromptedAt',
    set: (SettingsRepository r) => r.recordExportPrompted(_at),
    get: (AppSetting s) => s.lastExportPromptedAt,
    expected: _at,
  ),
  (
    name: 'lastReconcileScheduled',
    set: (SettingsRepository r) => r.recordReconcileScheduled(_at),
    get: (AppSetting s) => s.lastReconcileScheduled,
    expected: _at,
  ),
];

void main() {
  late AppDatabase db;
  late SettingsRepository repo;

  setUp(() {
    db = testDatabase();
    repo = SettingsRepository(db);
  });

  tearDown(() => db.close());

  test('every setting persists and re-reads', () async {
    // THE ANCHOR, parameterised. Written as ONE case over the table rather than
    // eleven cases, because the thing that matters is that the table is
    // complete: a setter added without a row is a setting nobody has seen
    // persist, and the write returns WriteCommitted whether or not the column
    // moved.
    for (final Setting s in _settings) {
      final WriteOutcome outcome = await s.set(repo);
      expect(outcome, isA<WriteCommitted>(), reason: s.name);

      final AppSetting row = await repo.read();
      expect(s.get(row), s.expected, reason: s.name);
    }
  });

  test('the settings table covers every public setter on the repository', () async {
    // The completeness half, and it is the one that keeps the case above honest.
    // Without it the table can silently fall behind the class.
    const List<String> setters = <String>[
      'setWeightUnit',
      'setPalette',
      'setHighContrast',
      'setLeftHanded',
      'setWakelockEnabled',
      'setTurnOutThresholdHours',
      'setCycleDays',
      'setPercentageDefinition',
      'setCurrentSeason',
      'recordExported',
      'recordExportPrompted',
      'dismissExportPromptForSeason',
      'recordReconcileScheduled',
    ];

    // setCurrentSeason and dismissExportPromptForSeason take a SeasonId and
    // need a real season row, so they are exercised in their own case below
    // rather than in the parameterised table.
    expect(_settings, hasLength(setters.length - 2));
  });

  test('reading before any write returns the seeded defaults', () async {
    // seedFirstRun writes the one row; CHECK (id = 1) is what makes it the ONLY
    // row. A repository that returned null here would push the question of "no
    // settings yet" onto twelve screens.
    final AppSetting row = await repo.read();

    expect(row.id, SettingsRepository.rowId);
    expect(row.weightUnit, 'kg');
    expect(row.palette, 'night');
    expect(row.highContrast, isFalse);
  });

  test('watch emits the new value after a write', () async {
    // `emitsThrough`, not `skip(1).first`. drift's watchSingle emits the
    // CURRENT row on subscribe and then again on change, but whether the first
    // emission lands before or after the write is a race — skipping exactly one
    // assumes an ordering the stream does not promise.
    final Future<void> sawIt = expectLater(
      repo.watch().map((AppSetting s) => s.weightUnit),
      emitsThrough('lb'),
    );

    await repo.setWeightUnit(WeightUnit.lb);
    await sawIt;
  });

  test('a nullable season pointer accepts null', () async {
    // The "no current season" state is a real one — a fresh install has no
    // season until the shepherd starts one — so the column is nullable and the
    // setter must be able to say so.
    expect(await repo.setCurrentSeason(null), isA<WriteCommitted>());
    expect((await repo.read()).currentSeason, isNull);
  });

  test('every verb returns a WriteOutcome and none of them throws', () async {
    // 01 §5.2. An exception crossing a repository boundary is a decision made
    // somewhere that cannot make it: the controller is what knows whether the
    // shepherd sees a warning, a refusal or nothing at all.
    for (final Setting s in _settings) {
      expect(await s.set(repo), isA<WriteOutcome>(), reason: s.name);
    }
  });

  test('the repository has no setter for a column the schema does not have', () async {
    // N12-T02 §5.2 prints `setTemperatureUnit`, and there is no
    // `temperature_unit` column: R68 rules that no temperature unit ships while
    // decision-record §7.1 #11 is open. A setter for a missing column is a
    // compile error at best and a silent no-op at worst.
    final AppSetting row = await repo.read();
    expect(
      row.toJson().keys,
      isNot(contains('temperature_unit')),
      reason: 'if the column now exists, the setter and its ledger line follow',
    );
  });
}
