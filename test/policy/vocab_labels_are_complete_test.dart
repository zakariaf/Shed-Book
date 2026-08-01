// test/policy/vocab_labels_are_complete_test.dart — the property N06-T11
// deferred here, named for the property rather than for a file (CONVENTIONS
// §4.1).
//
// R66 gives the forty terms three homes with no overlap: the KEYS are seeded in
// lib/core/db/seed/first_run.dart with label = NULL, the LABELS are ARB
// messages, and assets/content/ holds prose too long to be a UI string plus one
// provenance line per list.
//
// This is the SET EQUALITY between the first two, and it is the assertion that
// makes the NULL label safe: a seeded key with no ARB message renders blank at
// 3am, and an ARB message with no seeded key is a label nothing can ever show.
// N06-T11's count assertion is deliberately the weaker half that could run
// before this file existed; both are kept, because they fail differently.
@Tags(<String>['policy'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/seed/first_run.dart';

/// `dc_starvation` → `vocabDcStarvation` (10 §8.6).
String messageIdFor(String key) =>
    'vocab${key.split('_').map((String w) => w[0].toUpperCase() + w.substring(1)).join()}';

void main() {
  test('every seeded vocabulary key has an ARB label, and every label a key', () {
    final Map<String, dynamic> arb =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;

    final Set<String> fromSeed = <String>{
      for (final List<String> keys in kSeededVocabulary.values)
        for (final String key in keys) messageIdFor(key),
    };
    final Set<String> fromArb = arb.keys
        .where((String k) => k.startsWith('vocab') && !k.startsWith('@'))
        .toSet();

    // Both directions, and they fail differently. A seeded key with no message
    // renders a blank chip in the shed; a message with no key is a label nothing
    // can ever show, which is dead weight in every future translation.
    expect(
      fromSeed.difference(fromArb),
      isEmpty,
      reason: 'seeded keys with no ARB label — these render blank at 3am',
    );
    expect(fromArb.difference(fromSeed), isEmpty, reason: 'ARB labels no seed will ever show');
    expect(fromSeed, hasLength(40));
  });

  test('the seeded list names are exactly the six the CHECK admits', () {
    // vocab_terms.list carries a closed CHECK, so a seventh list name would be
    // unstorable — and the failure would be a first-run crash on a new install,
    // which is the worst place to discover it.
    expect(kSeededVocabulary.keys.toSet(), <String>{
      'death_cause',
      'malpresentation',
      'treatment_route',
      'ewe_observation',
      'lambing_ease',
      'foster_method',
    });
  });

  test('every seeded key is prefixed for its list, so a key names its own home', () {
    const Map<String, String> prefixes = <String, String>{
      'lambing_ease': 'ease_',
      'death_cause': 'dc_',
      'malpresentation': 'mp_',
      'treatment_route': 'rt_',
      'ewe_observation': 'obs_',
      'foster_method': 'fm_',
    };

    for (final MapEntry<String, List<String>> list in kSeededVocabulary.entries) {
      for (final String key in list.value) {
        expect(key, startsWith(prefixes[list.key]!), reason: '${list.key} / $key');
      }
    }
  });

  test('no seeded key repeats across lists', () {
    // vocab_terms.key is UNIQUE on its own, because foreign keys point at it. A
    // duplicate would abort the seed on a brand-new install.
    final List<String> all = <String>[
      for (final List<String> keys in kSeededVocabulary.values) ...keys,
    ];
    expect(all.toSet(), hasLength(all.length));
  });
}
