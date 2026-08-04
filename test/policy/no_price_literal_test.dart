// test/policy/no_price_literal_test.dart
//
// **NAMED FOR WHAT IT FORBIDS** (`CONVENTIONS §4.1`). The price is the store's,
// and it arrives as a `String` that this app never builds, never parses and
// never reformats.
//
// Two failures, and the second is the one that survives review:
//
//   * a hard-coded `£24.99` is wrong for most of the world the day it ships;
//   * a `NumberFormat.currency` call is wrong more subtly — it formats the
//     number correctly in the **wrong currency**, because this app knows
//     neither the account's currency nor the tier the store resolved nor the
//     tax treatment, and all three differ by territory.
@Tags(<String>['policy'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A file's source with its comment lines removed — the rule is about what the
/// code emits, not the prose about what it must not.
String _code(String path) => File(path)
    .readAsStringSync()
    .split('\n')
    .where((String l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

void main() {
  test('no currency symbol followed by a digit exists anywhere under lib/', () {
    // The gate row scans the same thing; this duplicates it in the tier a
    // developer runs first, and covers the ARB, which the gate also reaches.
    final RegExp literal = RegExp(r'[£$€¥]\s?\d');

    for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !(f.path.endsWith('.dart') || f.path.endsWith('.arb'))) {
        continue;
      }
      // ARB `description`s legitimately quote an example price, and the message
      // values are what render. Strip the prose, keep the payload.
      final String body = f.path.endsWith('.arb')
          ? File(f.path)
                .readAsLinesSync()
                .where((String l) => !l.contains('"description"') && !l.contains('"example"'))
                .join('\n')
          : _code(f.path);

      expect(literal.hasMatch(body), isFalse, reason: '${f.path} carries a price literal');
    }
  });

  test('no currency formatter exists, and formatters.dart must never gain one', () {
    // `formatters.dart` is the one `package:intl` site outside `lib/data/`, and
    // it deliberately has no currency function. Adding one would look like
    // consistency — every other unit in this app is formatted there — and would
    // be the second failure above.
    final String formatters = _code('lib/core/ui/formatters.dart');
    expect(formatters, isNot(contains('currency')));
    expect(formatters, isNot(contains('simpleCurrency')));

    for (final FileSystemEntity f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) {
        continue;
      }
      expect(
        _code(f.path),
        isNot(contains('NumberFormat.currency')),
        reason: '${f.path} formats a currency this app cannot know',
      );
    }
  });

  test('the price crosses the seam as a String and is never parsed back', () {
    // **IT IS A `String` THE WHOLE WAY**, from `ProductDetails.price` to the
    // button label. Parsing it to a number — to compare it, to sort it, to
    // "tidy" it — throws away the currency and the locale the store encoded in
    // it, and there is no way back.
    final String seam = _code('lib/data/purchase_service.dart');
    expect(seam, contains('Future<String?> queryUnlockPrice()'));

    for (final String path in <String>[
      'lib/features/settings/unlock_controller.dart',
      'lib/features/settings/widgets/unlock_section.dart',
      'lib/features/flock/widgets/upgrade_row.dart',
    ]) {
      final String body = _code(path);
      for (final String parse in <String>['double.parse', 'int.parse', 'num.parse']) {
        expect(body, isNot(contains(parse)), reason: '$path parses the price');
      }
    }
  });

  test('the unpriced form is its own message, not a placeholder left empty', () {
    // `UNLOCK — ` with a trailing dash is a rendering of a missing value, and a
    // dash where a price should be reads as **free**. Two messages, chosen by
    // the state.
    final String section = _code('lib/features/settings/widgets/unlock_section.dart');
    expect(section, contains('unlockBuyPriced'));
    expect(section, contains('unlockBuyUnpriced'));
  });
}
