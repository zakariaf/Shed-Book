// lib/data/media_store.dart
//
// THE ONLY TYPE THAT KNOWS WHERE MEDIA BYTES LIVE. lib/features/** never
// constructs a File, and this is one of exactly two files permitted to call
// getApplicationSupportDirectory() — the other is connection.dart.
//
// ---------------------------------------------------------------------------
// package:path IS NOT IMPORTED, AND THAT IS A DECISION (gotcha 1)
// ---------------------------------------------------------------------------
//
// 04 §4.3's printed body imports it. `path` is not a direct dependency:
// pubspec.yaml carries path_provider, not path, and G2's allowlist does not
// list it — so the import trips depend_on_referenced_packages and turns the
// gate red.
//
// Adding it is a DECISION, not an edit: it means a line in decision-record §5,
// which is the only source of a version number in this project, and a line in
// tool/policy_allowlist.txt, which CLAUDE.md names as a thing you never do to
// make a build green.
//
// It is not needed. `newRelativePath` is three string joins, and `resolve`
// validates against one RegExp that is the Dart transcription of the three
// CHECKs. A string matching `^\d{4}/\d{2}/[^/]+\.[^/]+$` CANNOT carry a `..`
// segment: `..` is two characters and `[^/]+\.[^/]+` needs at least three. That
// is a STRONGER containment check than a path-library `isWithin`, and it is the
// same rule the database holds.
//
// N23-T03's MediaSweeper inherits this answer.
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';

/// The Dart transcription of `media_assets`' three CHECKs (`03 §5.11`, R62):
///
/// ```sql
/// CHECK (relative_path NOT LIKE '/%')                              -- not absolute
/// CHECK (relative_path GLOB '[0-9][0-9][0-9][0-9]/[0-9][0-9]/*.*') -- YYYY/MM/<name>.<ext>
/// CHECK (relative_path NOT GLOB '*/*/*/*')                         -- exactly two separators
/// ```
///
/// **All three are load-bearing and none is redundant.** `GLOB`'s `*` matches
/// `/` in SQLite, so the second alone does not stop `2026/03/../../x.jpg`; the
/// third does, because two separators are already spent on `YYYY/MM/` and there
/// is no further segment to traverse with. If a simplification pass proposes
/// folding them into one, refuse it and say why.
final RegExp _shape = RegExp(r'^\d{4}/\d{2}/[^/]+\.[^/]+$');

final class MediaStore {
  /// The optional resolver exists for `test/data/media_store_test.dart`, which
  /// runs under `flutter_test` where the `path_provider` method channel does not
  /// answer. **Production passes nothing.** It is a departure from `04 §4.3`'s
  /// printed class and is flagged in the pull request.
  MediaStore({Future<Directory> Function()? supportDirectory})
    : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _supportDirectory;

  /// Resolved fresh every run and **deliberately never persisted anywhere**: on
  /// iOS the container path contains a UUID that changes between installs and
  /// across some OS upgrades, so a stored absolute path is a path that stops
  /// resolving on somebody else's phone, months later, with their photos behind
  /// it.
  Future<Directory> root() async {
    final Directory support = await _supportDirectory();
    return Directory('${support.path}/media');
  }

  /// The **only** string that ever reaches the database. Always
  /// POSIX-separated: `2026/03/019524f7-8a1c-7b3e-9f04-2c9a1e7d55b0.jpg`.
  ///
  /// **The shard is the LOCAL civil month, not the UTC one.** `YYYY/MM` is a
  /// human-legible directory rather than an instant: a photo taken at 00:30 BST
  /// on 1 April 2026 is `2026-03-31T23:30Z`, it belongs in `2026/04`, and a UTC
  /// shard files it under `2026/03` — silently disagreeing with the shepherd's
  /// own calendar.
  ///
  /// `newUid()` is the one `package:uuid` call site in the app (R15). **v7 is
  /// the point**: its time-ordered prefix means a directory listing sorts
  /// chronologically for free.
  String newRelativePath(String extension) {
    final DateTime local = appNow().local;
    final String year = local.year.toString().padLeft(4, '0');
    final String month = local.month.toString().padLeft(2, '0');
    return '$year/$month/${newUid()}.$extension';
  }

  /// Defence in depth. The three CHECKs make an escaping path unstorable, but a
  /// resolver that *can* leave its root is not a resolver.
  Future<File> resolve(String relativePath) async {
    if (!_shape.hasMatch(relativePath)) {
      throw ArgumentError.value(relativePath, 'relativePath', 'not a media-store relative path');
    }
    return File('${(await root()).path}/$relativePath');
  }

  /// Write to `<target>.part`, flush, then rename.
  ///
  /// **Rename within one filesystem is atomic**, so a reader never sees a
  /// half-written photo — which at 03:20 is the difference between a picture of
  /// a malpresentation and a grey rectangle nobody can explain.
  Future<File> writeAtomically(String relativePath, List<int> bytes) async {
    final File target = await resolve(relativePath);
    await target.parent.create(recursive: true);

    final File part = File('${target.path}.part');
    final RandomAccessFile handle = await part.open(mode: FileMode.write);
    try {
      await handle.writeFrom(bytes);
      await handle.flush();
    } finally {
      await handle.close();
    }

    return part.rename(target.path);
  }
}
