// lib/core/ui/components/shed_status_badge.dart
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// indelible.md §7.7's two lists, and **the boundary between them is the whole
/// design**: BOXED is a state of the animal, UNBOXED is a note about the record.
///
/// The form is a real second channel, not a naming convention — a reader who
/// cannot tell the inks apart still sees which stamps are about the ewe and
/// which are about the row.
enum ShedStampForm { boxed, unboxed }

enum ShedStamp {
  // Boxed — a state of the animal.
  penned(ShedStampForm.boxed),
  lambed(ShedStampForm.boxed),
  barren(ShedStampForm.boxed),
  withdrawal(ShedStampForm.boxed),
  toLamb(ShedStampForm.boxed),
  dead(ShedStampForm.boxed),
  alive(ShedStampForm.boxed),
  petLamb(ShedStampForm.boxed),
  over(ShedStampForm.boxed),

  // Unboxed — a note about the record itself.
  auto(ShedStampForm.unboxed),
  edited(ShedStampForm.unboxed),
  derived(ShedStampForm.unboxed),
  counted(ShedStampForm.unboxed),
  yourEntry(ShedStampForm.unboxed),
  struck(ShedStampForm.unboxed),
  muted(ShedStampForm.unboxed),
  notRecorded(ShedStampForm.unboxed);

  const ShedStamp(this.form);

  final ShedStampForm form;
}

/// A stamp: a word, and a form.
///
/// **Stamps are not targets** (indelible.md §7.7). This is a `StatelessWidget`
/// with no gesture and no `ShedTapTarget` — a stamp that could be pressed is a
/// stamp a shepherd presses at 03:20 expecting something to happen.
final class ShedStatusBadge extends StatelessWidget {
  ShedStatusBadge({required this.stamp, required this.label, super.key})
    : assert(label.trim().isNotEmpty, 'a stamp is a WORD; there is no wordless state — 06 §12');

  final ShedStamp stamp;

  /// Always required, always non-empty, and arrives localised. There is no state
  /// of this widget that renders a shape and no word.
  final String label;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    // `dead` USES NO STATUS COLOUR. indelible.md §2.7: a lamb that died prints
    // the word DEAD, in full ink, with "colour: none, ever". The status fields
    // exist for ShedStatusBadge to name; their existence is not a licence, and
    // this is the one stamp where using one would be actively wrong.
    final Color ink = t.textPrimary;

    final Widget word = Text(
      label,
      // titleSmall is the floor role — 18 at scale 1.0. The Indelible artefact
      // sets stamps at 14 px, and 02 §4.4 defect 2 rules that four of them are
      // never the sole carrier of their meaning and must clear 18. Rather than
      // split the set, every stamp takes the floor: a stamp worth showing at
      // 03:20 is worth 18 px.
      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: ink),
      maxLines: 1,
    );

    return switch (stamp.form) {
      ShedStampForm.boxed => DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: t.outline, width: t.outlineWidth),
          borderRadius: BorderRadius.all(Radius.circular(t.radiusControl)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: t.gapMin / 2),
          child: word,
        ),
      ),
      ShedStampForm.unboxed => word,
    };
  }
}
