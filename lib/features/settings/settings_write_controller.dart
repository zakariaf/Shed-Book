// lib/features/settings/settings_write_controller.dart
//
// One method per settable thing, each a `guard()`ed call into
// `SettingsRepository`. **No verb is added to the repository here** — N12-T02
// wrote them all, and a section that needed a new one would be a section that
// has reached past the frame.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/write_action.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/domain/units/weight_unit.dart';

/// `final` because [WriteController] is `base`.
final class SettingsWriteController extends WriteController {
  Future<void> setWeightUnit(WeightUnit unit) =>
      guard(() => ref.read(settingsRepositoryProvider).setWeightUnit(unit));

  Future<void> setPalette(String paletteKey) =>
      guard(() => ref.read(settingsRepositoryProvider).setPalette(paletteKey));

  Future<void> setHighContrast({required bool on}) =>
      guard(() => ref.read(settingsRepositoryProvider).setHighContrast(on: on));

  /// R40 — it moves the slab, `INDEX` and the keypad's bottom row, and nothing
  /// else. The spine, the margin cell and the record column do not mirror.
  Future<void> setLeftHanded({required bool on}) =>
      guard(() => ref.read(settingsRepositoryProvider).setLeftHanded(on: on));

  Future<void> setWakelockEnabled({required bool on}) =>
      guard(() => ref.read(settingsRepositoryProvider).setWakelockEnabled(on: on));

  Future<void> setTurnOutThresholdHours(int hours) =>
      guard(() => ref.read(settingsRepositoryProvider).setTurnOutThresholdHours(hours));

  Future<void> setCurrentSeason(SeasonId? season) =>
      guard(() => ref.read(settingsRepositoryProvider).setCurrentSeason(season));
}

/// `.autoDispose`, always, for a write controller (`CONVENTIONS §3.4`).
final AutoDisposeNotifierProvider<SettingsWriteController, WriteState>
settingsWriteControllerProvider = NotifierProvider.autoDispose<SettingsWriteController, WriteState>(
  SettingsWriteController.new,
);
