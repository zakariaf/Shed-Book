// lib/features/lambing/widgets/declare_type_sheet.dart
//
// WHAT THE QUERY MARK OPENS. It lists what was found, in the app's own
// observation voice, and offers exactly two ways out:
//
//   CHANGE THE BIRTH TYPE — writes the new declaration and LEAVES THE LAMBS
//                           ALONE. No lamb is added, none is struck, nothing is
//                           reconciled.
//   LEAVE IT              — writes nothing to either.
//
// NEITHER OPTION ADJUSTS ANYTHING, and that is §12.4 held by the shape of the
// sheet rather than by a reviewer's care. There is no third button, because a
// third button would be the app proposing a fix.
//
// Reachable ONLY from the type cell or from a query mark. It is not on the
// five-tap path and P8 is why: birth type is derived from the strokes and
// printed `(COUNTED)`, so a chooser that appears on its own would be the
// abolished chooser coming back through a side door.
library;

import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/components/shed_tap_target.dart';
import 'package:shed_book/core/ui/tokens.dart';
import 'package:shed_book/domain/birth_type.dart';

typedef DeclareTypeLabels = ({
  String heading,
  List<String> findings,
  String changeLabel,
  String leaveLabel,
  String Function(BirthType) typeWord,
});

class DeclareTypeSheet extends StatefulWidget {
  const DeclareTypeSheet({
    required this.labels,
    required this.onDeclare,
    required this.onLeave,
    super.key,
  });

  final DeclareTypeLabels labels;

  /// Writes the declaration. **The lambs are not touched**, here or downstream.
  final ValueChanged<BirthType> onDeclare;

  /// Writes nothing. It exists so that *leaving it* is an act the shepherd
  /// performs rather than a thing that happens when they walk away — the same
  /// reason the acknowledgement is recorded rather than forgotten.
  final VoidCallback onLeave;

  @override
  State<DeclareTypeSheet> createState() => _DeclareTypeSheetState();
}

class _DeclareTypeSheetState extends State<DeclareTypeSheet> {
  /// The five values appear only after CHANGE THE BIRTH TYPE is pressed.
  ///
  /// **A second step, deliberately.** Putting five values on the first screen
  /// would make declaring one the easy path and leaving it the awkward one,
  /// which is backwards: the counted number is the one the shepherd actually
  /// tallied, and the declaration is the exception.
  bool _choosing = false;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;
    final TextTheme text = Theme.of(context).textTheme;
    final DeclareTypeLabels l = widget.labels;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(t.gapMin),
            child: Text(l.heading, style: text.labelMedium),
          ),
          // WHAT WAS FOUND, ONE LINE EACH, IN THE OBSERVATION VOICE. Every one
          // of these strings comes from a `Warning.message`, which says what we
          // observed and NEVER what to do: a warning that instructs is advice
          // (§12.2), and a warning that changes a value is a correction (§12.4).
          for (final String finding in l.findings)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
              child: Text(finding, style: text.bodyMedium),
            ),
          SizedBox(height: t.gapMin),
          if (!_choosing) ...<Widget>[
            _SheetButton(
              id: 'lambing_entry.declare.change',
              label: l.changeLabel,
              onTap: () => setState(() => _choosing = true),
            ),
            // gapDestructive between the two, because they are opposites and a
            // mis-tap here is the one that changes a record.
            SizedBox(height: t.gapDestructive),
            _SheetButton(
              id: 'lambing_entry.declare.leave',
              label: l.leaveLabel,
              onTap: widget.onLeave,
            ),
          ] else
            for (final BirthType type in BirthType.values)
              _SheetButton(
                id: 'lambing_entry.declare.type_${type.code}',
                label: l.typeWord(type),
                onTap: () => widget.onDeclare(type),
              ),
          SizedBox(height: t.gapMin),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({required this.id, required this.label, required this.onTap});

  final String id;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ShedTokens t = context.tokens;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.gapMin, vertical: t.gapMin / 4),
      child: ShedTapTarget(
        key: Key(id),
        semanticLabel: label,
        minSize: t.tapHero,
        onTap: onTap,
        child: ExcludeSemantics(
          child: Center(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
        ),
      ),
    );
  }
}
