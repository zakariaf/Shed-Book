// lib/features/lambing/photo_controller.dart
//
// **THE PHOTO CHAIN, WHICH HAD NO CALLER AT ANY LINK.**
//
// `CameraService.pick`, `MediaStore.newRelativePath`, `MediaStore.writePhoto`
// and `NoteRepository.attachPhoto` all landed at N15 with their own tests and
// their own fakes, and nothing in `lib/` joined them up. A shepherd could not
// take a photo of a lambing.
//
// **FOUR STEPS, AND EACH ONE CAN STOP WITHOUT LOSING ANYTHING.** Backing out of
// the picker writes nothing; a compressor that fails leaves no `.part` behind
// (`MediaStore` cleans up after it, which is measured); and the row is written
// last, so a file on disk with no row is what the orphan sweep moves to
// `.trash/` rather than a record pointing at nothing.
library;

import 'dart:io';
import 'dart:ui';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/write_outcome.dart';
import 'package:shed_book/data/camera_service.dart';
import 'package:shed_book/data/media_store.dart';
import 'package:shed_book/data/note_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/domain/ids.dart';

/// What the attempt ended as. **Backing out is not a failure** — it is a
/// decision, and rendering it as an error tells somebody they did something
/// wrong when they did not.
sealed class PhotoAttempt {
  const PhotoAttempt();
}

final class PhotoAbandoned extends PhotoAttempt {
  const PhotoAbandoned();
}

final class PhotoAttached extends PhotoAttempt {
  const PhotoAttached(this.relativePath);
  final String relativePath;
}

final class PhotoFailed extends PhotoAttempt {
  const PhotoFailed();
}

/// Take a photo and attach it to [lambing].
///
/// **THE COMPRESSOR IS INJECTED RATHER THAN CALLED**, which is how `MediaStore`
/// stays testable without a plugin: `12 §4.1`'s fakes pass a function that
/// writes known bytes, and this is the one place the real one is named.
Future<PhotoAttempt> attachPhotoTo(WidgetRef ref, LambingId lambing) async {
  final ({bool recovered, String path})? picked = await ref
      .read(cameraServiceProvider)
      .pick(CaptureSource.camera);
  if (picked == null) {
    return const PhotoAbandoned();
  }

  final MediaStore store = ref.read(mediaStoreProvider);
  final String relative = store.newRelativePath('jpg');

  try {
    // **THE SOURCE DIMENSIONS COME OFF THE FILE, NOT OFF A GUESS.**
    // `writePhoto` derives the longest edge from the aspect ratio, and passing
    // a square guess would cap the shortest edge instead — quietly breaking
    // decision #40 for every portrait frame.
    final ({int height, int width}) size = await _dimensions(File(picked.path));

    final File written = await store.writePhoto(
      sourcePath: picked.path,
      relativePath: relative,
      sourceWidth: size.width,
      sourceHeight: size.height,
      compressor:
          ({
            required String source,
            required String target,
            required int minWidth,
            required int minHeight,
            required int quality,
            required bool keepExif,
          }) async => (await FlutterImageCompress.compressAndGetFile(
            source,
            target,
            minWidth: minWidth,
            minHeight: minHeight,
            quality: quality,
            keepExif: keepExif,
          ))?.readAsBytes(),
    );

    // **THE ROW LAST.** A file with no row is what the orphan sweep moves to
    // `.trash/`; a row with no file is a record pointing at nothing, which is
    // the worse of the two and the one this order prevents.
    final NoteRepository notes = await ref.read(noteRepositoryProvider.future);
    final WriteOutcome outcome = await notes.attachPhoto(
      lambing,
      relativePath: relative,
      byteSize: written.lengthSync(),
    );

    return outcome is WriteCommitted ? PhotoAttached(relative) : const PhotoFailed();
  } on Object {
    // `MediaStore` has already cleaned up its own `.part`. There is nothing to
    // undo here and nothing to say beyond *it did not happen*.
    return const PhotoFailed();
  }
}

/// The picked frame's pixel size.
///
/// **DECODED FROM THE HEADER, NOT THE WHOLE IMAGE.** `decodeImageFromList`
/// would hold a 12-megapixel frame in memory to learn two integers, on a phone
/// that is already holding a lamb.
Future<({int width, int height})> _dimensions(File file) async {
  final ImageDescriptor descriptor = await ImageDescriptor.encoded(
    await ImmutableBuffer.fromUint8List(await file.readAsBytes()),
  );
  final ({int height, int width}) size = (width: descriptor.width, height: descriptor.height);
  descriptor.dispose();
  return size;
}
