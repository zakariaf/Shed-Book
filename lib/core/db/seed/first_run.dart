import 'package:drift/drift.dart';
import 'package:shed_book/core/db/database.dart';
import 'package:shed_book/core/db/uid.dart';
import 'package:shed_book/core/time/app_clock.dart';

/// Everything a brand-new database needs before the first screen paints.
///
/// **Keys only — never labels.** R66 and 10 §8.6: `vocab_terms.label` is seeded
/// `NULL`, which means *"use the shipped en-GB default for this key"*, and the
/// label itself is an ARB message. That is what stops a locale change or an app
/// update overwriting a shepherd's own wording, and it is what keeps
/// `lib/data/` from ever touching `AppLocalizations`.
///
/// **Not a setup step.** Spec §5: there is no onboarding after first run. This
/// runs inside `onCreate`, before anything is rendered, and the shepherd never
/// sees it happen.
///
/// It is skipped on exactly two paths — a restore, and `tool/seed.dart` — both
/// of which pass `seedOnCreate: false`, because both are about to write their
/// own rows and a seeded row would collide with a restored one on
/// `vocab_terms.key`.
Future<void> seedFirstRun(AppDatabase db) async {
  await db.transaction(() async {
    await _seedVocabulary(db);
    await _seedReminderRules(db);
    // app_settings is a singleton whose every column carries a default, so the
    // seed is the row's existence rather than its contents.
    await db
        .into(db.appSettings)
        .insert(const AppSettingsCompanion(), mode: InsertMode.insertOrIgnore);
    await db
        .into(db.entitlements)
        .insert(const EntitlementsCompanion(), mode: InsertMode.insertOrIgnore);
  });
}

/// 03 §10.1's six lists, forty keys, in the order they render.
///
/// The keys are frozen; the labels are `NULL`. If this map is ever forty-one
/// entries, somebody has added the sixth ease point that decision-record §7.1
/// open question 15 leaves open — and that is a schema `CHECK` change, not a
/// seed edit.
const Map<String, List<String>> kSeededVocabulary = <String, List<String>>{
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

Future<void> _seedVocabulary(AppDatabase db) async {
  await db.batch((Batch batch) {
    for (final MapEntry<String, List<String>> list in kSeededVocabulary.entries) {
      int sortOrder = 0;
      for (final String key in list.value) {
        batch.insert(
          db.vocabTerms,
          VocabTermsCompanion.insert(
            uid: newUid(),
            createdAt: appNow(),
            updatedAt: appNow(),
            list: list.key,
            key: key,
            // NULL. The label is the ARB message `vocab${upperCamel(key)}`.
            sortOrder: sortOrder++,
            origin: 'seeded',
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    }
  });
}

/// The reminder kinds and their default offsets.
///
/// **Every rule is seeded enabled with an offset, and none of them is a
/// husbandry recommendation** — an offset is *"how long before you nudge me"*,
/// which is a preference, not a clinical interval. The kinds themselves are a
/// closed `CHECK` because each maps to an Android channel id frozen at release.
const Map<String, int> kSeededReminderRules = <String, int>{
  'colostrum': 120,
  'navel': 60,
  'turn_out': 1440,
  'tag_by': 10080,
  'ring_dock_castrate': 10080,
  'second_dose': 1440,
  'withdrawal_end': 0,
  'custom': 0,
};

Future<void> _seedReminderRules(AppDatabase db) async {
  await db.batch((Batch batch) {
    for (final MapEntry<String, int> rule in kSeededReminderRules.entries) {
      batch.insert(
        db.reminderRules,
        ReminderRulesCompanion.insert(kind: rule.key, offsetMinutes: rule.value),
        mode: InsertMode.insertOrIgnore,
      );
    }
  });
}
