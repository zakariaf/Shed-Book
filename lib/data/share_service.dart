// lib/data/share_service.dart
//
// THE ONLY ROUTE ANYTHING LEAVES THE PHONE BY, and the only `package:share_plus`
// import site in the app (`layer.plugin_share_plus`). `08 §5` calls it *"the
// highest-stakes non-database code path in the app"* for a plain reason: there
// is no *save to Files* path of our own, nothing is written to a user-visible
// folder, and nothing is opened in place.
//
// **THIS IS WHERE TIER 3 OF THE OFFLINE CLAIM ENDS.** The share sheet is another
// process. Decision-record §3.1's public wording says so in as many words —
// *"your records only leave the phone when you deliberately export and share
// them"* — and that sentence is true precisely because this file is the only
// thing that can move them.
//
// NO PLUGIN TYPE CROSSES THIS BOUNDARY IN EITHER DIRECTION (`08 §1.1`).
// [ShareOutcome] is ours; `ShareResultStatus` is the plugin's and stops here.
library;

import 'dart:ui' show Rect;

import 'package:share_plus/share_plus.dart';

/// What the OS said happened, in three states rather than a `bool`.
///
/// **The third state is why this is an enum.** `09 §8.3` writes
/// `last_exported_at` on [completed] **and** on [unknown], and never on
/// [dismissed] — so collapsing *unavailable* into either one makes the end-of-day
/// banner either a nag that never stops or a nag that lies. Getting it wrong
/// makes the app's one safety prompt useless in one direction or dishonest in
/// the other.
enum ShareOutcome {
  /// The sheet reported a completed share.
  completed,

  /// The shepherd backed out. **Nothing was exported**, so nothing is stamped.
  dismissed,

  /// The platform could not tell us. Android frequently cannot, and the honest
  /// reading is *it probably happened* — stamping here is the safer error,
  /// because the alternative nags somebody who has just exported.
  unknown,
}

/// **`interface class`, NOT `final class`** — and the modifier is the mechanism.
///
/// `12 §4.2` requires all seven gateway fakes to `implements` and never
/// `extends`, *"so that when an owning document changes a signature, the fake is
/// a compile error rather than a silent divergence."* `final` forbids
/// `implements` outside the library, so `FakeShareService` could not exist;
/// `interface` permits `implements` and forbids `extends`, which is that
/// sentence enforced by the compiler instead of by review.
///
/// The other six gateways are still `final class` and their fakes have not
/// landed yet (N15's three are named in `harness.dart` and do not exist). Each
/// will need this same modifier in the commit that writes its fake.
interface class ShareService {
  const ShareService();

  /// Always file **paths**, never bytes.
  ///
  /// The bytes-carrying `XFile` constructor is banned by decision #80 and by the
  /// gate row `share.from_data`: it hands the receiving app an in-memory blob
  /// with no name and no on-disk identity, and on Android it round-trips through
  /// a content provider that some targets silently refuse. Every artefact this
  /// app produces is written to `getTemporaryDirectory()` first and shared from
  /// there.
  ///
  /// **Its name is not spelled in this file** — the gate scans the whole source
  /// text, so a comment naming the thing it forbids fails the rule that forbids
  /// it. The ninth prohibition this project has caught matching itself.
  ///
  /// **[origin] IS REQUIRED AND NAMED**, not optional with a default. The
  /// `share_plus` README states that omitting `sharePositionOrigin` on iPad *"may
  /// cause crashes or unresponsive UI"*, and a required parameter is a better
  /// gate than a lint because it fails at compile time on the platform nobody
  /// tests on first.
  Future<ShareOutcome> shareFiles({
    required List<String> paths,
    required List<String> fileNames,
    required Rect origin,
    String? subject,
  }) async {
    if (paths.length != fileNames.length) {
      // A `throw`, not an `assert`: a name/path mismatch in release ships a file
      // called `ewes.csv` containing lambs, to somebody else's laptop.
      throw ArgumentError(
        'shareFiles: ${paths.length} paths and ${fileNames.length} names — '
        'every file is named or none is',
      );
    }

    final ShareResult result = await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[for (final String path in paths) XFile(path)],
        fileNameOverrides: fileNames,
        subject: subject,
        sharePositionOrigin: origin,
      ),
    );

    // EXHAUSTIVE, so a fourth status from a plugin bump is a compile error here
    // rather than an unstamped export at 03:20.
    return switch (result.status) {
      ShareResultStatus.success => ShareOutcome.completed,
      ShareResultStatus.dismissed => ShareOutcome.dismissed,
      ShareResultStatus.unavailable => ShareOutcome.unknown,
    };
  }
}
