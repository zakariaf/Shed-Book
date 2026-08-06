// lib/core/ui/components/shed_page_header.dart
//
// **MOVED FROM `lib/features/quick_entry/widgets/` AT R87, AND THE MOVE IS A FIX
// RATHER THAN A TIDY-UP.** `layer.sibling` forbids one feature importing another,
// so a page component in a feature folder is a component only that feature can
// ever have. Measured: Quick Entry was the ONLY screen in the app with a spine, a
// margin cell or a ruled header — six screens rendered as a bare column because
// the parts were in a room they could not reach.
//
// indelible.md §7.16's sticky header, naming what the page is filtered to.
// NEVER collapses, never parallaxes, never changes height — it is one of the
// boxes the shell's anchor test pins, and a header that grows on scroll moves
// every box below it.
//
// NOT A STAMP, SO THE SUB-18px EXEMPTION DOES NOT COVER IT. indelible §3.4
// permits sub-18px type only for stamps, and only when three conditions hold:
// at most 12 characters, all-caps at 0.14em, and never the sole carrier of
// meaning. This line reads "NIGHT OF 27 JUL 2026 · PAGE 3" — far longer than
// twelve characters, and it is the one line naming which night you are on. That
// is the audit block's Indelible defect 2. It renders at a role, never at 16.
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/tokens.dart';

class ShedPageHeader extends StatelessWidget {
  const ShedPageHeader({required this.text, required this.height, super.key});

  /// Already formatted and already localised. `d MMM y`, never all-numeric
  /// (R60, decision #108) — the formatting authority is
  /// `lib/core/ui/formatters.dart` and the pre-formatted string is passed into
  /// the ARB message, so there is one formatting authority rather than two.
  final String text;

  final double height;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    return SizedBox(
      key: const Key('quick_entry.page_header'),
      height: height,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: t.gapMin),
          // NOT `ShedSectionHeading`, AND THIS IS THE ONE SITE OF FIVE THAT
          // KEEPS ITS OWN RENDERING.
          //
          // The component prescribes `titleLarge` for level 1. Quick Entry is
          // the 3am screen and has the tightest vertical budget in the app — two
          // deck strips, a keypad and the entry sheet, none of which may give —
          // so a taller heading has nowhere to go. Measured: four matrix cells
          // overflowed the bottom by up to 72 px at textScaler 2.0.
          //
          // So the heading role and this screen's budget genuinely conflict, and
          // that is a design ruling rather than something to settle by shrinking
          // the component for everyone. The other four headings migrated.
          //
          // toUpperCase BELONGS HERE, NOT IN THE ARB. The caps are a typographic
          // decision owned by the design system and Flutter has no
          // text-transform; storing "NIGHT OF …" in the copy catalogue loses
          // that the first time somebody edits the string.
          child: Semantics(
            headingLevel: 1,
            child: Text(
              text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
      ),
    );
  }
}
