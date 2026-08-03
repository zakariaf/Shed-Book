// test/policy/mirrored_enums_agree_test.dart
//
// `ShedPenTileStatus` in `lib/core/ui/components/` MIRRORS `PenTileStatus` in
// `lib/features/pens/`, because `layer.core_ui` forbids the component importing
// the feature.
//
// **THE COMPONENT'S DOC COMMENT PROMISED THIS FILE AND THIS FILE DID NOT
// EXIST.** It said the two enums were "kept in step by a test on the source
// text" — and nothing compared them. A comment that describes a mechanism which
// is not there is worse than no comment: it tells the next reader the risk is
// already handled.
//
// Found by a review of N16–N20, along with two other comments naming things that
// had been deleted or never written.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The member names declared by one `enum X { ... }` in [source].
List<String> _members(String source, String enumName) {
  final RegExp pattern = RegExp('enum\\s+$enumName\\s*\\{([^}]*)\\}');
  final RegExpMatch? m = pattern.firstMatch(source);
  expect(m, isNotNull, reason: '$enumName is not declared as a simple enum any more');
  return m!
      .group(1)!
      .split(',')
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .toList();
}

void main() {
  test('ShedPenTileStatus and PenTileStatus declare the same members in the same order', () {
    // ORDER MATTERS AS WELL AS MEMBERSHIP. The mapping switch in
    // `pen_board_screen.dart` is exhaustive, so it catches a member being ADDED
    // — it cannot catch two members being swapped, renamed in lockstep, or
    // drifting in meaning. This is the half the compiler does not hold.
    final List<String> component = _members(
      File('lib/core/ui/components/shed_pen_tile.dart').readAsStringSync(),
      'ShedPenTileStatus',
    );
    final List<String> feature = _members(
      File('lib/features/pens/pen_board_controller.dart').readAsStringSync(),
      'PenTileStatus',
    );

    expect(component, isNotEmpty, reason: 'the scan must actually find members');
    expect(
      component,
      feature,
      reason:
          'the mirror has drifted. Either bring them back into step, or — better — '
          'move the enum to lib/domain/penning.dart beside PenExitReason, which '
          'layer rule 7 permits lib/core/ui/ to import (shed_countdown.dart '
          'already does exactly that). Moving it needs a CONVENTIONS §6 ruling '
          'and the 10 §3.5 amendment in the same change.',
    );
  });
}
