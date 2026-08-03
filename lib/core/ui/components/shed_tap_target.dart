// lib/core/ui/components/shed_tap_target.dart — the 60 pt contract, as a widget.
import 'package:flutter/material.dart';
import 'package:shed_book/core/ui/tokens.dart';

/// Guarantees a >= [minSize] hit region regardless of the child's painted size,
/// and makes the whole region opaque to hit testing so a tap in the transparent
/// margin still counts. **That margin IS the hit slop.**
///
/// `minSize` defaults to `context.tokens.tapMin` — 60, the spec §5 contract
/// floor. indelible.md §4.5's audit builds to 64, and the four points between
/// them are the entire margin: the gate asserts 60 because that is the contract,
/// and components pass 64 because that is the design.
///
/// **No `InkWell`.** A ripple is a scale-and-fade animation on a target, and
/// indelible.md §5.1 says a press is a fill change only — *"a target that shrinks
/// under a cold thumb is a target you miss"*. `theme.dart` already pins
/// `NoSplash.splashFactory` for the same reason; using `GestureDetector` here
/// means the rule does not depend on that pin holding.
class ShedTapTarget extends StatelessWidget {
  const ShedTapTarget({
    required this.onTap,
    required this.child,
    required this.semanticLabel,
    super.key,
    this.minSize,
    this.onTapHint,
    this.selected,
  });

  /// Null means disabled. A disabled target is still a target — it keeps its
  /// size and its label, and only loses its action.
  final VoidCallback? onTap;

  final Widget child;

  /// **Required, and non-nullable at the type level.** An unlabelled node is an
  /// unnamed stop in a Switch Control scan: the user hears "button" and has no
  /// idea which one. A runtime assert would be stripped in release, which is
  /// precisely the build where nobody is watching.
  ///
  /// It carries no role word — never ending in `button`, `link` or `tab`
  /// (10 §3.2 rule 1), because the platform already announces the role and the
  /// user hears it twice.
  final String semanticLabel;

  final double? minSize;

  /// Overrides the VERB an assistive technology announces for the tap action —
  /// "double tap to *record a lambing*". Inert without a tap action to rename,
  /// which is one more reason the `Semantics(onTap:)` line below is mandatory.
  final String? onTapHint;

  /// **STATE GOES HERE, NEVER IN THE LABEL** (`10 §3.2` rule 2). A word button
  /// that announces *"Barren, selected"* has a label that no longer matches its
  /// visible text, which is rule 3 of the same section — and a screen reader then
  /// reads the state twice, once from the string and once from the node.
  ///
  /// Null for a control that has no selected/unselected axis at all, which is
  /// most of them: `Semantics.selected` on a plain button announces it as a
  /// toggle that is currently off.
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final double size = minSize ?? context.tokens.tapMin;
    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: semanticLabel,
      // MANDATORY, AND THE LINE EVERYBODY DELETES. ExcludeSemantics below drops
      // the GestureDetector's own SemanticsAction.tap, so without this the node
      // announces correctly as a button and then REFUSES TO ACTIVATE under
      // VoiceOver or Switch Control.
      //
      // Nothing in flutter_test catches it — not MinimumTapTargetGuideline, not
      // labeledTapTargetGuideline — which is exactly why 06 §6.3's geometric
      // gate asserts node.hasAction(SemanticsAction.tap) by hand.
      onTap: onTap,
      onTapHint: onTapHint,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          // What turns the transparent margin into a target rather than a hole.
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: size, minHeight: size),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
