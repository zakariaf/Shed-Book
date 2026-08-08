// test/support/tolerant_comparator.dart
//
// **`LocalFileComparator` IS DOCUMENTED AS PIXEL-FOR-PIXEL EXACT, WITH NO
// TOLERANCE AT ALL.** On a suite of eight images rendered by a real variable
// font, that means a re-baseline every time anything touches the rasteriser —
// and a golden that is re-baselined reflexively is a golden nobody reads.
//
// Fifteen lines, and they are the whole argument against taking `alchemist` as a
// dependency: `diffThreshold` is the one feature of it worth having, it is a
// subclass and a comparison, and a package would have to clear the G2
// dependency allowlist to supply it (`12 §8.6`).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

final class TolerantFileComparator extends LocalFileComparator {
  TolerantFileComparator(super.testFile, {required this.tolerance});

  /// 0.5% of pixels.
  ///
  /// **Small enough that a moved baseline, a changed weight or a lost tabular
  /// figure fails; large enough to absorb the sub-pixel antialiasing two
  /// machines on the SAME Flutter version still disagree about.** It is not a
  /// licence for a different Flutter version — `12 §8.4` pins that separately,
  /// and a version bump re-baselines rather than widening this number.
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) {
      return true;
    }
    throw FlutterError(await generateFailureOutput(result, golden, basedir));
  }
}
