// lib/app.dart — minimum surface.
//
// T05 grows this into the real thing: the boot kick, the localisation
// delegates, the lifecycle observer and the accessibility wrapper. What is here
// is the smallest widget main() can name and still compile.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shed_book/core/ui/palettes.dart';
import 'package:shed_book/core/ui/theme.dart';

/// `ConsumerStatefulWidget` from the start (R34), because T05 attaches a
/// `WidgetsBindingObserver` to it and converting later would rewrite the file.
class ShedBookApp extends ConsumerStatefulWidget {
  const ShedBookApp({super.key});

  @override
  ConsumerState<ShedBookApp> createState() => _ShedBookAppState();
}

class _ShedBookAppState extends ConsumerState<ShedBookApp> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = buildShedTheme(nightPalette);
    return MaterialApp(
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      // The first painted frame is the page colour. No splash, no logo, no
      // white flash — on either platform.
      color: theme.scaffoldBackgroundColor,
      themeAnimationDuration: Duration.zero,
      home: const Scaffold(body: SizedBox.expand()),
    );
  }
}
