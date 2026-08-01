// test/domain/terminology_test.dart — the closed enum under the user-editable
// overlay.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/domain/terminology/animal_class.dart';
import 'package:shed_book/domain/terminology/term_label.dart';
import 'package:shed_book/domain/terminology/terminology.dart';

const Map<AnimalClass, TermLabel> _defaults = <AnimalClass, TermLabel>{
  AnimalClass.ewe: TermLabel('ewe', 'ewes'),
  AnimalClass.maidenFemale: TermLabel('gimmer', 'gimmers'),
  AnimalClass.eweLamb: TermLabel('ewe lamb', 'ewe lambs'),
  AnimalClass.ram: TermLabel('tup', 'tups'),
  AnimalClass.ramLamb: TermLabel('ram lamb', 'ram lambs'),
  AnimalClass.wether: TermLabel('wether', 'wethers'),
  AnimalClass.lamb: TermLabel('lamb', 'lambs'),
};

void main() {
  test('a term override replaces the label everywhere while the enum stays closed', () {
    const Terminology t = Terminology(_defaults, <AnimalClass, TermLabel>{
      AnimalClass.ewe: TermLabel('yow', 'yows'),
    });

    expect(t.labelFor(AnimalClass.ewe).singular, 'yow');
    expect(t.labelFor(AnimalClass.ewe).plural, 'yows');
    // …and the key is unchanged: the enum is what the code switches on, and what
    // goes into the database, the CSV and the JSON backup.
    expect(AnimalClass.ewe.name, 'ewe');
  });

  test('an unoverridden class falls back to its default', () {
    const Terminology t = Terminology(_defaults, <AnimalClass, TermLabel>{
      AnimalClass.ewe: TermLabel('yow', 'yows'),
    });

    expect(t.labelFor(AnimalClass.ram).singular, 'tup');
    expect(t.labelFor(AnimalClass.lamb).plural, 'lambs');
  });

  test('a half-filled override is ignored, not rendered', () {
    // A row with a blank plural falls back to the default rather than rendering
    // an empty 60 pt button at 3am.
    const Terminology blankPlural = Terminology(_defaults, <AnimalClass, TermLabel>{
      AnimalClass.ewe: TermLabel('yow', ''),
    });
    const Terminology whitespaceOnly = Terminology(_defaults, <AnimalClass, TermLabel>{
      AnimalClass.ewe: TermLabel('   ', '   '),
    });

    expect(blankPlural.labelFor(AnimalClass.ewe).singular, 'ewe');
    expect(whitespaceOnly.labelFor(AnimalClass.ewe).plural, 'ewes');
  });

  test('validateOverride rejects a missing side rather than inventing it', () {
    // Never derive a plural by appending "s". The user is already typing one
    // word; guessing the other is §12.4.
    final TermOverrideResult r = validateOverride('yow', '');

    expect(r, isA<TermOverrideRejected>());
    expect((r as TermOverrideRejected).reason, 'Both the singular and the plural are needed.');
  });

  test('validateOverride rejects over 24 characters, with the 3am reason', () {
    final TermOverrideResult r = validateOverride('a' * 25, 'bs');

    expect(
      (r as TermOverrideRejected).reason,
      '24 characters maximum, so it still fits the buttons at arm’s length.',
    );
    expect(validateOverride('a' * 24, 'b' * 24), isA<TermOverrideAccepted>());
  });

  test('validateOverride rejects a comma, a quote and a line break — it does not strip them', () {
    // Stripping the comma silently would be a silent correction; rejecting with
    // a reason is not. A label goes into the CSV, where a comma or a quote
    // breaks a column, and into a button, where a line break breaks the button.
    for (final String bad in <String>['a,b', 'a"b', 'a\nb', 'a\tb', 'a\rb']) {
      final TermOverrideResult r = validateOverride(bad, 'plural');
      expect(r, isA<TermOverrideRejected>(), reason: bad);
      expect((r as TermOverrideRejected).reason, 'No commas, quotes or line breaks.');
    }
  });

  test('trimming is the one accepted sanitisation', () {
    // Invisible, universally expected, and it cannot change meaning. Everything
    // else is rejected with a reason.
    final TermOverrideResult r = validateOverride('  yow  ', '  yows  ');

    expect((r as TermOverrideAccepted).label.singular, 'yow');
    expect(r.label.plural, 'yows');
  });

  test('an accepted override carries the trimmed label, not the raw text', () {
    final TermOverrideResult r = validateOverride(' tup ', ' tups ');
    expect((r as TermOverrideAccepted).label, const TermLabel('tup', 'tups'));
  });
}
