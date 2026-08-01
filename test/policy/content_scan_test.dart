// test/policy/content_scan_test.dart — the forty authored terms, scanned in both
// of R66's homes.
//
// tool/check_policy.dart's copy.vet_advice row is the gate half and is what
// fails a build. This file holds the counts and the shape assertions the gate's
// tuple cannot express, and it runs ContentPolicy's ten patterns singly so a
// failure names WHICH pattern and WHY rather than one joined regex.
//
// No uk-zone case: this task ships prose and nothing here computes with time.
@Tags(<String>['policy'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/policy/content_policy.dart';

/// 03 §10.1's six lists. The KEYS are frozen; only the labels were authored.
///
/// Forty exactly. If this is ever 41, somebody has added the sixth ease point
/// that decision-record §7.1 open question 15 leaves open — and that is a schema
/// CHECK change, not a content edit.
const Map<String, List<String>> kVocabLists = <String, List<String>>{
  'lambing_ease': <String>['ease_1', 'ease_2', 'ease_3', 'ease_4', 'ease_5'],
  'death_cause': <String>[
    'dc_starvation',
    'dc_hypothermia',
    'dc_watery_mouth',
    'dc_joint_ill',
    'dc_crushed',
    'dc_stillborn',
    'dc_unknown',
    'dc_other',
  ],
  'malpresentation': <String>[
    'mp_head_back',
    'mp_one_leg_back',
    'mp_both_legs_back',
    'mp_breech',
    'mp_backwards',
    'mp_twins_together',
    'mp_ringwomb',
    'mp_other',
  ],
  'treatment_route': <String>[
    'rt_subcutaneous',
    'rt_intramuscular',
    'rt_oral',
    'rt_topical',
    'rt_intranasal',
    'rt_intravenous',
    'rt_intraperitoneal',
    'rt_other',
  ],
  'ewe_observation': <String>[
    'obs_prolapse',
    'obs_mastitis',
    'obs_poor_mothering',
    'obs_good_mothering',
    'obs_no_milk',
    'obs_other',
  ],
  'foster_method': <String>['fm_wet_adopt', 'fm_skin', 'fm_crate', 'fm_bottle', 'fm_other'],
};

/// `dc_starvation` → `vocabDcStarvation`, `ease_1` → `vocabEase1`,
/// `mp_breech` → `vocabMpBreech` (10 §8.6).
String messageIdFor(String key) =>
    'vocab${key.split('_').map((String w) => w[0].toUpperCase() + w.substring(1)).join()}';

Map<String, dynamic> _arb() =>
    jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;

List<String> _vocabIds() =>
    _arb().keys.where((String k) => k.startsWith('vocab') && !k.startsWith('@')).toList()..sort();

List<String> _contentFiles() =>
    Directory('assets/content')
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => f.path.replaceAll(r'\', '/'))
        .toList()
      ..sort();

void main() {
  test('every authored term passes ContentPolicy and contains no dose, no should '
      'and no diagnosis', () {
    // BOTH homes, because R66 gives the forty terms three and the check that
    // reads only one of them misses the other. The patterns run singly so a
    // failure names which one and why.
    final Map<String, String> userFacing = <String, String>{
      for (final String id in _vocabIds()) 'ARB $id': _arb()[id] as String,
      for (final String path in _contentFiles()) path: File(path).readAsStringSync(),
    };

    expect(userFacing, isNotEmpty);

    for (final MapEntry<String, String> entry in userFacing.entries) {
      for (final ({RegExp pattern, String why}) rule in ContentPolicy.bannedInUserFacingText) {
        expect(
          rule.pattern.hasMatch(entry.value),
          isFalse,
          reason: '${entry.key} — ${rule.why} (${rule.pattern.pattern})',
        );
      }
    }
  });

  test('there are forty vocab messages, one per seeded key', () {
    // The ARB half of the count, pinned here so a missing label is caught before
    // N07-T07's parity test exists. That test —
    // test/policy/vocab_labels_are_complete_test.dart — is the SET EQUALITY
    // against the seeded keys and is N07-T07's; this is deliberately the weaker
    // half that can run today. Do not delete it later as a duplicate.
    final List<String> expected = <String>[
      for (final List<String> keys in kVocabLists.values)
        for (final String key in keys) messageIdFor(key),
    ]..sort();

    expect(expected, hasLength(40));
    expect(_vocabIds(), expected);
  });

  test('every vocab message carries a description', () {
    final Map<String, dynamic> arb = _arb();
    for (final String id in _vocabIds()) {
      final Object? meta = arb['@$id'];
      expect(meta, isA<Map<String, dynamic>>(), reason: id);
      expect((meta! as Map<String, dynamic>)['description'], isNotEmpty, reason: id);
    }
  });

  test('the ARB message ids follow vocab + upperCamel(key)', () {
    expect(messageIdFor('dc_starvation'), 'vocabDcStarvation');
    expect(messageIdFor('ease_1'), 'vocabEase1');
    expect(messageIdFor('mp_breech'), 'vocabMpBreech');
    expect(messageIdFor('rt_intraperitoneal'), 'vocabRtIntraperitoneal');
  });

  test('each of the six lists has a provenance line in assets/content/', () {
    // The artefact the "no verbatim third-party copy" check exists to protect.
    final String provenance = File('assets/content/vocabulary_provenance.md').readAsStringSync();

    for (final String list in kVocabLists.keys) {
      expect(provenance, contains(list), reason: list);
    }
    expect(
      provenance,
      contains('None that is licensed'),
      reason: "spec §11's answer, in the file that answers it",
    );
    expect(
      RegExp('authored for this app', caseSensitive: false).allMatches(provenance).length,
      greaterThanOrEqualTo(6),
      reason: 'one basis statement per list',
    );
  });

  test('no authored term names a product or a brand', () {
    // An assertion BY REVIEW with an explicit fixture list, because no regex
    // catches a brand name. The list is the shapes that would appear if somebody
    // reached for a real product while writing a route or a cause; if a term is
    // ever added that needs one of these words, that is the conversation, not an
    // allowlist line.
    const List<String> brandShapes = <String>[
      'spectam',
      'alamycin',
      'betamox',
      'orbenin',
      'heptavac',
      'ovivac',
      'crovect',
      'dectomax',
      'ivomec',
      'nuflor',
      ' mg',
      ' ml',
      'per kg',
      'dose',
      'course',
    ];

    final Iterable<String> all = <String>[
      for (final String id in _vocabIds()) (_arb()[id] as String).toLowerCase(),
    ];

    for (final String label in all) {
      for (final String brand in brandShapes) {
        expect(label.contains(brand), isFalse, reason: '"$label" contains "$brand"');
      }
    }
  });

  test('dc_unknown is a cause the shepherd picks, and is not the tally for a blank', () {
    // CONVENTIONS §5.1: never merge the two columns. dc_unknown is "I looked and
    // could not tell"; `unattributed` is our word for a field nobody filled in,
    // and it is not a vocab key at all — which is why it appears in no list here.
    expect(kVocabLists['death_cause'], contains('dc_unknown'));
    for (final List<String> keys in kVocabLists.values) {
      expect(keys, isNot(contains('unattributed')));
    }
  });
}
