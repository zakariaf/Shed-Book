// test/data/export_share_test.dart — assembling the artefacts and handing them
// to the sheet, driven through the controller rather than through the button.
//
// **WHY NOT A WIDGET TEST.** Assembling an artefact writes three real files, and
// `writeAsBytes` is real I/O that the fake-async zone `testWidgets` installs does
// not advance: the tap fires, the chain suspends on the first file write,
// `pumpAndSettle` returns having settled nothing, and the assertion reads an
// empty share list **with no exception anywhere**. Wrapping the tap in
// `runAsync` deadlocks instead, which is worse — it hangs the run rather than
// failing it. Measured, three times.
//
// So the widget test asserts what the widget does — it renders, it is honest,
// nothing monetization-shaped appears — and this file asserts what the write
// path does. Two files, two failure modes, and neither pretends to cover the
// other. The tap itself is covered on a real device by N33's journey, which is
// also the only place a share sheet actually opens.
library;

import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/data/share_service.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/export/export_controller.dart';
import 'package:shed_book/features/export/export_write_controller.dart';

import '../support/fake_share_service.dart';
import '../support/harness.dart';
import '../support/seeds.dart';

const Rect _origin = Rect.fromLTWH(0, 0, 1, 1);

Future<void> _share(ProviderContainer c) async {
  final ExportCounts counts = await c.read(exportCountsProvider.future);
  await c
      .read(exportWriteControllerProvider.notifier)
      .shareCsvs(
        season: await c.read(currentSeasonProvider.future),
        seasonYear: counts.seasonYear,
        vocabLabels: const <String, String>{},
        origin: _origin,
        localZoneLabel: 'UTC+00:00',
        appVersion: '1.0.0',
      );
}

Future<AppSetting> _settings(AppDatabase db) =>
    (db.select(db.appSettings)..where(($AppSettingsTable t) => t.id.equals(1))).getSingle();

void main() {
  late AppDatabase db;
  late FakeShareService share;
  late ProviderContainer c;

  Future<void> seedOneLamb() async {
    await seedSeason(db);
    final EweId ewe = await seedEwe(db, tag: '412');
    final LambingId lambing = await seedLambing(db, ewe);
    await seedLamb(db, lambing, ewe);
  }

  setUp(() {
    db = testDatabase();
    share = FakeShareService();
    c = shedContainer(db, share: share);
  });

  test('one sheet carries all three CSVs, named from the year', () async {
    await seedOneLamb();
    await _share(c);

    // ONE SHEET, THREE FILES — not three sheets. Three separate share sheets is
    // three chances to send the wrong one.
    expect(share.shared, hasLength(1));

    final List<String> names = share.shared.single.fileNames;
    expect(names, hasLength(3));
    expect(
      names,
      containsAll(<String>[
        'shed-book-2026-lambs.csv',
        'shed-book-2026-ewes.csv',
        'shed-book-2026-treatments.csv',
      ]),
    );

    // NAMED FROM `seasons.year` AND NEVER FROM `seasons.label` (`09 §1.1`). A
    // shepherd who renamed the season to "Home flock" would otherwise be handed
    // a file with a space in its name on a share sheet.
    for (final String name in names) {
      expect(name, isNot(contains(' ')));
    }
  });

  test('the files exist on disk before the sheet is opened', () async {
    await seedOneLamb();
    await _share(c);

    // `FakeShareService`'s own tripwire refuses a path that does not exist, so
    // reaching this line already proves the ordering — the explicit check is
    // here so a future relaxation of the fake does not silently take the
    // property with it.
    for (final String p in share.shared.single.paths) {
      expect(File(p).existsSync(), isTrue, reason: p);
      expect(File(p).lengthSync(), isPositive, reason: 'an empty artefact is not an artefact');
    }
  });

  test('a completed share stamps last_exported_at', () async {
    await seedOneLamb();
    expect((await _settings(db)).lastExportedAt, isNull);

    await _share(c);

    expect((await _settings(db)).lastExportedAt, isNotNull);
  });

  test('a dismissed share stamps nothing', () async {
    // `09 §8.3`. Backing out means nothing left the phone, so stamping would
    // silence the end-of-day prompt for somebody who has not exported — the one
    // failure mode that turns a safety feature into a liability.
    db = testDatabase();
    share = FakeShareService(outcome: ShareOutcome.dismissed);
    c = shedContainer(db, share: share);
    await seedOneLamb();

    await _share(c);

    expect(share.shared, hasLength(1), reason: 'the attempt happened');
    expect((await _settings(db)).lastExportedAt, isNull, reason: 'the share did not');
  });

  test('an unavailable share DOES stamp, because the honest reading is that it happened', () async {
    // The third state, and the reason `ShareOutcome` is not a `bool`. Android
    // frequently cannot tell us; nagging somebody who has just exported is the
    // worse error of the two.
    db = testDatabase();
    share = FakeShareService(outcome: ShareOutcome.unknown);
    c = shedContainer(db, share: share);
    await seedOneLamb();

    await _share(c);

    expect((await _settings(db)).lastExportedAt, isNotNull);
  });

  test('a second share while the first is running is refused, not queued', () async {
    // `guard()` is the double-tap defence, and on this screen it matters more
    // than on the shed screens: assembling a 400-ewe CSV twice writes the same
    // file twice and opens two share sheets, the second over one the shepherd is
    // already reading.
    await seedOneLamb();

    await Future.wait<void>(<Future<void>>[_share(c), _share(c)]);

    expect(share.shared, hasLength(1), reason: 'one of the two was refused');
  });
}
