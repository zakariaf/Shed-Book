// lib/features/lambing/voice_controller.dart
//
// **THE VOICE CHAIN, WHICH HAD NO CALLER AT ANY LINK.** `hasPermission`,
// `start`, `stop` and `levelDbfs` on `VoiceRecorder`, and `beginVoiceNote` and
// `completeVoiceNote` on `NoteRepository`, all landed at N15 with their own
// tests and their own fakes. Nothing joined them up.
//
// **THE ROW IS WRITTEN WHEN THE RECORDING STARTS, NOT WHEN IT ENDS**, and that
// is `beginVoiceNote`'s whole shape: a recording interrupted by a flat battery
// leaves a row pointing at a partial file, which the media sweep can find and
// mark, rather than a file nobody knows about. `completeVoiceNote` fills in the
// size and the duration afterwards.
//
// **A VOICE NOTE NEVER CARRIES A FACT THAT EXISTS NOWHERE ELSE**
// (`docs/store/accessibility-nutrition-label.md` §4). The app cannot transcribe
// it — on-device recognition was cut because the recognizer runs in another
// process whose network access the manifest cannot constrain — so it is a
// margin remark beside a record, never the only place a lambing lives.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/data/media_store.dart';
import 'package:shed_book/data/note_repository.dart';
import 'package:shed_book/data/providers.dart';
import 'package:shed_book/data/voice_recorder.dart';
import 'package:shed_book/domain/ids.dart';

/// What a recording ended as.
sealed class VoiceAttempt {
  const VoiceAttempt();
}

/// The OS says no microphone. **It states the fact and asks for nothing** — the
/// permission prompt is another process and appears once, on first use.
final class VoiceNoPermission extends VoiceAttempt {
  const VoiceNoPermission();
}

final class VoiceRecording extends VoiceAttempt {
  const VoiceRecording(this.relativePath);
  final String relativePath;
}

final class VoiceSaved extends VoiceAttempt {
  const VoiceSaved(this.relativePath);
  final String relativePath;
}

final class VoiceFailed extends VoiceAttempt {
  const VoiceFailed();
}

/// Start a voice note on [lambing]. The row lands before the first byte does.
Future<VoiceAttempt> startVoiceNote(WidgetRef ref, LambingId lambing) async {
  final VoiceRecorder recorder = ref.read(voiceRecorderProvider);
  if (!await recorder.hasPermission()) {
    return const VoiceNoPermission();
  }

  final MediaStore store = ref.read(mediaStoreProvider);
  final String relative = store.newRelativePath('m4a');
  final NoteRepository notes = await ref.read(noteRepositoryProvider.future);

  // **THE ROW FIRST.** A recording that dies with the battery leaves a row the
  // sweep can mark, rather than a file nobody knows about.
  await notes.beginVoiceNote(lambing, relativePath: relative);

  try {
    final String absolute = (await store.resolve(relative)).path;
    await recorder.start(
      absolute,
      // **THE CAP IS THE RECORDER'S, AND IT ENDS THE RECORDING ITSELF.** A cap
      // that only warned would leave a shepherd who put the phone in a pocket
      // with a file the size of the evening.
      onCapReached: (String? path) => _complete(ref, relative),
    );
    return VoiceRecording(relative);
  } on Object {
    return const VoiceFailed();
  }
}

/// Stop the recording and fill in what the row could not know at the start.
Future<VoiceAttempt> stopVoiceNote(WidgetRef ref, String relativePath) async {
  await ref.read(voiceRecorderProvider).stop();
  return _complete(ref, relativePath);
}

Future<VoiceAttempt> _complete(WidgetRef ref, String relativePath) async {
  try {
    final MediaStore store = ref.read(mediaStoreProvider);
    final NoteRepository notes = await ref.read(noteRepositoryProvider.future);

    final int bytes = (await store.resolve(relativePath)).lengthSync();
    await notes.completeVoiceNote(
      relativePath: relativePath,
      byteSize: bytes,
      // **THE DURATION IS NOT GUESSED FROM THE SIZE.** AAC-LC is variable
      // bitrate, so bytes-over-bitrate is a number the app originated — and
      // `05 §12.2`'s origination line says the app may transform a number the
      // user supplied and may never invent one. Zero is the honest answer until
      // something reads it off the file.
      durationMs: 0,
    );
    return VoiceSaved(relativePath);
  } on Object {
    return const VoiceFailed();
  }
}
