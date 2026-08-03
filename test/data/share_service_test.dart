// test/data/share_service_test.dart — the seam, and the three-way result the
// end-of-day banner depends on.
//
// The real gateway reaches `SharePlus.instance`, which has no platform channel
// in a unit test, so what is testable here is the CONTRACT rather than the call:
// the three outcomes are distinct, the fake honours the same signature, and the
// two tripwires fire. `08 §5`'s own note applies — the plugin call itself is
// covered by N33's integration journey on a real device, which is the only place
// a share sheet actually opens.
library;

import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/data/share_service.dart';

import '../support/fake_share_service.dart';

const Rect _origin = Rect.fromLTWH(0, 0, 1, 1);

void main() {
  test('the outcome is three-way, and dismissed is not merely "not completed"', () {
    // `09 §8.3` writes `last_exported_at` on completed AND on unknown, and never
    // on dismissed. Collapsing *unavailable* into either one makes the app's one
    // safety nag either useless or a liar — a `bool` here is the defect.
    expect(ShareOutcome.values, hasLength(3));
    expect(ShareOutcome.values.toSet(), <ShareOutcome>{
      ShareOutcome.completed,
      ShareOutcome.dismissed,
      ShareOutcome.unknown,
    });
  });

  test('a mismatched path and name list is refused, in release as well as debug', () async {
    // A `throw`, not an `assert`: in release a mismatch ships a file called
    // `ewes.csv` containing lambs, to somebody else's laptop.
    final FakeShareService fake = FakeShareService(requireFilesExist: false);
    await expectLater(
      fake.shareFiles(
        paths: <String>['/tmp/a.csv', '/tmp/b.csv'],
        fileNames: <String>['a.csv'],
        origin: _origin,
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(fake.shared, isEmpty, reason: 'nothing was shared');
  });

  test('the fake refuses a path that does not exist', () async {
    // The tripwire `12 §4.2` names. Every artefact is written to a temp file
    // first and shared from there; a caller that shares before it writes hands
    // the OS a dead path and the sheet opens on nothing.
    final FakeShareService fake = FakeShareService();
    await expectLater(
      fake.shareFiles(
        paths: <String>['/definitely/not/here/lambs.csv'],
        fileNames: <String>['lambs.csv'],
        origin: _origin,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('the fake records what was shared, with its names and its subject', () async {
    final FakeShareService fake = FakeShareService(requireFilesExist: false);

    final ShareOutcome outcome = await fake.shareFiles(
      paths: <String>['/tmp/lambs.csv'],
      fileNames: <String>['shed-book-2026-lambs.csv'],
      origin: _origin,
      subject: 'Shed Book 2026',
    );

    expect(outcome, ShareOutcome.completed);
    expect(fake.shared.single.fileNames, <String>['shed-book-2026-lambs.csv']);
    expect(fake.shared.single.subject, 'Shed Book 2026');
  });

  test('a dismissed share is reported as dismissed and not as a failure', () async {
    // Backing out of the sheet is not an error and must never be rendered as
    // one. It is also the one outcome that stamps nothing.
    final FakeShareService fake = FakeShareService(
      outcome: ShareOutcome.dismissed,
      requireFilesExist: false,
    );

    expect(
      await fake.shareFiles(
        paths: <String>['/tmp/a.csv'],
        fileNames: <String>['a.csv'],
        origin: _origin,
      ),
      ShareOutcome.dismissed,
    );
    expect(fake.shared, hasLength(1), reason: 'the attempt happened; the share did not complete');
  });

  test('the fake is a ShareService, so a signature change is a compile error', () {
    // `12 §4.2`'s whole reason for `implements` over `extends`, and the reason
    // `ShareService` is an `interface class`: a fake that merely looked like the
    // gateway would keep compiling after the gateway grew a parameter, and the
    // divergence would be silent.
    expect(FakeShareService(), isA<ShareService>());
  });
}
