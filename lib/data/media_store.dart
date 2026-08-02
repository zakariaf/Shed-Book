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
import 'package:shed_book/data/media_limits.dart';

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
    try {
      final RandomAccessFile handle = await part.open(mode: FileMode.write);
      try {
        await handle.writeFrom(bytes);
        await handle.flush();
      } finally {
        await handle.close();
      }
      return await part.rename(target.path);
    } on Object {
      // BEST-EFFORT CLEANUP, AND IT NEVER THROWS A SECOND EXCEPTION. A .part
      // file left behind after a full disk is a file that occupies the space
      // the shepherd is trying to free, and it is invisible to them. Swallowing
      // the delete's own failure is deliberate: the caller needs the ORIGINAL
      // error, and a cleanup that masked it would report the wrong problem.
      _deleteQuietly(part);
      rethrow;
    }
  }

  /// The second hop: downscale, re-encode, strip EXIF, land the bytes.
  ///
  /// **A NEW MEMBER.** Neither `04 §4.4` nor `08 §3.3` names it — both print the
  /// compress call inline at the call site — and it is flagged in the pull
  /// request rather than added silently, on `08 §1.3`'s precedent for
  /// `RestoreService.restoreFrom`. Inlining it would put the one
  /// `flutter_image_compress` import in a feature file, which the layer rules
  /// forbid and `layer.plugin_flutter_image_compress` catches.
  ///
  /// [compressor] exists because `compressAndGetFile` is a NATIVE call with no
  /// Dart fallback: it throws under `flutter_test`. The test drives this seam
  /// and asserts the ARGUMENTS; the output's real dimensions and byte count are
  /// a DEVICE measurement, and pretending otherwise in a unit test would be
  /// asserting a claim the test cannot see.
  Future<File> writePhoto({
    required String sourcePath,
    required String relativePath,
    required int sourceWidth,
    required int sourceHeight,
    required Future<List<int>?> Function({
      required String source,
      required String target,
      required int minWidth,
      required int minHeight,
      required int quality,
      required bool keepExif,
    })
    compressor,
  }) async {
    final File target = await resolve(relativePath);
    await target.parent.create(recursive: true);

    // THE LONGEST EDGE, DERIVED FROM THE ASPECT RATIO. The plugin's minWidth and
    // minHeight are a bounding box rather than a target, and passing
    // kPhotoLongestEdgePx to both would cap the SHORTEST edge at 2048 — which
    // for a 4032 x 3024 frame leaves the longest at 2731 and quietly breaks
    // decision #40. The derivation is safe under either reading of the
    // parameters, which is why it is written now rather than after the open
    // verification item in 04 §4.4 closes.
    final bool landscape = sourceWidth >= sourceHeight;
    final int minWidth = landscape
        ? kPhotoLongestEdgePx
        : (kPhotoLongestEdgePx * sourceWidth / sourceHeight).round();
    final int minHeight = landscape
        ? (kPhotoLongestEdgePx * sourceHeight / sourceWidth).round()
        : kPhotoLongestEdgePx;

    // THE COMPRESSOR WRITES THE .part ITSELF, so its failure has to be cleaned
    // up HERE — writeAtomically's own cleanup covers only the bytes IT wrote,
    // and by the time this method calls it the compressor has already been and
    // gone. Found by making the cleanup test non-vacuous: with a compressor that
    // threw before creating anything, the case passed against a MediaStore with
    // no cleanup on this path at all.
    final List<int>? bytes;
    try {
      bytes = await compressor(
        source: sourcePath,
        target: '${target.path}.part',
        minWidth: minWidth,
        minHeight: minHeight,
        quality: kPhotoJpegQuality,
        // THE DEFAULT, WRITTEN ANYWAY so the intent is visible. EXIF carries
        // GPS, and a photo of a lambing is a photo of where the shepherd lives.
        keepExif: false,
      );
    } on Object {
      _deleteQuietly(File('${target.path}.part'));
      rethrow;
    }

    if (bytes == null) {
      _deleteQuietly(File('${target.path}.part'));
      throw const FileSystemException('the photo could not be re-encoded');
    }
    return writeAtomically(relativePath, bytes);
  }
}

/// Best-effort, and **it never throws a second exception**. A `.part` left
/// behind after a full disk occupies the space the shepherd is trying to free
/// and is invisible to them — but the caller needs the ORIGINAL error, and a
/// cleanup that masked it would report the wrong problem.
void _deleteQuietly(File f) {
  try {
    if (f.existsSync()) {
      f.deleteSync();
    }
  } on Object {
    // Nothing to do and nothing to say.
  }
}
