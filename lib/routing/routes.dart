// lib/routing/routes.dart — CONVENTIONS §1, §2.14. See 02 §8.
//
// lib/routing/ IMPORTING EVERY FEATURE IS NOT A LAYER VIOLATION. Layer rule 6
// (no sibling-feature imports) applies to lib/features/<a>/ → lib/features/<b>/;
// this is not a feature, and rule 5 explicitly allows lib/features/ →
// lib/routing/. That asymmetry is the trade the file buys: ONE file knows all
// twelve destinations, so no screen has to know a second one.
import 'package:flutter/material.dart';
import 'package:shed_book/domain/ids.dart';
import 'package:shed_book/features/export/export_screen.dart';
import 'package:shed_book/features/flock/ewe_card_screen.dart';
import 'package:shed_book/features/lambing/foster_screen.dart';
import 'package:shed_book/features/lambing/lamb_card_screen.dart';
import 'package:shed_book/features/lambing/lambing_entry_screen.dart';

/// Every route name that can appear in the diagnostics log. Route name is one of
/// the few fields decision #124 permits to be logged, so every route sets one.
///
/// Thirteen names, and today **zero push helpers**: Quick Entry is
/// `MaterialApp.home` (route 0, `isFirst`) and is never pushed, and the other
/// twelve screens do not exist yet. Each screen epic adds its own
/// `Routes.<screen>` push helper in the commit that adds the screen.
///
/// The arithmetic assertion — thirteen names minus twelve push helpers equals
/// one — is a `test/policy/` row in **N33**, not here: asserting it today would
/// assert 13 − 0 = 13 and would have to be edited twelve times. Critique **S2**.
///
/// **Twelve of the thirteen names have no destination, and that is free.** A
/// `static const String` creates no compile edge — no import, no symbol, no
/// type — which is the exact property S2's fix relies on, and why the names land
/// now rather than one at a time: the diagnostics log, the resume policy and
/// `ModalRoute.withName` all need the full vocabulary before the screens exist.
abstract final class RouteNames {
  static const String quickEntry = 'quick_entry';
  static const String flock = 'flock';
  static const String eweCard = 'ewe_card';
  static const String lambingEntry = 'lambing_entry';
  static const String lambCard = 'lamb_card';
  static const String foster = 'foster';
  static const String penBoard = 'pen_board';
  static const String treatments = 'treatments';
  static const String reminders = 'reminders';
  static const String seasonSummary = 'season_summary';
  static const String export = 'export';
  static const String settings = 'settings';

  /// The thirteenth, and it is **not** a spec §9 screen: decision #35 puts
  /// full-text note search on its own screen because it is a different problem
  /// from tag matching. It is a real route, the matrix pumps it like any other
  /// (`12 §6.1` variant 13), and leaving it out is how the count becomes twelve
  /// and the matrix becomes 234 cells.
  static const String noteSearch = 'note_search';
}

/// Navigation, and the only place a route is constructed.
///
/// **P3 IS RULED — see `00-tech-decisions` §7.** The mechanism is a `Navigator`
/// stack; the *affordance* is Indelible's, which is to say there is no back
/// chevron anywhere in this app. A push whose only exit is [popToQuickEntry]
/// reads to the shepherd as "one press deeper, never one press back" while
/// keeping route names for the diagnostics log, `ModalRoute.withName`, and
/// Android's hardware and predictive back working for free.
abstract final class Routes {
  /// The one navigator, so notification taps and the resume policy can navigate
  /// without a `BuildContext`.
  ///
  /// **A `GlobalKey` is a global and this is the only one.** A widget test that
  /// pumps *two* `MaterialApp`s carrying this key in one tree throws
  /// *"Duplicate GlobalKey detected in widget tree"*, and the message names the
  /// key rather than the test. Do not make it non-`final` and do not rebuild it
  /// per test; a test that needs two navigators passes its own key.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Back to the screen that started the flow. Used only by the pen-board flow's
  /// explicit "back to the board" action (`02 §8.2`).
  static void popTo(BuildContext context, String routeName) =>
      Navigator.of(context).popUntil(ModalRoute.withName(routeName));

  /// Back to Quick Entry — the "next ewe" action, and the resume policy.
  ///
  /// **This is the one helper that exists today, and it is a POP.** The failure
  /// mode it guards against is a well-meaning `Routes.quickEntry(context)` that
  /// pushes a second copy of the root route on top of itself.
  static void popToQuickEntry(BuildContext context) =>
      Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);

  /// The context-free twin: `ResumePolicy` in `lib/app.dart` and, later, a
  /// notification tap have no `BuildContext` to hand.
  static void popToQuickEntryGlobal() =>
      navigatorKey.currentState?.popUntil((Route<dynamic> r) => r.isFirst);

  /// The **only** place a `MaterialPageRoute` is constructed in this app.
  ///
  /// `RouteSettings(name:)` exists for exactly two reasons — the diagnostics log
  /// (#124) and `ModalRoute.withName` — and **never** for `pushNamed`. There is
  /// no `routes:` table and no route-generating callback: stringly-typed
  /// arguments are the exact thing this file removes (`02 §8.4`).
  ///
  /// **`route`, NOT `_route`, AND THE RENAME IS FORCED — MEASURED.** `02 §8.1`
  /// prints it private, and N13-T01 §5.2 says to keep it, not to delete it and
  /// not to silence it with an analyzer ignore. All three cannot hold: nothing
  /// in N13 pushes anything — Quick Entry is `home:` — so a private `_route`
  /// stays unreferenced through the whole epic, and `unused_element` is a
  /// WARNING, which the `gate` job's `--fatal-warnings` fails on. (An info would
  /// have been arguable; a warning is not.)
  ///
  /// `@visibleForTesting` is the smallest honest move and it buys something the
  /// private form could not: `routing_test.dart` CONSTRUCTS a route and reads
  /// the settings back, instead of grepping the source for the string
  /// `RouteSettings`. The name is not a `CONVENTIONS §2.14` name — that section
  /// carries `RouteNames`, `Routes` and `Routes.navigatorKey` and nothing else —
  /// so this deviates from `02 §8.1`'s printed body only, and it is recorded
  /// there in the same commit.
  ///
  /// It is the shape every screen epic copies, and landing it once with this
  /// comment attached is the difference between twelve consistent helpers and
  /// twelve nearly-consistent ones. The shape, printed once so nobody re-derives
  /// it — the argument is an extension-type id, never a bare `int` (R33):
  ///
  /// ```dart
  /// static Future<void> eweCard(BuildContext context, EweId id) =>
  ///     Navigator.of(context).push(Routes.route(
  ///       RouteNames.eweCard,
  ///       (_) => EweCardScreen(eweId: id),
  ///     ));
  /// ```
  ///
  /// Keeping this the only construction site is also what keeps the ziplock-bag
  /// contingency (`00-tech-decisions` §7.1 item 2) to one file: if the target
  /// hardware does not register taps through a freezer bag, every entry point
  /// gains a second context-free caller through [navigatorKey], and it changes
  /// here.
  @visibleForTesting
  static MaterialPageRoute<void> route(String name, WidgetBuilder builder) =>
      MaterialPageRoute<void>(
        builder: builder,
        settings: RouteSettings(name: name),
      );

  /// **THE FIRST PUSH HELPER IN THE PROJECT** (N16-T01). N13-T01 landed the
  /// thirteen names and only the Quick Entry POP, with a comment saying each
  /// screen epic adds its own — this is that epic.
  ///
  /// The argument is an extension-type id, never a bare `int` (R33): a helper
  /// taking an `int` would accept a `LambId` by mistake and open the wrong
  /// record, silently, with a right-looking number on it.
  static Future<void> lambingEntry(BuildContext context, LambingId id) => Navigator.of(
    context,
  ).push(route(RouteNames.lambingEntry, (BuildContext _) => LambingEntryScreen(lambingId: id)));

  /// N17-T01's screen. `LambId`, never `LambingId` — the two are one letter
  /// apart in prose and unmistakable in the type system, which is the point of
  /// R33.
  static Future<void> lambCard(BuildContext context, LambId id) => Navigator.of(
    context,
  ).push(route(RouteNames.lambCard, (BuildContext _) => LambCardScreen(lambId: id)));

  /// N18-T02's screen, opened FROM a lamb card. It takes the lamb rather than
  /// the ewe, because a foster is a fact about a lamb: the ewe is what the
  /// shepherd picks once they are here.
  static Future<void> foster(BuildContext context, LambId id) => Navigator.of(
    context,
  ).push(route(RouteNames.foster, (BuildContext _) => FosterScreen(lambId: id)));

  /// N27-T01's screen — the one `02 §8.1` printed as the shape every other
  /// helper copies, which is why it is the last of them to compile.
  ///
  /// **THE TAG TRAVELS WITH THE ID, AND THAT IS A DEVIATION FROM §8.1'S PRINTED
  /// BODY, RECORDED HERE.** Every other helper takes an id alone. This one also
  /// takes the tag, because the tag is what the shepherd tapped to get here and
  /// the card's heading is the first thing on the page — re-reading it through a
  /// second statement would put a frame between opening the card and knowing
  /// whose it is. It is not a second source of truth: nothing is written from
  /// it, and the summary line's counts still come from the database.
  static Future<void> eweCard(BuildContext context, EweId id, {required String tag}) =>
      Navigator.of(
        context,
      ).push(route(RouteNames.eweCard, (BuildContext _) => EweCardScreen(eweId: id, tag: tag)));

  /// **No argument.** The Export screen is scoped to the current season, which
  /// it reads for itself — passing a season id would be a second answer to a
  /// question `app_settings` already answers, one frame apart.
  static Future<void> export(BuildContext context) => Navigator.of(
    context,
  ).push(route(RouteNames.export, (BuildContext _) => const ExportScreen()));
}
