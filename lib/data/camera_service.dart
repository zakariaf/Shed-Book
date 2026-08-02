// lib/data/camera_service.dart
//
// The ONLY package:image_picker import site in the app (R9, R47,
// layer.plugin_image_picker). No plugin type crosses the boundary (08 §1.1) —
// which is what CaptureSource exists for.
import 'package:image_picker/image_picker.dart';
import 'package:shed_book/core/log/local_log.dart';

/// OURS, not the plugin's `ImageSource`.
///
/// It lives in `lib/data/` rather than `lib/domain/` because it exists only to
/// keep a plugin type off the boundary — a domain that knew about cameras would
/// be a domain that knew about a package.
enum CaptureSource { camera, library }

final class CameraService {
  CameraService([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Returns an absolute path in the OS's own temp area, plus whether it was
  /// recovered from a killed capture. The caller compresses and rehomes it
  /// through `MediaStore`; nothing else in `lib/` constructs a media `File`.
  ///
  /// **`null` means the shepherd cancelled** — not an error, not an exception.
  ///
  /// **`retrieveLostData()` is called AT THE TOP, not from a resume handler.**
  /// `08 §3.1` narrows `04 §4.4` here and 08 is the owning document: a resume
  /// handler that recovers a photo has nowhere to put it, because the attach
  /// slot that asked for it may no longer be on screen. The next `pick()` after
  /// a resume is the first moment a recovered file and a record to attach it to
  /// both exist. Ask for the lost picture FIRST, before offering the camera —
  /// the shepherd already took that photo, and making them take it twice at 3am
  /// is the failure this call exists to prevent.
  Future<({String path, bool recovered})?> pick(CaptureSource source) async {
    // NO Platform.isAndroid BRANCH, even though the plugin documents this as a
    // no-op on iOS. A platform check in a gateway is a second source of truth
    // about which platform loses data, and iOS's behaviour is the plugin's to
    // change rather than ours.
    final LostDataResponse lost = await _picker.retrieveLostData();
    if (!lost.isEmpty) {
      final XFile? file = lost.file;
      if (file != null) {
        return (path: file.path, recovered: true);
      }
      // A LostDataResponse CAN CARRY AN EXCEPTION INSTEAD OF A FILE, and
      // swallowing it hides a real capture failure. Returning null here would
      // tell the caller "the shepherd cancelled", which is a lie about a thing
      // that failed. Logged — never the message, only what we control (#124) —
      // and then we fall through to a fresh capture.
      LocalLog.instance.record('camera.lost_data_error');
    }

    final XFile? picked = await _picker.pickImage(
      source: source == CaptureSource.camera ? ImageSource.camera : ImageSource.gallery,
      // ALWAYS FALSE. The plugin documents that the microphone permission is
      // never requested when this is always false. It does NOT remove the
      // Info.plist keys, which App Store policy still requires (08 §8.4) —
      // those are N31-T04's, and shipping the flag while forgetting the key set
      // is an App Review finding.
      requestFullMetadata: false,
    );

    return picked == null ? null : (path: picked.path, recovered: false);
  }
}
