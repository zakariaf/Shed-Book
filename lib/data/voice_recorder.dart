// lib/data/voice_recorder.dart
//
// The ONLY package:record import site in the app (R9, R47,
// layer.plugin_record). No plugin type crosses the boundary (08 §1.1) — which
// is why levelDbfs yields a double rather than the plugin's Amplitude.
//
// The class is `AudioRecorder`. `Record` was renamed in 5.0.0, and a snippet
// naming the old one predates that.
import 'dart:async';

import 'package:record/record.dart';
import 'package:shed_book/data/media_limits.dart';

final class VoiceRecorder {
  VoiceRecorder([AudioRecorder? recorder]) : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  Timer? _cap;

  /// Prompts for `RECORD_AUDIO` / `NSMicrophoneUsageDescription` natively.
  ///
  /// **Called on the FIRST TAP of the record button and never earlier.** A
  /// permission prompt on launch is a modal on the first frame, which is the one
  /// thing the first frame may not have.
  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Starts a recording at [absolutePath].
  ///
  /// **AAC-LC, NEVER Opus.** Opus in an `.m4a` container is not a combination
  /// every player accepts, and the voice note has to open on whatever the
  /// shepherd forwards it to.
  ///
  /// [onCapReached] fires if the cap stops the recording before the shepherd
  /// does. The write controller uses it to update the row exactly as it would on
  /// a manual stop, so **there is no second code path for a capped note** — a
  /// capped recording that took a different path is a recording with a different
  /// bug.
  Future<void> start(
    String absolutePath, {
    required void Function(String? path) onCapReached,
  }) async {
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: kVoiceNoteBitRate,
        sampleRate: kVoiceNoteSampleRate,
        numChannels: kVoiceNoteChannels,
      ),
      path: absolutePath,
    );

    _cap?.cancel();
    _cap = Timer(const Duration(seconds: kVoiceNoteMaxSeconds), () async {
      onCapReached(await stop());
    });
  }

  Future<String?> stop() async {
    _cap?.cancel();
    _cap = null;
    return _recorder.stop();
  }

  Future<void> cancel() async {
    _cap?.cancel();
    _cap = null;
    await _recorder.cancel();
  }

  Future<bool> isRecording() => _recorder.isRecording();

  /// dBFS, **not the plugin's `Amplitude`** — no plugin type crosses the
  /// boundary. The level meter is the only consumer.
  Stream<double> levelDbfs(Duration interval) =>
      _recorder.onAmplitudeChanged(interval).map((Amplitude a) => a.current);
}
