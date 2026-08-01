// The real entry point is `01-architecture.md` §6's ~20 lines — awaits nothing,
// installs the error handlers, calls runApp() — and it is written in **N11**
// together with `lib/app.dart` and `ShedBookApp`.
//
// Until then this file exists for exactly one reason: `flutter build apk
// --debug` needs an entry point, and N00-T01's Definition of Done already
// asserts that build completes. Deleting the file breaks it; leaving
// `flutter create`'s sample means `flutter analyze --fatal-infos` fails on demo
// code the moment N01-T02 lands the strict block.
//
// `lib/app.dart` is deliberately NOT created here. `ShedBookApp` is N11's, and
// a placeholder would be a second file N11 has to delete.
import 'package:flutter/widgets.dart';

void main() => runApp(const SizedBox.shrink());
