// test/support/fake_share_service.dart — `12 §4.2`'s fake for the one seam
// anything leaves the phone by.
//
// **`implements`, NEVER `extends`.** `12 §4.1`: a fake is a real implementation.
// Extending would inherit the real `shareFiles`, and a fake that accidentally
// calls `SharePlus.instance` in a widget test fails on a missing platform
// channel — which reads as a flaky test rather than as the mistake it is.
//
// It carries two tripwires, and both are failures the real gateway cannot have
// but a caller can:
//
//   * **a share of a path that does not exist.** The artefact is written to a
//     temp file first and shared from there; a caller that shares before it
//     writes hands the OS a dead path, and the sheet opens on nothing.
//   * **any call passing bytes rather than a path.** Structurally impossible
//     through this signature, so the tripwire is on the *shape* rather than on
//     the call: `fromData` in a name is a caller reaching for the banned API.
library;

import 'dart:io';
import 'dart:ui' show Rect;

import 'package:shed_book/data/share_service.dart';

/// One recorded share.
typedef FakeShared = ({List<String> paths, List<String> fileNames, String? subject, Rect origin});

final class FakeShareService implements ShareService {
  FakeShareService({this.outcome = ShareOutcome.completed, this.requireFilesExist = true});

  /// What the OS "said". Default [ShareOutcome.completed]; set
  /// [ShareOutcome.dismissed] to exercise the branch where **nothing is
  /// stamped**, which is the one the end-of-day banner depends on.
  ShareOutcome outcome;

  /// Off only for a test that is deliberately checking the naming contract with
  /// paths it never wrote. It defaults to ON because a dead path is the failure
  /// this fake exists to catch.
  final bool requireFilesExist;

  final List<FakeShared> shared = <FakeShared>[];

  @override
  Future<ShareOutcome> shareFiles({
    required List<String> paths,
    required List<String> fileNames,
    required Rect origin,
    String? subject,
  }) async {
    if (paths.length != fileNames.length) {
      throw ArgumentError(
        'shareFiles: ${paths.length} paths and ${fileNames.length} names — '
        'every file is named or none is',
      );
    }
    for (final String name in fileNames) {
      if (name.contains('fromData')) {
        throw StateError('a share passed bytes rather than a path — decision #80');
      }
    }
    if (requireFilesExist) {
      for (final String p in paths) {
        if (!File(p).existsSync()) {
          throw StateError('shared a path that does not exist: $p');
        }
      }
    }

    shared.add((paths: paths, fileNames: fileNames, subject: subject, origin: origin));
    return outcome;
  }
}
