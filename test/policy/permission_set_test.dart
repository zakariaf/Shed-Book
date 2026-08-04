// test/policy/permission_set_test.dart
//
// **`android/expected_permissions.txt` IS ONE OF THE TWO FILES `CLAUDE.md`
// FORBIDS EDITING TO SILENCE A GATE.** G1 compares it to `bundletool dump
// manifest` on the real release artefact and asserts **exact set equality** — so
// a red G1 is answered by deciding whether the permission belongs, never by
// adding a line here.
//
// This file asserts the other half: that the list agrees with the **record it
// was built from**, decision-record §3.3, which is the merger's own output on a
// real release `.aab` rather than a reading of any plugin's documentation.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The permission names in the expected file, normalised **exactly the way
/// `tool/assert_permissions.sh` normalises them**: strip `#` to end of line,
/// strip trailing whitespace, drop the empties.
///
/// **THE TWO NORMALISATIONS ARE THE SAME OR THE GATE IS NOT TESTING THE GATE.**
/// If this parser were more forgiving than the script's, a line the script
/// rejects would pass here and G1 would go red on CI for a reason no local test
/// could reproduce.
Set<String> normalisedNames(String path) => File(path)
    .readAsLinesSync()
    .map((String l) => l.replaceAll(RegExp('#.*'), '').trimRight())
    .where((String l) => l.trim().isNotEmpty)
    .map((String l) => l.trim())
    .toSet();

Set<String> _namesIn(String path) => normalisedNames(path);

void main() {
  test('expected_permissions.txt matches the G0 record exactly', () {
    // **A SET COMPARISON AGAINST THE DECISION RECORD**, not a hand-copied list.
    // §3.3's first fenced block is the as-built seven; the second names what is
    // removed and what `v1.1.0` adds. The file below is `v1.0.0`'s set, which is
    // the first block minus the two removals.
    final Set<String> declared = _namesIn('android/expected_permissions.txt');

    const Set<String> asBuilt = <String>{
      'android.permission.POST_NOTIFICATIONS',
      'android.permission.VIBRATE',
      'android.permission.RECORD_AUDIO',
      'com.android.vending.BILLING',
      'com.shedbook.shedbook.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION',
      'android.permission.ACCESS_NETWORK_STATE',
      'android.permission.INTERNET',
    };
    const Set<String> removedForV1 = <String>{
      'android.permission.INTERNET',
      'android.permission.POST_NOTIFICATIONS',
    };

    expect(
      declared,
      asBuilt.difference(removedForV1),
      reason: 'the file and decision-record §3.3 have drifted',
    );

    // **THE RECORD ITSELF IS READ, SO THE TWO CANNOT DIVERGE SILENTLY.** A
    // literal set in a test is a copy, and a copy defends the wrong list the
    // first time the record changes.
    final String record = File('docs/research/00-tech-decisions.md').readAsStringSync();
    for (final String name in asBuilt) {
      expect(record, contains(name), reason: '§3.3 no longer records $name');
    }
  });

  test('INTERNET is asserted by its ABSENCE, in the file and in the manifest', () {
    // **THE CLAIM IN DECISION-RECORD §3.1 RESTS ON THIS ONE LINE.** *The Android
    // build ships without the internet permission, so the app itself cannot
    // connect to anything.* It is merged by Play Billing's telemetry transport
    // on a transitive edge no README mentions, and the removal directive is what
    // makes the sentence true.
    expect(
      _namesIn('android/expected_permissions.txt'),
      isNot(contains('android.permission.INTERNET')),
      reason: 'the one permission this product is defined by not having',
    );

    final String manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(
      manifest,
      contains('android:name="android.permission.INTERNET" tools:node="remove"'),
      reason: 'the removal directive is gone — the merger will put INTERNET back',
    );
    expect(
      manifest,
      contains('xmlns:tools='),
      reason: 'tools:node without the namespace is a silent no-op',
    );
  });

  test('the three v1.1.0 adds are named in the file, not remembered', () {
    // `docs/RELEASE-SCOPE.md`: G1 going red must be answerable **from a file**
    // rather than from memory. The three names sit in the comments precisely so
    // the person reading a red build can tell *"this belongs, in the next
    // release"* from *"this should not be here at all"*.
    final String file = File('android/expected_permissions.txt').readAsStringSync();
    for (final String name in <String>[
      'android.permission.POST_NOTIFICATIONS',
      'android.permission.RECEIVE_BOOT_COMPLETED',
      'android.permission.SCHEDULE_EXACT_ALARM',
    ]) {
      expect(file, contains(name), reason: '$name is not named as a v1.1.0 add');
    }

    // And none of the three is an ACTIVE line: `v1.0.0` declares none of them.
    final Set<String> active = _namesIn('android/expected_permissions.txt');
    expect(active, isNot(contains('android.permission.RECEIVE_BOOT_COMPLETED')));
    expect(active, isNot(contains('android.permission.SCHEDULE_EXACT_ALARM')));
    expect(active, isNot(contains('android.permission.POST_NOTIFICATIONS')));
  });

  test('the file and the script normalise it the same way', () {
    // **THE NORMALISATION CONTRACT, AND IT IS THE HALF THAT FAILS ON CI
    // ONLY.** `tool/assert_permissions.sh` strips `#` to end of line, strips
    // trailing whitespace and drops the empties. If this file's parser were more
    // forgiving, a line the script rejects would pass here and G1 would go red on
    // a runner for a reason no local test could reproduce.
    //
    // Asserted by reading the script's own three transformations out of it, so
    // the two cannot drift without one of them saying so.
    final String script = File('tool/assert_permissions.sh').readAsStringSync();
    expect(script, contains("sed 's/#.*//'"));
    expect(script, contains("sed 's/[[:space:]]*\$//'"));
    expect(script, contains("grep -v '^\$'"));

    // And every normalised line is a bare permission name: no whitespace, no
    // `#`, nothing the diff would see as a difference.
    for (final String name in normalisedNames('android/expected_permissions.txt')) {
      expect(name, isNot(contains('#')), reason: name);
      expect(name.trim(), name, reason: 'untrimmed: "$name"');
      expect(name, isNot(contains(' ')), reason: 'whitespace survived: "$name"');
      expect(name, matches(RegExp(r'^[A-Za-z0-9_.]+$')), reason: name);
    }
  });

  test('the gate cannot be run into a false green', () {
    // **EXIT 2 IS "THE GATE COULD NOT RUN", AND IT IS STILL A FAILURE.** A
    // missing `bundletool` that reported success would let a permission ship
    // unseen — which is the one failure mode a gate has that is worse than not
    // existing.
    final String script = File('tool/assert_permissions.sh').readAsStringSync();
    expect('exit 2'.allMatches(script).length, greaterThanOrEqualTo(3));
    expect(script, contains('set -euo pipefail'));

    // An empty grep under `pipefail` dies silently mid-pipe. The capture-then-
    // decide shape is what turns *"no uses-permission elements at all"* into a
    // named failure.
    expect(script, contains('[ -s actual-permissions.txt ]'));

    // **DO NOT FILTER ON THE SUBSTRING "permission".** `com.android.vending.BILLING`
    // does not contain it, and it is the one entry a careless filter drops in
    // silence.
    expect(script, contains("grep '^uses-permission'"));
  });

  test('every declared permission names the manifest it was attributed to', () {
    // A permission with no attribution is a permission nobody can decide about:
    // the question *"can we remove this?"* is unanswerable without knowing which
    // dependency merged it, and that is the question every G1 failure asks.
    for (final String line
        in File('android/expected_permissions.txt')
            .readAsLinesSync()
            .map((String l) => l.trim())
            .where((String l) => l.isNotEmpty && !l.startsWith('#'))) {
      expect(line, contains('#'), reason: 'unattributed: $line');
    }
  });
}
