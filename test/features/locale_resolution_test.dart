// test/features/locale_resolution_test.dart — 10 §7.3.
//
// FIRST MATCH WINS, and that single fact is what the whole file is about:
// `supportedLocales` lists `en` before `en_GB`, so a US device resolves to `en`
// and only a GB device reaches `en_GB`. Reverse the order and every English
// speaker on earth silently gets British date formats and Monday-first weeks.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app's list, in the app's order. Duplicated from `app.dart` deliberately:
/// a test that imported it would agree with itself after somebody reordered it,
/// and the order is the entire property under test.
const List<Locale> _supported = <Locale>[Locale('en'), Locale('en', 'GB'), Locale('en', 'IE')];

Future<Locale> _resolve(WidgetTester tester, Locale device) async {
  late Locale resolved;
  await tester.pumpWidget(
    MaterialApp(
      locale: device,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: _supported,
      home: Builder(
        builder: (BuildContext context) {
          resolved = Localizations.localeOf(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return resolved;
}

void main() {
  testWidgets('a device set to en-GB resolves to en_GB', (WidgetTester tester) async {
    final Locale resolved = await _resolve(tester, const Locale('en', 'GB'));

    expect(resolved.languageCode, 'en');
    expect(resolved.countryCode, 'GB');
  });

  testWidgets('a device set to en-US resolves to en, not en_GB', (WidgetTester tester) async {
    // THE FIRST-WINS CONSEQUENCE, and the reason `Locale('en')` leads the list.
    // A US shepherd seeing `11 Mar 2026` and a Monday-first week is a silent
    // wrong answer — nothing throws, nothing looks broken.
    final Locale resolved = await _resolve(tester, const Locale('en', 'US'));

    expect(resolved.languageCode, 'en');
    expect(resolved.countryCode, isNot('GB'));
  });

  testWidgets('a device set to fr resolves to en', (WidgetTester tester) async {
    // The fallback, and **it must not throw**: an unsupported locale on a phone
    // in a shed is not an error state, it is a Tuesday.
    final Locale resolved = await _resolve(tester, const Locale('fr'));

    expect(tester.takeException(), isNull);
    expect(resolved.languageCode, 'en');
  });

  testWidgets('en_GB and en_IE both start the week on Monday', (WidgetTester tester) async {
    for (final Locale locale in <Locale>[const Locale('en', 'GB'), const Locale('en', 'IE')]) {
      late int firstDay;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: _supported,
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
}
