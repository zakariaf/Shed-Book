// lib/core/ui/components/shed_section_heading.dart
import 'package:flutter/material.dart';

/// A heading, with its level exposed to assistive technology.
///
/// **`headingLevel`, never the older boolean.** That boolean has been a no-op
/// since 3.44 — it is gate row `a11y.header_bool` for exactly that reason, and
/// the row scans this file, so it is described here rather than spelled. A
/// heading that announces nothing is a heading a screen-reader user cannot
/// navigate by, and the failure is completely silent on a developer's machine.
///
/// Only levels 1 and 2 exist in this app: `10 §3.4`'s table has no level 3
/// anywhere, so the parameter is **asserted rather than merely typed**. Screen
/// titles emit 1; everything else emits 2.
final class ShedSectionHeading extends StatelessWidget {
  const ShedSectionHeading({required this.label, super.key, this.level = 2})
    : assert(level == 1 || level == 2, 'only levels 1 and 2 exist — 10 §3.4');

  /// Arrives localised. This component composes no copy.
  final String label;

  final int level;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      headingLevel: level,
      child: Text(label, style: level == 1 ? text.titleLarge : text.titleMedium),
    );
  }
}
