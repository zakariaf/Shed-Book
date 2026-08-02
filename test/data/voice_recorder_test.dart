// test/data/voice_recorder_test.dart
//
// The codec, the container and the cap. The plugin is native, so what this file
// can assert is the CONFIGURATION it was handed and the cap's behaviour in a
// FakeAsync zone — and it says so rather than pretending to open a real file.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:shed_book/data/media_limits.dart';
import 'package:shed_book/data/voice_recorder.dart';

/// Reads the MPEG-4 `ftyp` brand out of a container header.
///
/// **In THIS file, not test/support/.** `12 §5.3` closes the support folder at
/// twelve files and gives a one-file helper exactly this home.
String? _ftypBrand(List<int> bytes) {
  if (bytes.length < 12) {
    return null;
  }
  final String box = String.fromCharCodes(bytes.sublist(4, 8));
  if (box != 'ftyp') {
    return null;
  }
  return String.fromCharCodes(bytes.sublist(8, 12));
}

/// A minimal MPEG-4 header: a 20-byte `ftyp` box branded `M4A `.
List<int> _mp4Header() => <int>[
  0,
  0,
  0,
  20,
  ...'ftyp'.codeUnits,
  ...'M4A '.codeUnits,
  0,
  0,
  2,
  0,
  ...'isom'.codeUnits,
];

/// An Ogg page header — the container Opus would land in.
List<int> _oggHeader() => <int>[...'OggS'.codeUnits, 0, 2, 0, 0, 0, 0, 0, 0];

/// Records what the gateway hands the plugin.
class _ScriptedRecorder implements AudioRecorder {
  RecordConfig? config;
  String? path;
  int stops = 0;

  @override
  Future<void> start(RecordConfig config, {required String path}) async {
    this.config = config;
    this.path = path;
  }

  @override
  Future<String?> stop() async {
    stops += 1;
    return path;
  }

  int cancels = 0;

  @override
  Future<void> cancel() async => cancels += 1;

  // The rest of AudioRecorder's surface is not exercised. `noSuchMethod` with a
  // `dynamic` return is what lets this class `implements` a wide plugin class
  // without stubbing thirty members the gateway never calls — and the three it
  // DOES call are written above, so a rename upstream is a compile error rather
  // than a silent no-op.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('the ftyp reader is not vacuous', () {
    // ASSERTED FIRST. A reader that always returned 'M4A ' would pass the anchor
    // and prove nothing — the same vacuity trap that has caught three
    // assertions in this project.
    expect(_ftypBrand(_mp4Header()), 'M4A ');
    expect(_ftypBrand(_oggHeader()), isNull, reason: 'an Ogg page is not an MPEG-4 container');
  });

  testWidgets('a recording is AAC-LC m4a and stops at kVoiceNoteMaxSeconds', (
    WidgetTester tester,
  ) async {
    // THE ANCHOR, AND IT IS A testWidgets FOR A REASON RATHER THAN BY HABIT.
    // The cap is a Timer, and 12 §2.2 says how to drive one: "fakeAsync in this
    // project means THE BINDING'S. You drive it with tester.pump, never by
    // constructing a FakeAsync yourself. package:fake_async is NOT a declared
    // dependency and importing it directly trips
    // depend_on_referenced_packages and is an allowlist change, not a
    // convenience." Measured: flutter_test does not re-export it either.
    //
    // So this pumps rather than elapsing a zone, and there is no widget tree —
    // which is fine: the binding's clock does not need one.
    final _ScriptedRecorder plugin = _ScriptedRecorder();
    final VoiceRecorder recorder = VoiceRecorder(plugin);

    final List<String?> capped = <String?>[];
    await recorder.start('/tmp/2026/03/note.m4a', onCapReached: capped.add);

    // THE CONFIGURATION, EXACTLY.
    expect(plugin.config!.encoder, AudioEncoder.aacLc, reason: 'NEVER opus');
    expect(plugin.config!.bitRate, kVoiceNoteBitRate);
    expect(plugin.config!.numChannels, kVoiceNoteChannels);
    expect(plugin.config!.sampleRate, kVoiceNoteSampleRate);
    expect(plugin.path, endsWith('.m4a'));

    // THE CAP FIRES ONCE, with the path stop() would have returned.
    expect(capped, isEmpty, reason: 'nothing before the cap');
    await tester.pump(const Duration(seconds: kVoiceNoteMaxSeconds));

    expect(capped, <String?>['/tmp/2026/03/note.m4a']);
    expect(plugin.stops, 1);

    // And a further advance fires NOTHING. A cap that re-armed would stop a
    // recording the shepherd started afterwards.
    await tester.pump(const Duration(seconds: kVoiceNoteMaxSeconds * 3));
    expect(capped, hasLength(1));
    expect(plugin.stops, 1);
  });

  testWidgets('a manual stop cancels the cap', (WidgetTester tester) async {
    // There is NO SECOND CODE PATH for a capped note — the cap calls the same
    // stop() — so the only thing that can differ is whether the timer survives
    // the stop. It must not: a cap that fired after a manual stop would stop the
    // NEXT recording.
    final _ScriptedRecorder plugin = _ScriptedRecorder();
    final VoiceRecorder recorder = VoiceRecorder(plugin);

    final List<String?> capped = <String?>[];
    await recorder.start('/tmp/2026/03/note.m4a', onCapReached: capped.add);
    await recorder.stop();
    await tester.pump(const Duration(seconds: kVoiceNoteMaxSeconds * 2));

    expect(capped, isEmpty, reason: 'the cap was cancelled by the manual stop');
    expect(plugin.stops, 1);
  });

  testWidgets('cancel also cancels the cap', (WidgetTester tester) async {
    final _ScriptedRecorder plugin = _ScriptedRecorder();
    final VoiceRecorder recorder = VoiceRecorder(plugin);

    final List<String?> capped = <String?>[];
    await recorder.start('/tmp/2026/03/note.m4a', onCapReached: capped.add);
    await recorder.cancel();
    await tester.pump(const Duration(seconds: kVoiceNoteMaxSeconds * 2));

    expect(capped, isEmpty);
  });

  test('the cap is 60 seconds, and the number lives in one place', () {
    // Decision-record §7.0 ruling 18. 60 is the RECOVERABLE direction rather
    // than the cheap one: raising a cap orphans nothing, whereas lowering one
    // makes recordings that already exist unreproducible.
    expect(kVoiceNoteMaxSeconds, 60);
    expect(
      File('lib/data/voice_recorder.dart').readAsStringSync(),
      isNot(contains('Duration(seconds: 60)')),
      reason: 'the number is named, never typed at the call site',
    );
  });

  test('VoiceRecorder is the one package:record call site', () {
    const String needle =
        'package:re' // split: this file is scanned
        'cord/';

    final List<File> importers = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .where((File f) => f.readAsStringSync().contains(needle))
        .toList();

    expect(importers.map((File f) => f.path), <String>['lib/data/voice_recorder.dart']);
  });
}
