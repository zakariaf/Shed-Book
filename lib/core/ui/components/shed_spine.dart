// lib/core/ui/components/shed_spine.dart
//
// **MOVED FROM `lib/features/quick_entry/widgets/` AT R87, AND THE MOVE IS A FIX
// RATHER THAN A TIDY-UP.** `layer.sibling` forbids one feature importing another,
// so a page component in a feature folder is a component only that feature can
// ever have. Measured: Quick Entry was the ONLY screen in the app with a spine, a
// margin cell or a ruled header — six screens rendered as a bare column because
// the parts were in a room they could not reach.
//
// THE SPINE IS CONTINUOUS AND IT DOES NOT MIRROR. indelible.md §4.3: "2 px wide,
// madder rule, continuous down the entire scroll. It does not break for headers,
// sheets, sections or the live row. It is what makes this a book and not a list;
// if a component would interrupt it, that component is wrong."
//
// So it is painted BEHIND everything as a Stack layer, never as a child of a row
// — a spine assembled per row is a spine with seams, and the seams show under a
// head torch at the exact moment the shepherd is scrolling.
//
// "A book's margin is on the left. Left-handed mode moves the slab, not the
// spine." It therefore takes no leftHanded parameter, deliberately.
//
// THE COLOUR IS `outline`, NOT A MADDER TOKEN, AND THAT IS P6 AGAIN. indelible
// §4.3 names `--madder-rule` from its own warm ramp; P6 ruled that 06 §4's ramps
// ship (decision #95 settles it from rank 1), and 06 §4 has no madder. `outline`
// is the token 06 gives a rule that must be findable under a head torch — it
// carries the >= 3:1 non-text contrast the rule needs. What indelible still
// binds here is the GEOMETRY and the continuity, which is the part that makes
// the page a book.
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/tokens.dart';

class ShedSpine extends StatelessWidget {
  const ShedSpine({required this.left, super.key});

  /// Where the margin column ends. Read off the layout rather than written down.
  final double left;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    return Positioned(
      key: const Key('quick_entry.spine'),
      left: left,
      top: 0,
      bottom: 0,
      width: t.outlineWidth,
      child: ColoredBox(color: t.outline),
    );
  }
}
