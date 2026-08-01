// test/policy/terminology_survives_a_rename_test.dart — the property 05's
// definition of done names: pluralisation survives an ARBITRARY override, and
// the seven members and fourteen ARB messages are the same set.
//
// This is NOT the "no domain noun is a literal in any ARB message" scan. That is
// test/policy/arb_has_no_domain_noun_test.dart and it belongs to N33-T05
// (00-PLAN-CRITIQUE §11.3). Do not create a second copy here.
@Tags(<String>['policy'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/terminology/animal_class.dart';
import 'package:shed_book/domain/terminology/term_label.dart';
import 'package:shed_book/domain/terminology/terminology.dart';

/// `ewe` → `Ewe`, so the enum member and the ARB key can be compared.
String _messageStem(AnimalClass c) => c.name[0].toUpperCase() + c.name.substring(1);

Map<String, dynamic> _arb() =>
    jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;

void main() {
  test('every AnimalClass member has a singular and a plural ARB message', () {
    final Map<String, dynamic> arb = _arb();

    for (final AnimalClass c in AnimalClass.values) {
      expect(arb.containsKey('term${_messageStem(c)}Singular'), isTrue, reason: c.name);
      expect(arb.containsKey('term${_messageStem(c)}Plural'), isTrue, reason: c.name);
    }
  });

  test('every term* ARB message belongs to an AnimalClass member', () {
    // The reverse direction. Without it, a deleted enum member leaves an orphan
    // message that the bootstrap silently never reads, and `_defaults[c]!` then
    // throws for the member nobody noticed was gone.
    final Set<String> expected = <String>{
      for (final AnimalClass c in AnimalClass.values) ...<String>[
        'term${_messageStem(c)}Singular',
        'term${_messageStem(c)}Plural',
      ],
    };
    final Set<String> actual = _arb().keys
        .where((String k) => k.startsWith('term') && !k.startsWith('@'))
        .toSet();

    expect(actual, expected);
    expect(actual, hasLength(14), reason: 'seven members, two forms each');
  });

  test('pluralisation survives an arbitrary override', () {
    // The property, not an example. Whatever pair the shepherd types comes back
    // unchanged — no appended "s", no title case, no re-derivation. "3 sheeps"
    // is what a rule-based pluraliser produces and is why there is no rule.
    const Map<AnimalClass, TermLabel> defaults = <AnimalClass, TermLabel>{
      AnimalClass.ewe: TermLabel('ewe', 'ewes'),
    };

    const List<TermLabel> arbitrary = <TermLabel>[
      TermLabel('yow', 'yows'),
      TermLabel('sheep', 'sheep'),
      TermLabel('ox', 'oxen'),
      TermLabel('theave', 'theaves'),
      TermLabel('Zwartbles ewe', 'Zwartbles ewes'),
    ];

    for (final TermLabel label in arbitrary) {
      final Terminology t = Terminology(defaults, <AnimalClass, TermLabel>{AnimalClass.ewe: label});
      expect(t.labelFor(AnimalClass.ewe).singular, label.singular, reason: label.singular);
      expect(t.labelFor(AnimalClass.ewe).plural, label.plural, reason: label.plural);
      if (label.plural != '${label.singular}s') {
        // Only meaningful for the pairs the naive rule gets WRONG — 'sheep' and
        // 'ox' are the whole reason there is no rule. Asserting it for
        // 'yow'/'yows' would pass under a rule-based pluraliser too.
        expect(t.labelFor(AnimalClass.ewe).plural, isNot('${label.singular}s'));
      }
    }
  });

  test('the nAnimals message takes both forms and lets ICU choose only the category', () {
    final Map<String, dynamic> arb = _arb();
    final String message = arb['nAnimals'] as String;
    final Map<String, dynamic> meta = arb['@nAnimals'] as Map<String, dynamic>;

    expect(message, contains('{singularTerm}'));
    expect(message, contains('{pluralTerm}'));
    // The failure mode this shape exists to prevent: ICU appending its own "s".
    expect(message, isNot(contains('{term}s')));
    expect((meta['placeholders'] as Map<String, dynamic>).keys.toSet(), <String>{
      'count',
      'singularTerm',
      'pluralTerm',
    });
  });

  test('every message in the ARB carries a description', () {
    // l10n.yaml sets required-resource-attributes, so gen-l10n already enforces
    // this — the cross-check is here because a description is where the safety
    // rationale for a string lives, and gen-l10n only checks that one exists.
    final Map<String, dynamic> arb = _arb();
    for (final String key in arb.keys.where((String k) => !k.startsWith('@'))) {
      final Object? meta = arb['@$key'];
      expect(meta, isA<Map<String, dynamic>>(), reason: key);
      expect((meta! as Map<String, dynamic>)['description'], isNotEmpty, reason: key);
    }
  });

  test('lib/domain/ never references AppLocalizations', () {
    // Layer rule 1. Terminology holds no default text and cannot fetch any: the
    // defaults arrive through its constructor, seeded once by
    // terminology_bootstrap.dart, which has a BuildContext.
    //
    // DECLARATIONS, comment lines dropped. terminology.dart's own doc comment
    // names the ban — that is how the next reader learns the absence is
    // deliberate — and a whole-text scan fires on that sentence, whose only fix
    // would be to delete it. The gate reads import directives; this reads
    // declarations; neither reads prose.
    for (final FileSystemEntity f in Directory('lib/domain').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) {
        continue;
      }
      final String declarations = f
          .readAsLinesSync()
          .where((String l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      expect(declarations, isNot(contains('AppLocalizations')), reason: f.path);
    }
  });
}
