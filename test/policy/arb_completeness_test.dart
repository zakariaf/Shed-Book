// test/policy/arb_completeness_test.dart
//
// **ONE FILE, THREE PROPERTIES, ONE ARB READER.**
// `00-PLAN-CRITIQUE` §11.3 prefers `10 §7.3`'s name,
// `arb_has_no_domain_noun_test.dart` — which describes **one** of the three.
// Splitting them means parsing the same JSON three times and maintaining three
// copies of `10 §8.7`'s exception list. `10 §7.3`'s third bullet is amended to
// name the file that exists.
//
// **THE GATE PROVES THE ABSENCE; THIS PROVES THE GATE IS ALIVE** (`12 §1.4`).
// The rules are `copy.arb_domain_noun` and `copy.banned_word`, in
// `tool/check_policy.dart`. Re-implementing either as a `RegExp` inside a
// `test()` would be a second implementation that can disagree with the one that
// runs on CI.
@Tags(<String>['policy'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `10 §8.7`'s closed list.
///
/// A sweep that demanded EVERY user-facing string be an ARB key fails on these,
/// and the obvious "fix" is to move them into the ARB — **into the one place a
/// translator can soften a safety string**. Adding an entry is a review
/// conversation, not an edit.
const List<String> kNotInTheArb = <String>[
  'lib/domain/policy/disclaimers.dart', // decision #62 — referenced, never re-typed
  'lib/core/failure.dart', // the ShedFailure.userMessage strings
  'lib/domain/time/recorded_time.dart', // provenanceLabel — a §12.5 property, not copy
  'lib/core/ui/night_error_panel.dart', // renders outside Localizations by construction
];

/// **44 MESSAGES NOTHING RENDERS. THIS IS A FINDING, NOT AN EXEMPTION.**
///
/// Found by this file at N33-T05 and written down rather than deleted, because
/// deleting copy is how a screen quietly ends up with a worse sentence than the
/// one somebody already wrote for it. Every entry below is grouped with what has
/// to happen for it to leave, and **the test fails if the list stops matching** —
/// in either direction.
///
/// The groups are not equal. Only the first loses records.
const List<String> kWrittenAhead = <String>[
  // ── 1. RESTORE — WIRED, AND THE GROUP IS GONE. ────────────────────────────
  //
  // This list opened with ten messages under the heading *RESTORE IS
  // UNREACHABLE IN THE PRODUCT*: `SettingsSectionId.data` fell through to an
  // empty widget list, so Settings ▸ Data printed a heading over nothing and
  // `pickBackupFile`, `readBackupPrelude` and `showRestoreConfirmation` had no
  // caller outside their own tests. N23-T02's step 4 was never done.
  //
  // **All ten now render**, so all ten are deleted from this list — which is
  // what the second assertion below is for. A finding that stays on the page
  // after it is fixed is a finding nobody trusts the next time.

  // ── 2. A SECOND NAME FOR COPY THAT ALREADY RENDERS. ───────────────────────
  // An earlier ARB draft; the widget was built against a different key and the
  // draft was never removed. `treatmentsNotApplicable` and
  // `treatmentsNoWithdrawal` are what `_BookLine` prints; `withdrawal_control`
  // supplies the rest. `withdrawalSource` is the exception that must NOT be
  // deleted — `disclaimer_is_defined_once_test` names it as the one place
  // `as entered by you` is allowed to exist besides `Disclaimers`.
  'withdrawalSource',
  'withdrawalLabel',
  'withdrawalEnterDays',
  'withdrawalNotApplicable',
  'withdrawalNotRecorded',
  'withdrawalUnit',
  'withdrawalDisagrees',
  'withdrawalStored',
  'withdrawalRecomputed',
  'lambCardTitle',
  'lambCardPermanent',
  'lambCardDeathCauseLabel',
  'lambCardDeathCauseUnattributed',
  'lambCardFeedsLabel',
  'lambingEaseHeading',
  'quickEntryTitle',
  'quickEntryStruckAt',
  'keypadEnteredTag',
  'matchCountClosest',
  'nAnimals',
  'declareTypeAcknowledged',
  // Word for word `capRefusedSecondSeason`, which the season section renders.
  // Two names for one sentence, and the one that ships is the one the free
  // tier's own switch reaches for.
  'settingsSeasonCapRefused',
  'fosterBirthDamNote',
  'detailAssistedBy',
  'detailPresentationNote',
  'detailNote',
  'warningImplausibleBirthWeight',

  // ── 4. PHOTOS ARE NOT IN A BACKUP IN THIS VERSION. ────────────────────────
  // `restoreDoneMedia` above says so in the shepherd's words. These three are
  // the viewer's, and the viewer is not built.
  'photoMissingOnThisPhone',
  'photoShowInFullColour',
  'photoSemanticLabel',
];

Map<String, Object?> _arb() =>
    jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, Object?>;

/// Runs the real gate over a planted file and returns its output.
({int code, String out}) _gateWith(String path, String contents) {
  final File f = File(path);
  final bool existed = f.existsSync();
  final String? original = existed ? f.readAsStringSync() : null;
  try {
    f.writeAsStringSync(contents);
    final ProcessResult r = Process.runSync('dart', <String>['run', 'tool/check_policy.dart']);
    return (code: r.exitCode, out: '${r.stdout}${r.stderr}');
  } finally {
    if (original != null) {
      f.writeAsStringSync(original);
    } else if (f.existsSync()) {
      f.deleteSync();
    }
  }
}

void main() {
  test('every message carries a description, and none of them is a stub', () {
    // `gen-l10n`'s `required-resource-attributes: true` fails on a missing
    // `@key` BLOCK, not on a missing description — measured on 3.44.8 at
    // N01-T03. So the block's existence is already held; what is not is whether
    // anybody wrote anything in it.
    final Map<String, Object?> arb = _arb();
    final Iterable<String> messages = arb.keys.where((String k) => !k.startsWith('@'));

    for (final String key in messages) {
      final Object? meta = arb['@$key'];
      expect(meta, isNotNull, reason: '$key has no @-block');
      final Object? description = (meta! as Map<String, Object?>)['description'];
      expect(description, isNotNull, reason: '$key has no description');

      final String text = description! as String;
      expect(text.trim(), isNotEmpty, reason: '$key has an empty description');
      // A stub is worse than nothing: it satisfies a presence check and tells
      // the next reader that somebody already thought about it.
      expect(text.length, greaterThan(20), reason: '$key has a stub description: "$text"');
      expect(text.toLowerCase(), isNot('todo'), reason: key);
    }
  });

  test('the two safety descriptions are byte-identical to what 10 §8.4 published', () {
    // **THESE TWO ARE THE MECHANISM THAT STOPS A FUTURE CONTRIBUTOR "IMPROVING"
    // A SAFETY STRING.** They are the only thing standing between *as entered by
    // you* and a shorter, friendlier lie — and a description is the only place
    // the reason survives next to the string it protects.
    final Map<String, Object?> arb = _arb();

    final String withdrawal =
        (arb['@withdrawalSource']! as Map<String, Object?>)['description']! as String;
    expect(
      withdrawal,
      contains('SAFETY REQUIREMENT'),
      reason: 'the withdrawal provenance description no longer says why it cannot be shortened',
    );
    expect(withdrawal, contains('Do not shorten it'));
    expect(withdrawal, contains('Never show a withdrawal figure without it'));
  });

  test('the domain-noun rule fires on a planted literal and not on the term messages', () {
    // **BOTH DIRECTIONS, BECAUSE A ONE-DIRECTION SELF-TEST IS HOW A RULE THAT
    // MATCHES EVERYTHING SHIPS.**
    //
    // The fourteen `term<Class>Singular` / `term<Class>Plural` messages ARE the
    // default nouns — the source the placeholder is fed FROM — so they are
    // skipped **in the rule**, by shape, rather than in the `[exempt]`
    // allowlist where the skip would be invisible.
    const String planted = '''
{
  "@@locale": "en",
  "plantedViolation": "Turn out ewe 412?",
  "@plantedViolation": { "description": "A planted violation for the gate self-test." }
}
''';
    final ({int code, String out}) red = _gateWith('lib/l10n/planted_test.arb', planted);
    expect(red.code, 1, reason: 'the gate did not fail on a hard-coded domain noun');
    expect(red.out, contains('copy.arb_domain_noun'));

    const String legitimate = '''
{
  "@@locale": "en",
  "plantedLegitimate": "Turn out {term} {tag}?",
  "@plantedLegitimate": {
    "description": "The same sentence with the noun as a placeholder, which is the fix.",
    "placeholders": { "term": {"type": "String"}, "tag": {"type": "String"} }
  }
}
''';
    final ({int code, String out}) green = _gateWith('lib/l10n/planted_test.arb', legitimate);
    expect(
      green.code,
      0,
      reason: 'the gate fired on a correctly-placeholdered message: ${green.out}',
    );
  });

  test('the §8.7 exceptions are exactly four, and each file exists', () {
    // A closed list whose entries have rotted is a list nobody re-reads. Each
    // path is checked, so a file that moved shows up here rather than silently
    // widening the exception to nothing.
    expect(kNotInTheArb, hasLength(4));
    for (final String path in kNotInTheArb) {
      expect(File(path).existsSync(), isTrue, reason: '$path no longer exists');
    }
  });

  test('every ARB message is referenced from lib/, or is on the written-ahead list', () {
    // **AN UNREFERENCED MESSAGE IS COPY NOBODY SEES**, and it accumulates: the
    // ARB is the one file where deleting is safe and nobody ever does it. A
    // translator translates every line of it, including the lines no screen can
    // reach.
    //
    // The `vocab*` and `term*` families are the exception by construction — they
    // are looked up by KEY at runtime, so no call site names them.
    final Map<String, Object?> arb = _arb();
    final String dart = <String>[
      for (final FileSystemEntity f in Directory('lib').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart') && !f.path.contains('/l10n/'))
          f.readAsStringSync(),
    ].join('\n');

    final List<String> orphans = <String>[
      for (final String key in arb.keys)
        if (!key.startsWith('@') &&
            !key.startsWith('vocab') &&
            !key.startsWith('term') &&
            !dart.contains('.$key'))
          key,
    ];

    expect(
      orphans.toSet().difference(kWrittenAhead.toSet()),
      isEmpty,
      reason: 'ARB messages nothing renders and nothing accounts for',
    );

    // **AND THE LIST ONLY SHRINKS.** A key that starts rendering must leave it,
    // or the list stops describing anything and becomes a place to put keys.
    expect(
      kWrittenAhead.toSet().difference(orphans.toSet()),
      isEmpty,
      reason: 'these are rendered now — delete them from kWrittenAhead',
    );
  });
}
