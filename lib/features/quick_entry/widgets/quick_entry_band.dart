// lib/features/quick_entry/widgets/quick_entry_band.dart
//
// **THE THIN LAYER R87 LEFT BEHIND, AND IT IS ONE WATCH.**
//
// `indelible.md §8`: *"The tag lands. ... the slab arms — its border goes to
// `--ink-full`, a madder tick prints at its corner, and its label changes to
// `+ LAMB`."* Something has to notice that an animal was chosen.
//
// It may not be the screen: `quick_entry_test.dart` asserts the shell watches
// nothing, because a widget that watches nothing cannot be rebuilt by a keystroke
// or by an emission (`02 §10.1`) — and that, not any layout constant, is what
// makes every box on Quick Entry immovable under a thumb.
//
// And it may not be `ShedBottomBand`, because R87 moved that into
// `lib/core/ui/components/` where `layer.core_ui` forbids reading a provider at
// all. So it is here: one `ConsumerWidget`, watching one boolean, choosing
// between two strings. A rebuild moves nothing — the band is 152 pt, `INDEX` is
// 96 × 64 and the slab is 160 × 140, all fixed, none of them derived from the
// thing being watched.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/components/shed_bottom_band.dart';
import 'package:shed_book/features/quick_entry/quick_entry_controller.dart';

final class QuickEntryBand extends ConsumerWidget {
  const QuickEntryBand({
    required this.indexLabel,
    required this.slabLabelUnarmed,
    required this.slabLabelArmed,
    required this.onIndex,
    required this.onSlab,
    required this.bandHeight,
    required this.indexWidth,
    required this.indexHeight,
    required this.slabWidth,
    required this.slabHeight,
    super.key,
  });

  final String indexLabel;

  /// `TAG FIRST` — and it is **never disabled**. Pressing it opens the tag sheet,
  /// because a dead key under a cold thumb is indistinguishable from a missed tap.
  final String slabLabelUnarmed;

  /// `+ LAMB`, once an animal is chosen.
  final String slabLabelArmed;

  final VoidCallback onIndex;
  final VoidCallback onSlab;
  final double bandHeight;
  final double indexWidth;
  final double indexHeight;
  final double slabWidth;
  final double slabHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `.select`, so a keystroke in the tag sheet does not rebuild the band — only
    // the transition from nothing-chosen to chosen does.
    final bool armed = ref.watch(
      quickEntryControllerProvider.select((QuickEntryState s) => s.selected != null),
    );

    return ShedBottomBand(
      indexLabel: indexLabel,
      slabLabel: armed ? slabLabelArmed : slabLabelUnarmed,
      onIndex: onIndex,
      onSlab: onSlab,
      bandHeight: bandHeight,
      indexWidth: indexWidth,
      indexHeight: indexHeight,
      slabWidth: slabWidth,
      slabHeight: slabHeight,
    );
  }
}
