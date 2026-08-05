// test/flutter_test_config.dart
//
// **THE SDK'S PER-PROJECT HOOK, AND ITS SCOPE IS A DIRECTORY WALK.** The
// framework scans **up** from each test file to the first `flutter_test_config.dart`
// it finds, or to `pubspec.yaml`. So one file at `test/` covers everything under
// `test/` — and covers **nothing** under `integration_test/`, which is a separate
// tree with a separate binding. That is not a gap to fill by copying this file:
// an integration test drives a real app on a real device, where the fonts are the
// bundled ones already.
//
// Two things happen here and both are load-bearing for `goldens_test.dart`:
//
// 1. **The real font is loaded.** Without it every glyph renders as Ahem — a
//    full-em black box — and eight goldens capture eight pictures of nothing,
//    which look exactly like a correct run in the log.
// 2. **The tolerant comparator is installed**, because `LocalFileComparator` is
//    pixel-exact and would re-baseline on antialiasing.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/tolerant_comparator.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadAppFonts();

  // **`basedir` RESOLVES OFF A FILE URI, SO THE DIRECTORY IS WHAT DECIDES WHERE
  // GOLDEN KEYS RESOLVE.** `12 §8.3` prints this line ending in
  // `test/features/golden_test.dart` — singular, and no such file has ever
  // existed. The behaviour was right because only the directory is read; the
  // literal was a lie about a file, and it is corrected here and in 12 §8.3.
  goldenFileComparator = TolerantFileComparator(
    Uri.parse('${Directory.current.uri}test/features/goldens_test.dart'),
    tolerance: 0.005,
  );

  await testMain();
}

/// The bundled variable font, loaded into the test engine.
///
/// **ONE FAMILY, AND THAT IS P7's OPEN HALF RATHER THAN a shortcut here.**
/// `indelible.md §3.2` asks for two bundled faces; decision #98 names Atkinson
/// Hyperlegible Next and only that, and #98 is rank 1 in the authority order and
/// is not struck. So the goldens capture what ships.
Future<void> _loadAppFonts() async {
  final FontLoader loader = FontLoader('AtkinsonNext');
  final File file = File('assets/fonts/AtkinsonHyperlegibleNext[wght].ttf');

  // A missing font file must fail here, loudly, rather than silently leaving
  // Ahem installed — see the head comment.
  if (!file.existsSync()) {
    throw StateError('${file.path} is missing — every golden would capture Ahem');
  }
  loader.addFont(Future<ByteData>.value(ByteData.sublistView(file.readAsBytesSync())));
  await loader.load();
}
