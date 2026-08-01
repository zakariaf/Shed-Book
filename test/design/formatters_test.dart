// test/design/formatters_test.dart — the one intl call site.
//
// initializeDateFormatting is called HERE and never in lib/. After
// GlobalMaterialLocalizations.delegate loads, DateFormat('d MMM y', 'en_GB')
// just works; a bare unit test has no delegate and throws a locale-data error.
// Fixing that in lib/ would add a second initialisation authority — so it is
// fixed in the test, which is whose problem it actually is.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shed_book/core/ui/formatters.dart';
import 'package:shed_book/domain/time/instant.dart';
import 'package:shed_book/domain/time/local_date.dart';
import 'package:shed_book/domain/units/grams.dart';
import 'package:shed_book/domain/units/weight_unit.dart';

const String _gb = 'en_GB';

/// Anything that reads as an all-numeric date: `11/03/2026`, `2026-03-11`,
/// `11.03.26`.
final RegExp _allNumericDate = RegExp(r'^\s*\d{1,4}[/.\-]\d{1,2}[/.\-]\d{1,4}\s*$');

List<String> _authoredDart(String root) => Directory(root)
    .listSync(recursive: true)
    .whereType<File>()
    .map((File f) => f.path.replaceAll(r'\', '/'))
    .where(
      (String p) => p.endsWith('.dart') && !p.endsWith('.g.dart') && !p.endsWith('.drift.dart'),
    )
    .toList();

String _declarations(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

void main() {
  setUpAll(() => initializeDateFormatting(_gb));

  test('a human date is never all-numeric and the clock is 24-hour', () {
    // THE ANCHOR. A numeric date is ambiguous between en_GB and en_US, and the
    // app has users in both conventions the moment a CSV is opened on somebody
    // else's laptop.
    expect(formatShedDate(LocalDate(2026, 3, 11), _gb), '11 Mar 2026');
    expect(formatShedDayMonth(LocalDate(2026, 7, 14), _gb), '14 Jul');

    for (final String rendered in <String>[
      formatShedDate(LocalDate(2026, 3, 11), _gb),
      formatShedDayMonth(LocalDate(2026, 7, 14), _gb),
      formatShedDate(LocalDate(2026, 12, 1), _gb),
    ]) {
      expect(_allNumericDate.hasMatch(rendered), isFalse, reason: rendered);
      expect(rendered, matches(RegExp('[A-Za-z]{3}')), reason: '$rendered has no spelled month');
    }

    // 24-hour, both halves of the day. '3:21 AM' is the failure.
    expect(formatShedTime(Instant.fromDateTime(DateTime(2026, 3, 11, 3, 21)), _gb), '03:21');
    expect(formatShedTime(Instant.fromDateTime(DateTime(2026, 3, 11, 15, 21)), _gb), '15:21');
  });

  testWidgets('formatShedTime is unchanged when alwaysUse24HourFormat is false', (
    WidgetTester tester,
  ) async {
    // The deliberate override, made executable. This is the ONE place the app
    // ignores a system preference, and 10 §9.4's reasons are data-integrity
    // reasons: the AM/PM token is exactly the part a tired reader drops, and the
    // medicine book handed to a vet must not carry two spellings of one instant.
    late String rendered;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(alwaysUse24HourFormat: false),
        child: MaterialApp(
          locale: const Locale('en', 'GB'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const <Locale>[Locale('en'), Locale('en', 'GB')],
          home: Builder(
            builder: (BuildContext context) {
              rendered = formatShedTime(
                Instant.fromDateTime(DateTime(2026, 3, 11, 15, 21)),
                context.localeName,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(rendered, '15:21');
    expect(rendered, isNot(contains('PM')));
  });

  test('formatShedWeight round-trips canonical grams into kg and lb', () {
    // The stored value is never rewritten — that is the display-unit round-trip
    // bug WeightUnit's own doc comment describes, and it has no line of code to
    // blame.
    const Grams g = Grams(4100);

    expect(formatShedWeight(g, WeightUnit.kg, _gb), '4.1 kg');
    expect(formatShedWeight(g, WeightUnit.lb, _gb), '9 lb 1 oz');
    expect(g.value, 4100, reason: 'formatting must not touch the canonical value');

    // The decimal separator is fixed to `.` and never locale-derived (#57).
    expect(formatShedWeight(g, WeightUnit.kg, _gb), contains('.'));
    expect(formatShedWeight(g, WeightUnit.kg, _gb), isNot(contains(',')));
  });

  test('formatShedCount groups by locale', () {
    expect(formatShedCount(412, _gb), '412');
    expect(formatShedCount(1240, _gb), '1,240');
  });

  testWidgets('the week starts on Monday for en_GB and en_IE', (WidgetTester tester) async {
    // No calendar ships in v1. The assertion exists so that the day one does, it
    // is already right.
    for (final Locale locale in <Locale>[const Locale('en', 'GB'), const Locale('en', 'IE')]) {
      late int firstDay;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: <Locale>[locale],
          home: Builder(
            builder: (BuildContext context) {
              firstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(firstDay, 1, reason: '$locale');
    }
  });

  test('package:intl is imported by exactly one file under lib/ outside lib/data/', () {
    // Layer rule 7, made executable here rather than waiting for the gate. A
    // second importer is a second place a date format can be decided, and the
    // failure mode of that is a CSV whose two date columns disagree.
    //
    // SCOPED TO IMPORT DIRECTIVES, not to the string. Nine files under lib/
    // contain the characters `package:intl` and only three import it — the rest
    // name it in a comment while explaining layer rule 7, and a naive scan
    // fires on the sentence that documents the rule. Same
    // prohibition-versus-claim shape this project has hit repeatedly.
    //
    // lib/l10n/app_localizations*.dart are EXCLUDED because they are gen-l10n's
    // output. They are committed (00-README §7.1 requires it, so a fresh clone
    // builds) but they are not authored, and `flutter gen-l10n` will always
    // import intl there. Holding generated code to an authored-code layer rule
    // would mean the rule could only be satisfied by deleting the localisation.
    final RegExp directive = RegExp(r"^\s*import\s+'package:intl", multiLine: true);
    final List<String> importers = _authoredDart('lib')
        .where((String p) => !p.startsWith('lib/data/'))
        .where((String p) => !p.startsWith('lib/l10n/app_localizations'))
        .where((String p) => directive.hasMatch(File(p).readAsStringSync()))
        .toList();

    expect(importers, <String>['lib/core/ui/formatters.dart']);
  });

  test('every DateFormat in formatters.dart is passed an explicit locale', () {
    // A DateFormat with a null locale silently produces en_US, and in a
    // background isolate that is what you get with no warning at all.
    final String source = _declarations('lib/core/ui/formatters.dart');
    final Iterable<RegExpMatch> calls = RegExp(r'DateFormat\(([^)]*)\)').allMatches(source);

    expect(calls, isNotEmpty, reason: 'no DateFormat found — has the file moved?');
    for (final RegExpMatch m in calls) {
      expect(
        m.group(1)!.split(',').length,
        greaterThanOrEqualTo(2),
        reason: 'DateFormat(${m.group(1)}) has no explicit locale',
      );
    }
  });

  test('no DateFormat pattern contains a slash or a dot', () {
    // The copy.numeric_date shape, asserted positively so the failure names the
    // pattern rather than a rule id. `d MMM y` and `HH:mm` contain neither,
    // which is exactly why they are safe.
    final String source = _declarations('lib/core/ui/formatters.dart');
    for (final RegExpMatch m in RegExp(r"DateFormat\(\s*'([^']*)'").allMatches(source)) {
      final String pattern = m.group(1)!;
      expect(pattern, isNot(contains('/')), reason: pattern);
      expect(pattern, isNot(contains('.')), reason: pattern);
    }
    expect(source, isNot(contains('DateFormat.yMd')));
  });

  test('formatShedTime takes an Instant and not a RecordedTime', () {
    // The signature that makes laundering provenance impossible. A time is never
    // displayed without its label; giving this function a RecordedTime would let
    // a call site format the instant and drop the label in one step.
    final String source = _declarations('lib/core/ui/formatters.dart');
    expect(source, contains('String formatShedTime(Instant t, String localeName)'));
    expect(source, isNot(contains('RecordedTime')));
  });

  test('no temperature formatter ships', () {
    // R68: decision-record §7.1 #11 is open — spec §7.10 has a °C/°F setting and
    // no v1 table stores a temperature. "An unused setting is a 3am tax."
    final String source = _declarations('lib/core/ui/formatters.dart');
    expect(source, isNot(contains('Celsius')));
    expect(source, isNot(contains('formatShedTemperature')));
  });
}
