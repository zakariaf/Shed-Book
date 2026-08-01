// lib/core/ui/night_error_panel.dart
//
// Renders when everything else has failed. It may be invoked with NO Theme, NO
// MediaQuery, NO Directionality and NO Localizations in scope, so it reads none
// of them.
//
// package:flutter/widgets.dart, NOT material.dart. Material's widgets look up
// Theme, MaterialLocalizations and MediaQuery, which is the entire failure mode
// this file exists to avoid: a Scaffold, a Text with a style: from Theme.of, an
// ElevatedButton or a SnackBar in here throws INSIDE the error handler, and the
// shepherd gets a grey screen with no diagnosis at all.
//
// The one file besides primitives.dart allowed a raw hex under lib/ — allowlist
// line `lib/core/ui/night_error_panel.dart :: token.raw_color`. It cannot read a
// token, so it cannot read `nSurface04` either; the value is duplicated here and
// a test compares the two.
//
// Copy is hard-coded English BY CONSTRUCTION (10 §8.7 rule 6): Localizations may
// not be in scope, and a panel that throws looking up its own copy is a panel
// that does not render.
import 'package:flutter/widgets.dart';

/// The dark error screen.
///
/// The default red-on-yellow `ErrorWidget` is a flashbang under a head torch.
class NightErrorPanel extends StatelessWidget {
  const NightErrorPanel({super.key, this.onSaveACopy});

  /// Wired by the Diagnostics route when one exists (N29). **Null here, and the
  /// action still renders enabled** — a disabled-looking button at 3am reads as
  /// a broken app, so it renders and does nothing until N29 lands it.
  final VoidCallback? onSaveACopy;

  /// The base surface, P14 (`#0A0A0B`, ruled at N11-T04). Duplicated from
  /// `primitives.dart` rather than imported, because this widget must not depend
  /// on anything that could itself fail — and a test asserts the two agree.
  static const Color pageColour = Color(0xFF0A0A0B);

  /// Near-white, not pure white: this panel is read at 03:20 and halation is the
  /// reason indelible.md §2.2 rejects white-on-black in the first place.
  static const Color inkColour = Color(0xFFE8EAED);

  /// Named rather than written inline, and NOT to satisfy taste: the literal
  /// forms fire `token.literal_font_size` and `token.magic_size`, and this file
  /// is exempted only from `token.raw_color`. R56 fixes `[exempt]` at four lines,
  /// so the remedy is the one those rows ask for — name the value — rather than
  /// a fifth waiver. It cannot come from `ShedTokens`: reading a token is
  /// reading a `Theme`, which is the one thing this widget must never do.
  static const double _bodySize = 20;
  static const double _target = 64;
  static const double _gap = 24;

  static const String message = 'Something went wrong on this screen. Your records are safe.';
  static const String saveACopy = 'Save a copy of my records';

  @override
  Widget build(BuildContext context) => Directionality(
    // Constraint 1: supply our own. There may be no ancestor.
    textDirection: TextDirection.ltr,
    child: ColoredBox(
      // Constraint 2: no Theme, no token lookup.
      color: pageColour,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              message,
              textAlign: TextAlign.center,
              // Constraint 3: an explicit style with an explicit size. There is
              // no DefaultTextStyle to inherit from and no TextTheme to read.
              style: TextStyle(color: inkColour, fontSize: _bodySize),
            ),
            const SizedBox(height: _gap),
            Semantics(
              button: true,
              label: saveACopy,
              onTap: onSaveACopy,
              child: ExcludeSemantics(
                child: GestureDetector(
                  onTap: onSaveACopy,
                  behavior: HitTestBehavior.opaque,
                  child: ConstrainedBox(
                    // The build box, written here rather than read from a
                    // token, because a token lookup is a Theme lookup.
                    constraints: const BoxConstraints(minWidth: _target, minHeight: _target),
                    child: Center(
                      child: const Text(
                        saveACopy,
                        style: TextStyle(color: inkColour, fontSize: _bodySize),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
