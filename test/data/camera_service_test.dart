// test/data/camera_service_test.dart
//
// HALF OF DECISION #40 IS NOT UNIT-TESTABLE AND MUST NOT BE PRETENDED INTO A
// UNIT TEST. `compressAndGetFile` is a native call with no Dart fallback: it
// throws MissingPluginException under flutter_test. So the assertion splits
// honestly:
//
//   * UNIT (here, blocking): the compressor is invoked through a narrow injected
//     seam, and this file asserts the ARGUMENTS — keepExif: false, the quality,
//     and the derived (minWidth, minHeight) pair — plus that the bytes handed to
//     writeAtomically carry no APP1 Exif segment.
//   * DEVICE (before shipping, not blocking): open the real output and assert
//     max(width, height) <= kPhotoLongestEdgePx and bytes <= kPhotoMaxBytes.
//     That is the measurement 04 §4.4 and 08 §3.3 both demand and neither has
//     taken; docs/perf/measurements.md is where it lands.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/data/media_limits.dart';
import 'package:shed_book/data/media_store.dart';

/// Walks a JPEG's segment markers looking for an APP1 `Exif\0\0` header.
///
/// **In THIS file, not in test/support/.** `12 §5.3` closes the support folder,
/// and a walker used by one test is a private top-level function in the file
/// that uses it.
bool _hasExifApp1(List<int> bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
    return false;
  }
  int i = 2;
  while (i + 3 < bytes.length) {
    if (bytes[i] != 0xFF) {
      return false;
    }
    final int marker = bytes[i + 1];
    if (marker == 0xDA) {
      return false; // start of scan — no more headers
    }
    final int length = (bytes[i + 2] << 8) | bytes[i + 3];
    if (marker == 0xE1 &&
        i + 9 < bytes.length &&
        bytes[i + 4] == 0x45 && // E
        bytes[i + 5] == 0x78 && // x
        bytes[i + 6] == 0x69 && // i
        bytes[i + 7] == 0x66 && // f
        bytes[i + 8] == 0x00 &&
        bytes[i + 9] == 0x00) {
      return true;
    }
    i += 2 + length;
  }
  return false;
}

/// A minimal JPEG carrying one APP1 Exif segment, so the walker above can be
/// proved non-vacuous in the same file that relies on it.
List<int> _jpegWithExif() => <int>[
  0xFF, 0xD8, // SOI
  0xFF, 0xE1, 0x00, 0x0A, // APP1, length 10
  0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // "Exif\0\0"
  0x00, 0x00,
  0xFF, 0xDA, // SOS
];

/// The same shape without the APP1 segment.
List<int> _jpegWithoutExif() => <int>[0xFF, 0xD8, 0xFF, 0xDA, 0x00, 0x00];

void main() {
  test('the EXIF walker is not vacuous', () {
    // ASSERTED FIRST, and it is the assertion that makes every other one below
    // mean something: a walker that always returned false would pass the anchor
    // and prove nothing.
    expect(_hasExifApp1(_jpegWithExif()), isTrue);
    expect(_hasExifApp1(_jpegWithoutExif()), isFalse);
  });

  test('a captured photo is resized, re-encoded and carries no EXIF', () async {
    // THE ANCHOR. A 4032 x 3024 source — a real phone frame, landscape.
    final Directory support = Directory.systemTemp.createTempSync('media');
    addTearDown(() => support.deleteSync(recursive: true));

    final MediaStore store = MediaStore(supportDirectory: () async => support);

    late int seenMinWidth;
    late int seenMinHeight;
    late int seenQuality;
    late bool seenKeepExif;

    final File written = await store.writePhoto(
      sourcePath: '/tmp/source.jpg',
      relativePath: store.newRelativePath('jpg'),
      sourceWidth: 4032,
      sourceHeight: 3024,
      compressor:
          ({
            required String source,
            required String target,
            required int minWidth,
            required int minHeight,
            required int quality,
            required bool keepExif,
          }) async {
            seenMinWidth = minWidth;
            seenMinHeight = minHeight;
            seenQuality = quality;
            seenKeepExif = keepExif;
            return _jpegWithoutExif();
          },
    );

    // KEEP-EXIF IS WRITTEN EXPLICITLY even though it is the default, so the
    // intent is visible: EXIF carries GPS, and a photo of a lambing is a photo
    // of where the shepherd lives.
    expect(seenKeepExif, isFalse);
    expect(seenQuality, kPhotoJpegQuality);

    // THE PAIR IS DERIVED FROM THE ASPECT RATIO so the LONGEST edge lands at
    // the cap. Passing kPhotoLongestEdgePx to both would cap the SHORTEST edge
    // — for this frame that leaves the longest at 2731 and quietly breaks
    // decision #40.
    expect(seenMinWidth, kPhotoLongestEdgePx);
    expect(seenMinHeight, (kPhotoLongestEdgePx * 3024 / 4032).round());

    expect(_hasExifApp1(await written.readAsBytes()), isFalse);
  });

  test('a portrait source derives the mirrored pair', () async {
    // The mirror, because a derivation that only works one way round is a
    // coincidence — and portrait is how a phone is held with a lamb in the
    // other hand.
    final Directory support = Directory.systemTemp.createTempSync('media');
    addTearDown(() => support.deleteSync(recursive: true));

    final MediaStore store = MediaStore(supportDirectory: () async => support);
    late int seenMinWidth;
    late int seenMinHeight;

    await store.writePhoto(
      sourcePath: '/tmp/source.jpg',
      relativePath: store.newRelativePath('jpg'),
      sourceWidth: 3024,
      sourceHeight: 4032,
      compressor:
          ({
            required String source,
            required String target,
            required int minWidth,
            required int minHeight,
            required int quality,
            required bool keepExif,
          }) async {
            seenMinWidth = minWidth;
            seenMinHeight = minHeight;
            return _jpegWithoutExif();
          },
    );

    expect(seenMinHeight, kPhotoLongestEdgePx);
    expect(seenMinWidth, (kPhotoLongestEdgePx * 3024 / 4032).round());
  });

  test('a square source lands both edges at the cap', () async {
    final Directory support = Directory.systemTemp.createTempSync('media');
    addTearDown(() => support.deleteSync(recursive: true));

    final MediaStore store = MediaStore(supportDirectory: () async => support);
    late int w;
    late int h;

    await store.writePhoto(
      sourcePath: '/tmp/source.jpg',
      relativePath: store.newRelativePath('jpg'),
      sourceWidth: 2000,
      sourceHeight: 2000,
      compressor:
          ({
            required String source,
            required String target,
            required int minWidth,
            required int minHeight,
            required int quality,
            required bool keepExif,
          }) async {
            w = minWidth;
            h = minHeight;
            return _jpegWithoutExif();
          },
    );

    expect(w, kPhotoLongestEdgePx);
    expect(h, kPhotoLongestEdgePx);
  });

  test('a compressor that returns nothing is a failure, never a silent empty file', () async {
    // An empty photo attached to a lambing is worse than no photo: it looks
    // like the shepherd took one and it shows nothing.
    final Directory support = Directory.systemTemp.createTempSync('media');
    addTearDown(() => support.deleteSync(recursive: true));

    final MediaStore store = MediaStore(supportDirectory: () async => support);

    await expectLater(
      () => store.writePhoto(
        sourcePath: '/tmp/source.jpg',
        relativePath: store.newRelativePath('jpg'),
        sourceWidth: 4032,
        sourceHeight: 3024,
        compressor:
            ({
              required String source,
              required String target,
              required int minWidth,
              required int minHeight,
              required int quality,
              required bool keepExif,
            }) async => null,
      ),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('CameraService is the one image_picker call site', () {
    // R9, R47, layer.plugin_image_picker. Asserted here as well as in the gate,
    // in the tier a developer runs first.
    const String needle =
        'package:image_' // split: this file is scanned
        'picker/';

    final List<File> importers = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .where((File f) => f.readAsStringSync().contains(needle))
        .toList();

    expect(importers.map((File f) => f.path), <String>['lib/data/camera_service.dart']);
  });
}
