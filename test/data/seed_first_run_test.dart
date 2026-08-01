// test/data/seed_first_run_test.dart — what a brand-new database holds before
// the first screen paints.
library;

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/seed/first_run.dart';

import '../support/harness.dart';

void main() {
  test('a new database seeds forty vocabulary keys with NULL labels', () async {
    // KEYS ONLY, never labels (R66, 10 §8.6). A NULL label means "use the
    // shipped en-GB default for this key", which is what stops a locale change
    // or an app update overwriting a shepherd's own wording — and it is what
    // keeps lib/data/ from ever touching AppLocalizations.
    final AppDatabase db = testDatabase();

    final List<VocabTerm> terms = await db.select(db.vocabTerms).get();

    expect(terms, hasLength(40));
    expect(terms.every((VocabTerm t) => t.label == null), isTrue);
    expect(terms.every((VocabTerm t) => t.origin == 'seeded'), isTrue);
    expect(terms.every((VocabTerm t) => t.hiddenAt == null), isTrue);
  });

  test('the six lists are seeded in render order, each from 0', () async {
    final AppDatabase db = testDatabase();

    for (final MapEntry<String, List<String>> list in kSeededVocabulary.entries) {
      final List<VocabTerm> seeded =
          await (db.select(db.vocabTerms)
                ..where(($VocabTermsTable t) => t.list.equals(list.key))
                ..orderBy(<OrderClauseGenerator<$VocabTermsTable>>[
                  ($VocabTermsTable t) => OrderingTerm(expression: t.sortOrder),
                ]))
              .get();

      expect(seeded.map((VocabTerm t) => t.key).toList(), list.value, reason: list.key);
      expect(
        seeded.map((VocabTerm t) => t.sortOrder).toList(),
        List<int>.generate(list.value.length, (int i) => i),
        reason: list.key,
      );
    }
  });

  test('the eight reminder rules are seeded enabled', () async {
    final AppDatabase db = testDatabase();

    final List<ReminderRule> rules = await db.select(db.reminderRules).get();

    expect(rules, hasLength(8));
    expect(rules.every((ReminderRule r) => r.enabled), isTrue);
    expect(rules.map((ReminderRule r) => r.kind).toSet(), kSeededReminderRules.keys.toSet());
  });

  test('app_settings and entitlements each hold exactly one row', () async {
    final AppDatabase db = testDatabase();

    expect(await db.select(db.appSettings).get(), hasLength(1));
    expect(await db.select(db.entitlements).get(), hasLength(1));
    expect((await db.select(db.entitlements).getSingle()).unlocked, isFalse);
  });

  test('seedOnCreate: false leaves every table empty', () async {
    // The two paths that pass it are a restore and tool/seed.dart, and both are
    // about to write their own rows — a seeded vocab_terms row would collide
    // with a restored one on the UNIQUE key.
    final AppDatabase db = testDatabase(seedOnCreate: false);

    expect(await db.select(db.vocabTerms).get(), isEmpty);
    expect(await db.select(db.reminderRules).get(), isEmpty);
    expect(await db.select(db.appSettings).get(), isEmpty);
  });

  test('seeding is idempotent: running it twice changes nothing', () async {
    // insertOrIgnore rather than insert. A second run happens whenever a
    // migration re-enters onCreate on a partially built file, and a UNIQUE
    // violation there would leave the app unable to open at all.
    final AppDatabase db = testDatabase();

    await seedFirstRun(db);

    expect(await db.select(db.vocabTerms).get(), hasLength(40));
    expect(await db.select(db.reminderRules).get(), hasLength(8));
    expect(await db.select(db.appSettings).get(), hasLength(1));
  });

  test('the seeded key count is forty, and forty-one is a schema change', () {
    // If this is ever 41, somebody has added the sixth ease point that
    // decision-record §7.1 open question 15 leaves open — and that is a CHECK
    // change, not a seed edit.
    final int total = kSeededVocabulary.values.fold<int>(
      0,
      (int sum, List<String> keys) => sum + keys.length,
    );
    expect(total, 40);
    expect(kSeededVocabulary.keys, hasLength(6));
  });
}
