// lib/core/ui/components/shed_page.dart
//
// **THE DOCUMENT. `indelible.md §8`'s FIRST CLAIM, AND ONLY ONE SCREEN HAD IT.**
//
// §8: *"There is one scrolling ruled document. Twelve screens and note search are
// that document under a different filter — one spine, one header, one slab, one
// `INDEX` button. What changes is what the filter lets through. A layout that
// needs a second structure is wrong."*
//
// Measured on 2026-08-06 against the running app: **Quick Entry was the only
// screen with a spine.** The other six were a `Column` of `Text` on a dark
// background — no margin gutter, no sticky header, no thumb anchors, no ruled
// rows. Not a different filter on the same document; a different document each
// time, and none of them the one the design describes.
//
// The parts existed. They were in `lib/features/quick_entry/widgets/`, where
// `layer.sibling` made them unreachable from anywhere else (R87).
//
// ---------------------------------------------------------------------------
// WHAT THIS IS NOT
// ---------------------------------------------------------------------------
//
// Not a `Scaffold` wrapper with a theme on it. It owns four things no screen may
// re-decide, because the whole argument for one document is that they are the
// same on every screen:
//
//   * **The spine at x=68, unbroken.** It does not break for a header, a sheet or
//     a section, and it never mirrors — a book's margin is on the left (`§4.3`).
//   * **The 44 pt sticky header**, read-only and never a target. Put a back
//     button in it and you have created an illegal 44 pt target; back belongs to
//     `INDEX` in the thumb band, and there is no back chevron in this app at all
//     (ruling P3).
//   * **`SafeArea`.** Quick Entry shipped without one and drew its header under
//     the Dynamic Island. Every screen gets it here so no screen can forget.
//   * **The band's reserved height**, so nothing scrolls under the home
//     indicator and the two thumb anchors are where the thumb expects them.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_page_header.dart';
import 'package:shed_book/core/ui/components/shed_ruled_row.dart';
import 'package:shed_book/core/ui/components/shed_spine.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// `§4.4`: the page header is 44 pt, sticky, read-only, and never changes height.
const double kPageHeaderHeight = 44;

/// One ruled page.
final class ShedPage extends StatelessWidget {
  const ShedPage({
    required this.header,
    required this.children,
    super.key,
    this.band,
    this.fixedAboveBand,
    this.scrollKey,
  });

  /// `NIGHT OF 27 JULY 2026 · PAGE 3`, `THE PENS · 04:12 · 2 OVER †`.
  /// **Already formatted and already localised** — `lib/core/ui/` may not resolve
  /// copy, and a human-facing date is never all-numeric (R60).
  final String header;

  /// The stream. Ruled rows, sharing edges, scrolling under the band.
  final List<Widget> children;

  /// The two thumb anchors. `null` on a screen reached from `INDEX` that has no
  /// primary act of its own — and that is a decision worth making per screen
  /// rather than a default, because `§4.5` says nothing required to record an
  /// event may sit above 560 pt from the bottom.
  final Widget? band;

  /// A row welded above the band, outside the scroll — the live row's slot.
  ///
  /// **`indelible.html:1138` PUTS THE LIVE ROW INSIDE THE STREAM AND THAT IS THE
  /// DESIGN'S ONE GENUINE SAFETY GAP** (`00-comparison.md §4.1`): the open row
  /// scrolls away and you lose track of whose it is. The corrected rule is a
  /// fixed layer, and this is the slot that makes it one.
  final Widget? fixedAboveBand;

  final Key? scrollKey;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    return Scaffold(
      backgroundColor: t.surfaceBase,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // **THE BOTTOM LAYER, PAINTED BEHIND EVERYTHING.** A spine assembled
            // per row is a spine with seams, and the seams show under a head
            // torch at the moment the shepherd is scrolling.
            const ShedSpine(left: kRuledMarginWidth),
            Column(
              children: <Widget>[
                ShedPageHeader(text: header, height: kPageHeaderHeight),
                Expanded(
                  child: ClipRect(
                    child: SingleChildScrollView(
                      key: scrollKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    ),
                  ),
                ),
                if (fixedAboveBand case final Widget w) w,
                if (band case final Widget w) w,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
