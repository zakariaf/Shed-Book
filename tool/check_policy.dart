// tool/check_policy.dart
//
// The single source-and-dependency gate for Shed Book.
//   dart tool/check_policy.dart
//
// NEVER `dart run`. Measured 2026-08-01 (N03-T01): the `run` subcommand does an
// implicit `pub get` and executes the package's build hooks, so on a cold hook
// cache with no network it fails at a pub.dev advisories fetch — which is
// exactly "it can fail for reasons that are not violations". Without `run` it
// exits 0 on the same tree, in ~2.5 s, of which the walk is milliseconds.
// Exit codes: 0 clean · 1 violations · 2 the gate could not run (still a failure).
//
// Dependency-free by decision (00-tech-decisions #9, #10): every analyzer plugin
// that could express these rules is discontinued, archived, or unresolvable
// against drift_dev's analyzer ^13.0.0. Do not add a second scanning script;
// the answer to a new rule is a new row in the tables below. The moment this
// script needs `pub get` it can fail for reasons that are not violations.
//
// THE RULE TABLE IS NOT CLOSED. copy.vet_advice and copy.disclaimer_retyped
// need ContentPolicy and Disclaimers and arrive with them (N06-T09). The
// db.destructive_ddl family arrives with the migration harness (N08), and
// layer.in_app_purchase / launch.store_call with monetization (N30). A row and
// the case that proves it fires land in the same commit — always.
//
// NEVER edit this file, its rule table, its exit code, or
// tool/policy_allowlist.txt to make a build pass. An [exempt] line deletes one
// rule for one file, forever, and silently. If a gate is genuinely wrong, say
// so and stop.

import 'dart:io';

const String _package = 'shed_book';

/// Walked roots. `tool/` is deliberately absent: this file's own tables contain
/// every banned literal, so scanning it would fail the build on itself.
const List<String> _roots = <String>['lib', 'test'];

/// The four allowlist sections. A header outside this set is a typo that would
/// empty a whole section, so it is refused rather than accepted.
const Set<String> _allowlistSections = <String>{
  'dependencies',
  'dev_dependencies',
  'transitive',
  'exempt',
};

/// Most specific prefix first — [_layerOf] returns the first match.
///
/// **The order is the rule.** `lib/core/ui/` and `lib/core/db/` must both
/// precede `lib/core/`, and `lib/` must be last. Sort this list alphabetically —
/// a plausible tidy-up — and `lib/core/db/database.dart` resolves to layer
/// `lib/core/`, which *is* allowed to import `lib/core/ui/`, so R16's carefully
/// drawn line disappears with no test failing.
const List<String> _layers = <String>[
  'lib/core/db/',
  'lib/core/ui/',
  'lib/core/',
  'lib/domain/',
  'lib/data/',
  'lib/features/',
  'lib/routing/',
  'lib/',
];

/// CONVENTIONS §1.1's eight layer rules, as amended. Copied, never re-derived.
const Map<String, Set<String>> _mayImport = <String, Set<String>>{
  'lib/domain/': <String>{'lib/domain/'},
  'lib/core/db/': <String>{'lib/core/db/', 'lib/core/', 'lib/domain/'}, // R16
  'lib/core/ui/': <String>{'lib/core/ui/', 'lib/domain/'},
  'lib/core/': <String>{'lib/core/', 'lib/core/ui/', 'lib/core/db/', 'lib/domain/'},
  'lib/data/': <String>{'lib/data/', 'lib/core/', 'lib/core/db/', 'lib/core/ui/', 'lib/domain/'},
  'lib/features/': <String>{
    'lib/features/',
    'lib/data/',
    'lib/domain/',
    'lib/core/',
    'lib/core/ui/',
    'lib/routing/',
  },
  'lib/routing/': <String>{
    'lib/routing/',
    'lib/features/',
    'lib/data/',
    'lib/core/',
    'lib/domain/',
  },
  'lib/': <String>{
    'lib/',
    'lib/core/',
    'lib/core/ui/',
    'lib/data/',
    'lib/domain/',
    'lib/features/',
    'lib/routing/',
  },
};

const Map<String, Set<String>> _bannedPackages = <String, Set<String>>{
  // R24: package:clock is banned in the domain. A pure function that needs the
  // current instant takes it as a parameter: timeSincePenned(enteredAt, now).
  'lib/domain/': <String>{
    'package:flutter/',
    'package:drift/',
    'package:sqlite3',
    'package:flutter_riverpod/',
    'package:riverpod/',
    'package:intl/',
    'package:clock/',
  },
  'lib/data/': <String>{'package:flutter/material.dart', 'package:flutter/cupertino.dart'},
  'lib/core/ui/': <String>{'package:drift/', 'package:sqlite3'},
  'lib/features/': <String>{'package:drift/', 'package:sqlite3'},
  'lib/routing/': <String>{'package:drift/', 'package:sqlite3'},
  'lib/': <String>{'package:drift/', 'package:sqlite3'},
};

/// Path-pair bans. Not expressible in [_mayImport], because `lib/data/` may
/// import the rest of `lib/domain/` freely. R53 — spec §12.4's structural half,
/// and the one rule in this table a reviewer may never wave through.
const List<(String, String, String)> _bannedPathPairs = <(String, String, String)>[
  ('layer.data_no_validation', 'lib/data/', 'lib/domain/validation/'),
];

/// The importing layer → the id its direction violation is reported under.
///
/// `01 §3.2`'s printed driver emits `layer.direction` and `layer.import`, and
/// neither is one of CONVENTIONS §1.1's ten ids — so the inventory assertion
/// would face ten ids with no proving case and two proving cases with no id.
/// `lib/routing/` shares `layer.features` because §1.1 gives routing no id of
/// its own, and the two-way routing↔features edge is deliberate.
const Map<String, String> _directionRuleId = <String, String>{
  'lib/domain/': 'layer.domain',
  'lib/core/db/': 'layer.core_db',
  'lib/core/ui/': 'layer.core_ui',
  'lib/core/': 'layer.core_ui',
  'lib/data/': 'layer.data',
  'lib/features/': 'layer.features',
  'lib/routing/': 'layer.features',
  'lib/': 'layer.root',
};

/// Every layer rule id, in CONVENTIONS §1.1's order. Listed rather than derived
/// from the maps above, because `layer.sibling`, `layer.single_writer` and
/// `layer.data_no_validation` are emitted by code and not by a map entry, and
/// an inventory that cannot see them is an inventory with holes.
const List<String> _layerRuleIds = <String>[
  'layer.domain',
  'layer.core_db',
  'layer.data',
  'layer.data_no_material',
  'layer.features',
  'layer.sibling',
  'layer.core_ui',
  'layer.single_writer',
  'layer.root',
  'layer.data_no_validation',
];

/// G3 of the offline contract. Applies to **every scanned file**, in both roots,
/// regardless of layer — a network dependency in the test tier is still in the
/// graph. Reported under `layer.import`, which is the one import id that is not
/// a direction rule.
///
/// `package:firebase_` and `package:google_mlkit_` carry **no trailing slash**:
/// they are prefixes over a family of packages, not a single package root, and
/// adding the slash silently unbans `firebase_core`.
///
/// `package:printing/` and `package:google_fonts/` are banned here *and* on G2's
/// allowlist. That is not duplication: G2 stops the package entering the graph,
/// G3 stops a source file importing it if it ever does — transitively, for
/// instance, via a package that vendors it.
const Set<String> _bannedEverywhere = <String>{
  'package:http/',
  'package:dio/',
  'package:connectivity_plus/',
  'package:workmanager/',
  'package:battery_plus/',
  'package:web_socket_channel/',
  'package:firebase_',
  'package:google_fonts/',
  'package:printing/',
  'package:speech_to_text/',
  'package:google_mlkit_',
  'package:permission_handler/',
};

/// (id, literal text, path prefix it applies under, why). An empty `under`
/// means every scanned root — the driver never walks anything else.
///
/// **The `net.*` rows are not redundant with [_bannedEverywhere].** That set
/// matches `package:` URIs, and the highest-risk socket APIs in this app do not
/// arrive on one: `HttpClient`, `Socket` and `WebSocket` come from `dart:io`,
/// which every file may legitimately import, and `Image.network` is in the
/// Flutter SDK. G3 claims our own source cannot reach a network API; without
/// these rows it is not proved.
///
/// **There is no rule that reads `pubspec.lock` for `http`, and there must never
/// be one.** `http 1.6.0` sits on two REGULAR edges —
/// `flutter_local_notifications → timezone → http`, and
/// `wakelock_plus → package_info_plus → http`. Such a rule is permanently red,
/// so it gets deleted by whoever meets it first, and then there is no gate at
/// all. The claim G2 makes is narrower and true: no package enters the graph
/// unreviewed. (00-tech-decisions §3.4 #1, 13 §2.4.) `test/policy/gate_rules_test.dart`
/// holds that as an assertion, because a comment cannot stop a future row.
///
/// **There is no `Uri.parse(` row, and that is a decision.** A bare one would
/// fire on the media store's relative paths, on the restore path and on
/// `share_plus`'s file URIs — all legitimate, none a network path. `01 §3.3`
/// names the anti-pattern: a rule that gets weakened is worse than one never
/// written. If a scheme check is ever wanted it belongs where a URI is actually
/// constructed, and that is one file.
const List<(String, String, String, String)> _bannedText = <(String, String, String, String)>[
  // 'Socket.connect(' also matches RawSocket.connect( and SecureSocket.connect(,
  // because both contain it. Deliberate, and why the row carries the dot and the
  // open paren rather than a bare `Socket`.
  //
  // 'HttpClient(' misses `HttpClient.new` and a torn-off constructor. Both are
  // legal Dart and neither contains the literal. That is the honest limit of a
  // text gate: G3 proves our source has no obvious network call site, not that
  // it cannot possibly open a socket. What G3 does not prove is G1's job, and
  // the split is the point (13 §2.5). Upgrade the claim's honesty, never the row.
  ('net.http_client', 'HttpClient(', 'lib/', 'dart:io socket — G3'),
  ('net.socket', 'Socket.connect(', 'lib/', 'dart:io socket — G3'),
  ('net.web_socket', 'WebSocket.', 'lib/', 'dart:io socket — G3'),
  ('net.image_network', 'Image.network(', 'lib/', 'no remote assets — G3'),
  // Bans an identifier, not an import: PdfGoogleFonts is a class inside
  // package:printing, and #83 keeps pdf and rejects printing exactly because
  // the class is a one-line footgun. The row fires on a copied snippet before
  // the import is even added.
  ('net.pdf_fonts', 'PdfGoogleFonts', 'lib/', 'fetches fonts over HTTP — G3, #83'),
  // No exemption, deliberately: R25's one ticker is built on Future.delayed
  // precisely so this row needs no waiver (#66). A developer reaching for
  // Timer.periodic at N12 is this row working, not this row being wrong.
  (
    'net.sync_timer',
    'Timer.periodic(',
    'lib/',
    'per-row timers and refresh loops are both banned; the one ticker uses '
        'Future.delayed so this rule needs no exemption — #66, #7',
  ),

  // -- design: the literal rows (06 §3.5) -----------------------------------
  // R55: scoped lib/, NOT lib/features/ as 01 §3.2 prints them.
  // lib/core/ui/components/ is exactly where a shared widget would hide a raw
  // hex. The two [exempt] lines are the only escape, and they name one file each.
  ('token.raw_color', 'Color(0x', 'lib/', 'read ShedTokens — #97'),
  // Also matches Colors.transparent, and that is intended: context.tokens owns
  // every colour including the absent one. Do not add an exemption; add a token.
  ('token.material_color', 'Colors.', 'lib/', 'read ShedTokens — #97'),
  ('a11y.scale_factor', 'textScaleFactor', 'lib/', 'deprecated; never clamp — #99'),
  ('a11y.header_bool', 'header: true', 'lib/', 'no-op since 3.44 — use headingLevel — #104'),
  ('gesture.dismissible', 'Dismissible(', 'lib/', 'gesture ban — #101'),
  ('gesture.draggable', 'Draggable(', 'lib/', 'gesture ban — #101'),
  // A tooltip is a long-press affordance on touch, and long-press is banned, so
  // the widget is banned. 00-README §2.2 and CLAUDE.md list the same three.
  ('gesture.tooltip', 'Tooltip(', 'lib/', 'gesture ban — #101'),

  // -- time: one clock (#46, R23) and no SQL-side time (#47) ----------------
  // An empty prefix means BOTH scanned roots and nothing else — `tool/` is never
  // walked. 12 §5: the rule scans test/ too, because a test that reads the real
  // clock depends on the day it runs. Two rows with one id would be the
  // duplicate R54 forbids; one row scoped lib/ would leave the whole test tier
  // reading wall-clock time.
  //
  // The exemption, lib/core/time/app_clock.dart, is a file that does not exist
  // until N04. The rule is live from this commit, so the FIRST DateTime.now(
  // written anywhere in this project has to be in that file. That is the
  // intended order.
  ('time.dart_clock', 'DateTime.now(', '', 'use appNow() — #46, R23'),
  ('time.sql_now_1', "date('now')", 'lib/', 'no SQL-side time — #47'),
  ('time.sql_now_2', "datetime('now')", 'lib/', 'no SQL-side time — #47'),
  ('time.sql_now_3', 'CURRENT_TIMESTAMP', 'lib/', 'no SQL-side time — #47'),
  ('time.sql_now_4', 'CURRENT_DATE', 'lib/', 'no SQL-side time — #47'),
  ('time.sql_now_5', 'CURRENT_TIME', 'lib/', 'no SQL-side time — #47'),
  // `strftime` and a bare `datetime` are deliberately NOT rows: 01 §3.3 and
  // decision #47 both name them as the false-positive trap that gets a rule
  // weakened and then deleted.

  // -- the single writer's text half, and the stream rows that go with it ----
  // layer.single_writer's IMPORT half is in _bannedPackages (N03-T02). This is
  // the other half. One rule, two mechanisms — not two rules.
  ('db.raw_statement', 'customStatement(', 'lib/data/', 'bypasses stream tracking — rule 8'),
  ('stream.combine', 'combineLatest', 'lib/', 'torn state across drift streams — #12'),
  (
    'stream.invalidate',
    'ref.invalidate(',
    'lib/',
    'drift tracks tables; manual invalidation is a stale read — #12',
  ),
  ('stat.zero_default', '?? 0', 'lib/features/season/', 'unknown is not zero — #58'),
  ('stat.zero_default2', '?? 0', 'lib/features/flock/', 'unknown is not zero — #58'),

  // -- rp3: THIRTEEN rows (13 §2.5), spellings from 02 §2.4 ------------------
  // Every tutorial published after 2025 shows the 3.x form and the analyzer will
  // not save you: several of them COMPILE against 2.6.1 and mean something else.
  //
  // 02 §2.4's table has six more rows that are NOT rp3.*: go_router, the
  // restoration family, WillPopScope, pushNamed/onGenerateRoute, and the
  // `.select(` fresh-collection heuristic. Those are navigation and read-path
  // rules and they need a namespace CONVENTIONS §4.7 does not list — a §6
  // ruling, not a decision at the keyboard. The count here is thirteen.
  ('rp3.retry', 'retry:', '', 'Riverpod-3 only; 2.6.1 has no auto-retry — #18'),
  (
    'rp3.container_test',
    'ProviderContainer.test',
    '',
    'use ProviderContainer(…) + addTearDown — #18',
  ),
  ('rp3.tester_container', 'tester.container', 'test/', 'use UncontrolledProviderScope — #18'),
  ('rp3.is_auto_dispose', 'isAutoDispose', '', 'use the .autoDispose builder — #18'),
  (
    'rp3.mutation',
    'Mutation<',
    '',
    'Riverpod-3 experimental API; use WriteController.guard() — #18',
  ),
  ('rp3.value_or_null', '.valueOrNull', '', 'switch on the AsyncValue instead — #18'),
  ('rp3.ref_mounted', 'ref.mounted', '', '2.6.1 has no Ref.mounted; use a _disposed field — #18'),
  (
    'rp3.observer_context',
    'ProviderObserverContext',
    '',
    "the 3.x ProviderObserver signature; use 2.6.1's four-argument form — #18",
  ),
  ('rp3.state_provider', 'StateProvider', '', 'legacy; use NotifierProvider — #18'),
  ('rp3.state_notifier', 'StateNotifier', '', 'legacy; use NotifierProvider — #18'),
  ('rp3.annotation', 'riverpod_annotation', '', 'unresolvable on this stack — #18'),
  ('rp3.hooks', 'hooks_riverpod', '', 'not in this project — #18'),
  // lib/ ONLY. Overrides are a test mechanism — 02 §5.2 says production has zero
  // of them — and a row scoped to both roots would fire on test/support/harness.dart,
  // which is built entirely out of overrideWith. Get this wrong and the harness
  // is unwritable at N12.
  ('rp3.overrides', 'overrideWith', 'lib/', 'production has zero overrides — 02 §5.2, #18'),
];

/// CONVENTIONS §5.3 and `CLAUDE.md`, verbatim. **The only place a banned word is
/// written down**; both vocabulary rows build their patterns from it, so adding
/// one is a one-line change.
const List<String> kBannedWords = <String>[
  'draft',
  'isDirty',
  'commit(',
  'submit(',
  'pending',
  'sync',
  'synchronized',
  'offline-first',
  'flags',
];

/// The subset of [kBannedWords] that **cannot** false-positive in Dart source.
///
/// `sync` is the one this project already documented once and then nearly wrote
/// anyway: a substring row for it fires on `existsSync(`, `readAsLinesSync()`,
/// `listSync(`, `asyncMap`, `Future.sync` and the `sync*` generator keyword —
/// which is to say, on this file's own driver. `01 §3.3` names the shape
/// exactly, about `strftime`: they false-positive on legitimate code and get
/// weakened. So the full list runs over the **ARB**, where `existsSync` cannot
/// appear, and this subset runs over Dart. Two scopes, one word list.
const List<String> _dartSafeBannedWords = <String>[
  'draft',
  'isDirty',
  'commit(',
  'submit(',
  'pending',
  'synchronized',
  'offline-first',
  'flags',
];

/// The phrasings that may never appear in shipped copy. Decision-record §3.1's
/// paragraph is the only permitted public wording.
///
/// `13 §2.1` scopes this to `lib/` **and `assets/`** — not to `test/`, which the
/// backlog's empty scope would have meant. `test/policy/offline_wording_test.dart`
/// legitimately contains every one of these strings, because banning a phrase
/// and claiming it are different things. `assets/` is not a walked root yet;
/// N06-T11 lands `assets/content/` and widens `_roots` with the same reason.
const List<String> _tier3Claims = <String>['your data never leaves your phone', 'offline-first'];

/// Same tuple, a pattern instead of a literal — the same driver, the same
/// allowlist keys (`'<path> :: <id>'`) and the same exit code. `final`, not
/// `const`: RegExp has no const constructor.
///
/// Grouped as `06 §3.5` groups them. **There is no `design` namespace** —
/// CONVENTIONS §4.7 lists seventeen and `design` is not among them. The plan's
/// shorthand (`design.raw_hex`, `design.magic_size`) would mean the id in an
/// `[exempt]` line never matches the id in this table, and R54 exists because a
/// duplicated rule is a rule that gets weakened twice.
final List<(String, RegExp, String, String)> _bannedPattern = <(String, RegExp, String, String)>[
  // -- tokens ---------------------------------------------------------------
  (
    'token.raw_color_ctor',
    RegExp(r'Color\.from(ARGB|RGBO)\('),
    'lib/',
    'raw colour literal — read ShedTokens — #97',
  ),
  (
    'token.seeded_scheme',
    RegExp(r'ColorScheme\.fromSeed'),
    'lib/',
    'generated scheme; 3.41 changed four on*Container roles — #94',
  ),
  (
    'token.literal_font_size',
    RegExp(r'fontSize:\s*[0-9]'),
    'lib/',
    'literal fontSize — use a TextTheme role — 06 §5.1',
  ),
  // Two rows for one idea, because the tuple carries a single path prefix and
  // the idea spans two. Do NOT merge them into one row with a widened scope:
  // lib/core/ui/theme.dart and lib/core/ui/palettes.dart legitimately build a
  // ColorScheme and would fire.
  (
    'token.color_scheme_read',
    RegExp(r'\bcolorScheme\b'),
    'lib/features/',
    'widgets read ShedTokens, not ColorScheme — 06 §3.3',
  ),
  (
    'token.color_scheme_read_ui',
    RegExp(r'\bcolorScheme\b'),
    'lib/core/ui/components/',
    'components read ShedTokens, not ColorScheme — 06 §3.3',
  ),
  (
    'token.primitives_import',
    RegExp(r'''import\s+['"][^'"]*core/ui/primitives\.dart'''),
    'lib/',
    'primitives are private to lib/core/ui/ — 06 §3.1',
  ),
  // The negative lookahead IS the rule. `(?![01](?:\.0+)?\s*[,)])` lets
  // EdgeInsets.all(0) and SizedBox(height: 1) through while catching
  // SizedBox(height: 12). Simplify it — "surely [0-9] is enough" — and every
  // hairline divider and every zero inset becomes a violation, the rule earns an
  // exemption per file, and within a month it is dead.
  //
  // It fires on the LITERAL form only: SizedBox(height: kGap) passes, which is
  // the point. What it therefore misses — `_gap * 2.5`, an opacity literal, an
  // alpha inside withValues — is a reviewer's job and not a row
  // (CODE-REVIEW-CHECKLIST §1.7).
  (
    'token.magic_size',
    RegExp(
      r'(EdgeInsets\.\w+\(|SizedBox\(|BoxConstraints\(|Size\(|'
      r'(?:Border)?Radius\.circular\(|'
      r'(?:width|height|minWidth|minHeight|maxWidth|maxHeight|spacing|'
      r'strokeWidth|elevation|letterSpacing):)'
      r'\s*(?![01](?:\.0+)?\s*[,)])[0-9]',
    ),
    'lib/',
    'magic size — use the spacing or tap scale — 06 §3.2',
  ),

  // -- themes ---------------------------------------------------------------
  ('theme.mode', RegExp(r'ThemeMode\.(system|light)'), 'lib/', 'no light theme exists — 06 §2.1'),
  ('theme.brightness', RegExp(r'Brightness\.light'), 'lib/', 'no light theme exists — 06 §2.1'),
  (
    'theme.platform_brightness',
    RegExp(r'platformBrightnessOf'),
    'lib/',
    'the OS brightness never changes this app — 06 §2.1',
  ),
  (
    'theme.light_factory',
    RegExp(r'ColorScheme\.light|ThemeData\.light'),
    'lib/',
    'no light theme exists — 06 §2.1',
  ),
  (
    'theme.deprecated_scheme_role',
    RegExp(r'\b(background|onBackground|surfaceVariant):'),
    'lib/core/ui/',
    'deprecated ColorScheme role — 06 §2.3',
  ),

  // -- typography -----------------------------------------------------------
  (
    'type.google_fonts',
    RegExp(r'\bGoogleFonts\b|google_fonts'),
    'lib/',
    'runtime font fetch is a network path — 06 §5.2',
  ),
  (
    'type.clamp',
    RegExp(r'withClampedTextScaling|TextScaler\.clamp'),
    'lib/',
    'never clamp text scale — #99',
  ),
  (
    'type.weight_cap',
    RegExp(r'FontWeight\.w(8|9)00|FontWeight\.(black|extraBold)'),
    'lib/',
    'w800/w900 render LIGHTER under Bold Text (flutter#139712) — 06 §5.3',
  ),
  (
    'type.fitted_box',
    RegExp(r'\bFittedBox\b'),
    'lib/',
    'FittedBox undoes the user text size — 06 §5.5',
  ),

  // -- gestures (06 §7) -----------------------------------------------------
  (
    'gesture.long_press_draggable',
    RegExp(r'\bLongPressDraggable\b'),
    'lib/',
    'banned gesture — #101',
  ),
  (
    'gesture.interactive_viewer',
    RegExp(r'\bInteractiveViewer\b|\bReorderableListView\b'),
    'lib/',
    'banned gesture — #101',
  ),
  (
    'gesture.refresh',
    RegExp(r'\bRefreshIndicator\b'),
    'lib/',
    'pull-to-refresh: there is nothing to refresh — 06 §7',
  ),
  (
    'gesture.long_press',
    RegExp(r'onLongPress(Start|End|MoveUpdate)?:'),
    'lib/',
    'long-press-only is banned — 06 §7',
  ),
  (
    'gesture.scale',
    RegExp(r'onScale(Start|Update|End):|onForcePress'),
    'lib/',
    'pinch / force touch — 06 §7',
  ),
  (
    'gesture.drag',
    RegExp(r'on(Horizontal|Vertical|Pan)Drag(Start|Update|End):'),
    'lib/',
    'drag — 06 §7',
  ),
  (
    'gesture.drag_handle',
    RegExp(r'showDragHandle:\s*true'),
    'lib/',
    'a drag handle advertises a banned gesture — 06 §7',
  ),
  // Catches the EXPLICIT spelling only. showModalBottomSheet defaults enableDrag
  // to TRUE, so the default slips past this row. The gap is closed elsewhere and
  // is recorded here rather than discovered: ShedBottomSheet is the only overlay
  // in the app, it is constructed in one place, and that place sets
  // enableDrag: false. ui.show_dialog holds the other half.
  (
    'gesture.sheet_drag',
    RegExp(r'enableDrag:\s*true'),
    'lib/',
    'drag-to-dismiss is a drag; sheets set enableDrag: false — 06 §7',
  ),
  (
    'gesture.slider',
    RegExp(r'\bSlider\b|\bRangeSlider\b|\bCupertinoPicker\b'),
    'lib/',
    'drag-only control; use the keypad or a Wrap of 60 pt choices — 06 §7',
  ),
  (
    'gesture.horizontal_swipe',
    RegExp(r'\bPageView\b|\bTabBarView\b'),
    'lib/',
    'horizontal swipe; vertical scrolling is the only tracked gesture — 06 §7',
  ),
  // P2 (docs/skills/02-build-manifest §4.1) SUPERSEDES CONVENTIONS §2.11, R30
  // and 06 §3.5's scope, all three of which are still on disk and all three of
  // which call feedback.dart "the one file permitted to call showSnackBar(".
  // Indelible §9 bans toasts, snackbars and modal dialogs outright, which made
  // undo-until-the-snackbar-is-dismissed unimplementable — so Indelible won. The
  // confirmation IS the committed row, in ink, one line above the one being
  // written; undo is a time-boxed strike in that row's margin, its window stated
  // in seconds. feedback.dart is no longer a legitimate call site, so this row is
  // scoped lib/ and has NO allowlist entry, ever.
  (
    'gesture.raw_snackbar',
    RegExp(r'showSnackBar\('),
    'lib/',
    'the receipt is the committed row — P2, indelible §9',
  ),

  // -- semantics (10-accessibility-and-i18n.md) -----------------------------
  // 10 §10 records this as a live defect: as 06 §3.5 prints it the pattern is
  // `SemanticsService\.announce`, which does NOT match sendAnnouncement — while
  // 10 §3.8 bans both spellings and 10 §11 row 2 claims the gate catches both.
  // As printed, the claim is false and the Android no-op ships. Widened here.
  (
    'a11y.announce',
    RegExp(r'SemanticsService\.(announce|sendAnnouncement)\b'),
    'lib/',
    'no-op on Android — use a liveRegion — #103',
  ),
  (
    'a11y.sort_key',
    RegExp(r'\bOrdinalSortKey\b|sortKey:'),
    'lib/',
    'reading order is the tree — 10 §10',
  ),
  (
    'a11y.merge_semantics',
    RegExp(r'\bMergeSemantics\b'),
    'lib/',
    'a merged node loses the per-element target — 10 §10',
  ),
  // Grouped with the gesture ban rather than with accessibility: the dial is a
  // drag, the keyboard mode is the system IME, and the cells are under 60 pt.
  (
    'a11y.material_picker',
    RegExp(r'showDatePicker\(|showTimePicker\('),
    'lib/',
    'the shepherd enters a date on the keypad, never on a dial — 10 §10',
  ),

  // -- rows CONVENTIONS §4.7 adds that no document had ----------------------
  (
    'ui.spinner',
    RegExp(r'\bCircularProgressIndicator\b'),
    'lib/features/',
    'a spinner is a screen that has not decided what it is — CONVENTIONS §4.7',
  ),
  // Two files will be allowlisted — delete-season (N29) and restore-from-backup
  // (N23). Neither exists yet, so the rule has no exemption at all, which is
  // correct: the exemptions arrive with the files, in the commits that need them.
  (
    'ui.show_dialog',
    RegExp(r'showDialog\('),
    'lib/',
    'the only overlay is ShedBottomSheet — CONVENTIONS §4.7',
  ),

  // -- vocabulary (CONVENTIONS §5) ------------------------------------------
  // Word-anchored and case-sensitive, or `\bpending\b` would eat
  // `pendingRequests` and `\bflags\b` would eat `flagsFor`. The three that are
  // not bare words — `commit(`, `submit(`, `offline-first` — are escaped, not
  // anchored, because `(` and `-` are not word characters.
  (
    'copy.banned_word',
    RegExp(_dartSafeBannedWords.map(_wordPattern).join('|')),
    'lib/',
    'one word per concept — CONVENTIONS §5',
  ),
  // A CLASS-DECLARATION rule, not a word ban. A bare `Error` fires on
  // StateError, ArgumentError, FlutterError.onError and ErrorWidget.builder,
  // every one of which is the framework's and every one of which this app
  // legitimately names — 01 §5.5 installs FlutterError.onError in main().
  (
    'type.error_name',
    RegExp(r'class\s+\w*Error\b'),
    'lib/',
    'Error is never a failure-type name; the failure types are sealed — CONVENTIONS §5.3',
  ),
  // Repositories are event verbs. This is what makes "there is no
  // save(aggregate) anywhere, so there is no aggregate in which a draft could be
  // deferred" mechanical rather than aspirational (00-README §2.4). It also
  // fires on saveAs(, savePoint( and savedAt, which is why it is scoped to
  // lib/data/ and no wider.
  (
    'db.save_verb',
    RegExp(r'\bsave\w*\('),
    'lib/data/',
    'repositories are event verbs; there is no save(aggregate) — CONVENTIONS §4.7',
  ),
  (
    'copy.tier3_claim',
    RegExp(_tier3Claims.map(RegExp.escape).join('|'), caseSensitive: false),
    'lib/',
    'only decision-record §3.1 wording is permitted — 13 §2.1',
  ),
];

/// A word-anchored pattern for one banned word, escaped.
///
/// `\b` only applies where the neighbouring character is a word character, so
/// `commit(` and `offline-first` get a leading boundary and no trailing one.
String _wordPattern(String word) {
  final String escaped = RegExp.escape(word);
  final String lead = RegExp(r'^\w').hasMatch(word) ? r'\b' : '';
  final String tail = RegExp(r'\w$').hasMatch(word) ? r'\b' : '';
  return '$lead$escaped$tail';
}

/// Every rule id this script can emit, in declaration order. N03-T07's
/// inventory assertion iterates this; a rule that is not here cannot be proved.
Iterable<String> get policyRuleIds sync* {
  yield* _layerRuleIds;
  yield 'layer.import';
  for (final (String id, _, _, _) in _bannedText) {
    yield id;
  }
  for (final (String id, _, _, _) in _bannedPattern) {
    yield id;
  }
}

/// Every text and pattern rule as (id, the path prefix it applies under).
///
/// Exposed for one assertion and one only: **no rule's scope may be
/// `pubspec.lock`.** A rule that reads the lockfile for `http` is unsatisfiable
/// — see [_bannedText] — and a comment cannot stop a future contributor writing
/// one. A test can.
Iterable<(String, String)> get policyRuleScopes sync* {
  for (final (String id, _, String under, _) in _bannedText) {
    yield (id, under);
  }
  for (final (String id, _, String under, _) in _bannedPattern) {
    yield (id, under);
  }
}

/// `import` and `export` alike. A re-export moves a symbol across a layer
/// boundary exactly as an import does, which is what makes `lib/data/models.dart`
/// (R20, the one file that re-exports every drift row type) a legal
/// concentration point rather than a hole.
///
/// Configurable imports — `import '…' if (dart.library.io) '…'` — are not
/// matched. There are none in this project and none is permitted.
final RegExp _directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

/// Null for anything outside `lib/` — layer direction does not apply there. The
/// test tier is allowed to reach the database.
String? _layerOf(String path) {
  for (final String layer in _layers) {
    if (path.startsWith(layer)) {
      return layer;
    }
  }
  return null;
}

/// `'lib/features/flock/flock_screen.dart'` + `'../../data/models.dart'`
///   → `'lib/data/models.dart'`.
///
/// `..` pops a segment and does not clamp at the root: a path with more `..`
/// than depth escapes `lib/`, resolves to no layer and is skipped. The analyzer
/// rejects such an import anyway, so this is recorded rather than guarded.
String _resolveRelative(String from, String uri) {
  final List<String> parts = from.split('/')..removeLast();
  for (final String segment in uri.split('/')) {
    if (segment.isEmpty || segment == '.') {
      continue;
    }
    if (segment == '..') {
      if (parts.isNotEmpty) {
        parts.removeLast();
      }
    } else {
      parts.add(segment);
    }
  }
  return parts.join('/');
}

/// Which of CONVENTIONS §1.1's ids a banned **package** import is reported under.
///
/// Rule 8 is the writer ban and it is keyed on the package, not the layer:
/// `package:sqlite3` anywhere outside `lib/data/` and `lib/core/db/` is
/// `layer.single_writer`. Rule 4 is likewise keyed on the package. Everything
/// else is the importing layer's own id.
String _packageRuleId(String layer, String package) {
  if (package.startsWith('package:sqlite3')) {
    return 'layer.single_writer';
  }
  if (layer == 'lib/data/' && package.startsWith('package:flutter/')) {
    return 'layer.data_no_material';
  }
  return _directionRuleId[layer]!;
}

/// 00-README §7.3: everything generated is named so you can see it, and the
/// gate always skips it. Never hand-edit one; `make gen` is the only writer.
///
/// Three of the four shapes are not `*.g.dart`. `app_localizations*.dart` comes
/// from gen-l10n and holds user-facing strings the vocabulary rules would fire
/// on; `test/drift/generated/**` comes from `drift_dev schema steps` and holds
/// generated SQL. All four are committed (00-README §7.1) and all four are
/// walked by a driver that only checks two suffixes.
bool _isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.drift.dart') ||
    path.contains('/app_localizations') ||
    path.contains('test/drift/generated/');

/// The file kinds the gate reads.
///
/// `.arb` joined `.dart` at N03-T06: `10 §10(a)` records that a walker which
/// skips everything but Dart leaves the vocabulary rows with nothing to run
/// against, because every user-facing string in this project is in
/// `lib/l10n/app_en.arb`.
bool _isScannable(String path) => path.endsWith('.dart') || path.endsWith('.arb');

/// Every file the gate will read under [root], as repository-relative paths,
/// **sorted**.
///
/// `Directory.listSync(recursive: true)` returns filesystem order, which
/// differs between macOS and the `ubuntu-latest` runner. Sorting here rather
/// than only sorting the violations means the walk itself is reproducible, so a
/// future short-circuit cannot make the first reported message machine-dependent.
List<String> scannedFiles(String root) {
  final List<String> out = <String>[];
  for (final String name in _roots) {
    final Directory dir = Directory(_join(root, name));
    if (!dir.existsSync()) {
      continue;
    }
    for (final FileSystemEntity entity in dir.listSync(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      final String path = _relative(entity.path, root);
      if (!_isScannable(path) || _isGenerated(path)) {
        continue;
      }
      out.add(path);
    }
  }
  return out..sort();
}

/// Pure. Walks [root], applies every rule, returns one message per violation.
/// Never prints and never exits — `main()` owns the process.
///
/// Throws [PolicyConfigProblem] if the gate cannot read its own configuration.
List<String> runPolicy({String root = '.'}) {
  final Map<String, Set<String>> allow = readAllowlist(root);
  final Set<String> exempt = allow['exempt'] ?? const <String>{};
  final List<String> violations = <String>[];

  for (final String path in scannedFiles(root)) {
    final String source = File(_join(root, path)).readAsStringSync();

    if (path.endsWith('.arb')) {
      violations.addAll(_checkArb(path, source, exempt));
      continue;
    }

    for (final (String id, String text, String under, String why) in _bannedText) {
      if (!path.startsWith(under) || !source.contains(text)) {
        continue;
      }
      if (exempt.contains('$path :: $id')) {
        continue;
      }
      violations.add('[$id] $path contains "$text" — $why');
    }

    for (final (String id, RegExp pattern, String under, String why) in _bannedPattern) {
      if (!path.startsWith(under) || !pattern.hasMatch(source)) {
        continue;
      }
      if (exempt.contains('$path :: $id')) {
        continue;
      }
      violations.add('[$id] $path matches ${pattern.pattern} — $why');
    }

    violations.addAll(_checkImports(path, source, exempt));
  }

  violations.addAll(_checkLockfile(allow, root: root));
  return violations..sort();
}

/// The lockfile's three dependency kinds → the allowlist section each is checked
/// against. They are **separate lists**, not one list read three times:
/// `build_runner` legitimately drags `shelf` and `web_socket_channel` into the
/// graph as dev-only, and an undifferentiated allowlist fails on day one.
const Map<String, String> _sectionFor = <String, String>{
  'direct main': 'dependencies',
  'direct dev': 'dev_dependencies',
  'transitive': 'transitive',
};

/// Two spaces, and the line must **end** at the colon.
///
/// That anchor is why the `sdks:` block at the foot of the lockfile is skipped
/// for free: its entries carry a value on the same line (`dart: ">=3.12.0 …"`),
/// so they never match. Loosen it and the gate starts reporting `dart` and
/// `flutter` as unknown packages.
final RegExp _lockPackage = RegExp(r'^  ([a-z0-9_]+):$');

/// Four spaces, exactly. A lockfile written by a different pub version with
/// different indentation would match nothing and G2 would pass on everything —
/// which is why `test/policy/gate_rules_test.dart` asserts the parser finds a
/// plausible count on the real `pubspec.lock`.
final RegExp _lockKind = RegExp(r'^    dependency: "?([a-z ]+)"?$');

/// G2. Parses `pubspec.lock` by hand — no YAML package, because the gate has no
/// dependencies (#9, #10).
///
/// It reads a committed file, so it is only as good as the commit discipline
/// around it: `13 §1.2` makes a lockfile diff in a pull request that does not
/// also change `pubspec.yaml` a **review stop** — something upstream moved and
/// you are about to ship it. G2 cannot see that; a reviewer can.
List<String> _checkLockfile(Map<String, Set<String>> allow, {required String root}) {
  final Map<String, String> kinds = lockfileKinds(root);
  return <String>[
    for (final MapEntry<String, String> entry in kinds.entries)
      if (!(allow[_sectionFor[entry.value] ?? ''] ?? const <String>{}).contains(entry.key))
        '[dep.${entry.value.replaceAll(' ', '_')}] ${entry.key} is ${entry.value} and is not on '
            'the allowlist — read its pubspec, confirm it opens no socket and merges no '
            'permission, then add it to tool/policy_allowlist.txt',
  ];
}

/// Every package in `<root>/pubspec.lock`, as name → dependency kind.
///
/// Exposed so a test can assert the parser found a plausible count: "parsed zero
/// packages" must fail loudly rather than pass quietly. A missing lockfile is a
/// [PolicyConfigProblem] and so exit 2 — it means `flutter pub get` has not run,
/// and a gate that reports clean because it could not find its input is worse
/// than no gate.
Map<String, String> lockfileKinds(String root) {
  final File lock = File(_join(root, 'pubspec.lock'));
  if (!lock.existsSync()) {
    throw const PolicyConfigProblem('pubspec.lock is missing — run `flutter pub get`');
  }
  final Map<String, String> kinds = <String, String>{};
  String? current;
  for (final String line in lock.readAsLinesSync()) {
    final RegExpMatch? package = _lockPackage.firstMatch(line);
    if (package != null) {
      current = package.group(1);
      continue;
    }
    final RegExpMatch? kind = _lockKind.firstMatch(line);
    if (kind != null && current != null) {
      kinds[current] = kind.group(1)!;
    }
  }
  return kinds;
}

/// The vocabulary rules over one ARB file.
///
/// A **separate reader** from the Dart one, and deliberately so. JSON has no
/// adjacent-string-literal problem, so `05 §7.3`'s join-before-matching rule
/// applies to the Dart half only and must not be copied here, where it would
/// concatenate unrelated messages and invent matches that span two strings.
///
/// The `@`-prefixed entries are metadata. Scanning them makes every
/// `description` — which `10 §8` requires on every string — a false positive on
/// its own explanatory prose: the description of a message about a draft has to
/// be able to say so.
///
/// The **full** [kBannedWords] list runs here, `sync` included, because
/// `existsSync` cannot appear in an ARB message.
List<String> _checkArb(String path, String source, Set<String> exempt) {
  final List<String> violations = <String>[];
  for (final (String key, String value) in _arbMessages(source)) {
    for (final String word in kBannedWords) {
      if (!RegExp(_wordPattern(word), caseSensitive: false).hasMatch(value)) {
        continue;
      }
      if (exempt.contains('$path :: copy.banned_word')) {
        continue;
      }
      violations.add('[copy.banned_word] $path: message "$key" contains "$word" — CONVENTIONS §5');
    }
    for (final String claim in _tier3Claims) {
      if (!value.toLowerCase().contains(claim)) {
        continue;
      }
      violations.add(
        '[copy.tier3_claim] $path: message "$key" claims "$claim" — '
        'only decision-record §3.1 wording is permitted',
      );
    }
  }
  return violations;
}

/// The non-metadata messages of an ARB file, as (key, value).
///
/// Hand-rolled, because the gate has no dependencies and an ARB message is one
/// JSON string on one line in every file this project writes. A key beginning
/// `@` is metadata and is skipped.
/// Only entries at the **top level** are messages. Depth matters: `description`
/// lives one level down, inside an `@`-prefixed object, and it does not begin
/// with `@` itself — so a scan that only skipped `@` keys would read every
/// description as a message and fire on its own explanatory prose.
Iterable<(String, String)> _arbMessages(String source) sync* {
  final RegExp entry = RegExp(r'^\s*"([^"]+)"\s*:\s*"((?:[^"\\]|\\.)*)"');
  int depth = 0;
  for (final String line in source.split('\n')) {
    final int opens = '{'.allMatches(line).length;
    final int closes = '}'.allMatches(line).length;
    final RegExpMatch? match = entry.firstMatch(line);
    // Depth BEFORE this line's braces: a top-level entry sits at depth 1.
    if (depth == 1 && match != null) {
      final String key = match.group(1)!;
      if (!key.startsWith('@')) {
        yield (key, match.group(2)!);
      }
    }
    depth += opens - closes;
  }
}

/// The layer rules, for one file. CONVENTIONS §1.1.
List<String> _checkImports(String path, String source, Set<String> exempt) {
  final List<String> violations = <String>[];
  final String? layer = _layerOf(path);

  for (final RegExpMatch match in _directive.allMatches(source)) {
    String uri = match.group(1)!;

    for (final String banned in <String>{..._bannedEverywhere, ...?_bannedPackages[layer]}) {
      if (!uri.startsWith(banned) || exempt.contains('$path :: import:$uri')) {
        continue;
      }
      final String id = _bannedEverywhere.contains(banned)
          ? 'layer.import'
          : _packageRuleId(layer!, banned);
      violations.add('[$id] $path (${layer ?? 'test'}) may not import $uri');
    }

    // No layer direction outside lib/.
    if (layer == null) {
      continue;
    }

    if (uri.startsWith('package:$_package/')) {
      uri = 'lib/${uri.substring('package:$_package/'.length)}';
    } else if (uri.startsWith('dart:') || uri.startsWith('package:')) {
      // A package: URI that is not banned is legal — `package:collection` in
      // the domain, for one — and never reaches the direction check.
      continue;
    } else {
      uri = _resolveRelative(path, uri);
    }

    for (final (String id, String fromPrefix, String toPrefix) in _bannedPathPairs) {
      if (path.startsWith(fromPrefix) && uri.startsWith(toPrefix)) {
        violations.add('[$id] $path may not import $uri');
      }
    }

    final String? to = _layerOf(uri);
    if (to == null) {
      continue;
    }
    if (!_mayImport[layer]!.contains(to)) {
      violations.add('[${_directionRuleId[layer]}] $path ($layer) may not import $to  [$uri]');
      continue;
    }
    // Rule 6 fires only when the IMPORTING file is under lib/features/, so
    // routing may name all nine features and a feature still may not name a
    // sibling. The asymmetry is deliberate (01 §3.1).
    if (layer == 'lib/features/' && to == 'lib/features/') {
      final String a = path.split('/')[2];
      final String b = uri.split('/')[2];
      if (a != b) {
        violations.add(
          '[layer.sibling] $path: feature "$a" may not import feature "$b" — '
          'move the shared piece into lib/data/ or lib/domain/',
        );
      }
    }
  }
  return violations;
}

/// Parses `<root>/tool/policy_allowlist.txt`.
///
/// `[section]` headers, one entry per line, `#` starts a comment. Throws
/// [PolicyConfigProblem] on a malformed line, naming the file and the 1-based
/// line number; `main()` turns that into exit 2.
///
/// `[exempt]` keys are **normalised** to `'<path> :: <id>'`. The file is
/// column-aligned for readability and the driver looks the key up unpadded, so
/// storing the raw line makes every exemption ever written silently inert — the
/// gate goes red on a file that carries a waiver, somebody deletes the rule, and
/// nobody sees it happen.
Map<String, Set<String>> readAllowlist(String root) {
  const String name = 'tool/policy_allowlist.txt';
  final File file = File(_join(root, name));
  if (!file.existsSync()) {
    throw const PolicyConfigProblem('$name is missing — the gate cannot run');
  }
  final Map<String, Set<String>> out = <String, Set<String>>{
    for (final String section in _allowlistSections) section: <String>{},
  };
  String? section;
  final List<String> lines = file.readAsLinesSync();
  for (int i = 0; i < lines.length; i++) {
    final String line = lines[i].split('#').first.trim();
    final int number = i + 1;
    if (line.isEmpty) {
      continue;
    }
    if (line.startsWith('[') && line.endsWith(']')) {
      section = line.substring(1, line.length - 1);
      if (!_allowlistSections.contains(section)) {
        throw PolicyConfigProblem(
          '$name line $number: unknown section "$section". '
          'The four are ${_allowlistSections.join(", ")}',
        );
      }
      continue;
    }
    if (line.startsWith('[')) {
      // Opens like a header and does not close like one. Almost always a header
      // that has had text appended to it — which the parser would otherwise
      // accept as an ENTRY in whatever section came before, silently. Found by
      // exactly that accident on 2026-08-01, in this file's own allowlist.
      throw PolicyConfigProblem(
        '$name line $number: "$line" opens a section header and does not close it',
      );
    }
    if (section == null) {
      throw PolicyConfigProblem(
        '$name line $number: "$line" is outside any section. '
        'Every entry belongs under one of ${_allowlistSections.join(", ")}',
      );
    }
    out[section]!.add(section == 'exempt' ? _exemptKey(name, number, line) : line);
  }
  return out;
}

String _exemptKey(String name, int number, String line) {
  final List<String> halves = line.split('::');
  if (halves.length != 2) {
    throw PolicyConfigProblem(
      '$name line $number: "$line" is not `<path> :: <rule id>`. '
      'A waiver with no :: separator is refused, never ignored',
    );
  }
  return '${halves.first.trim()} :: ${halves.last.trim()}';
}

/// The gate could not run. Deliberately not named `…Error`: `CLAUDE.md` bans
/// `Error` as a failure-type name, and this is a configuration problem the gate
/// reports, not a failure type the app models.
final class PolicyConfigProblem implements Exception {
  const PolicyConfigProblem(this.message);
  final String message;

  @override
  String toString() => 'PolicyConfigProblem: $message';
}

String _join(String root, String path) => root == '.' ? path : '$root/$path';

String _relative(String path, String root) {
  final String normalised = path.replaceAll(r'\', '/');
  final String prefix = root == '.' ? '' : '$root/';
  return normalised.startsWith(prefix) ? normalised.substring(prefix.length) : normalised;
}

void main(List<String> args) {
  final List<String> violations;
  try {
    violations = runPolicy();
  } on PolicyConfigProblem catch (problem) {
    stderr.writeln('POLICY  ${problem.message}');
    exit(2);
  }
  if (violations.isEmpty) {
    stdout.writeln('policy ok');
    return;
  }
  for (final String line in violations) {
    stderr.writeln('POLICY  $line');
  }
  exit(1);
}
