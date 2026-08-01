import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Spec 12.1 provenance. The wording 'as entered by you' is a SAFETY REQUIREMENT, not a style choice. Do not shorten it. Never show a withdrawal figure without it.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal period: {days} days, as entered by you'**
  String withdrawalSource({required int days});

  /// The DEFAULT label for AnimalClass.ewe. It is a default, not a constant: the shepherd may rename it in Settings and every screen follows, because the code switches on the AnimalClass enum and only ever renders the resolved label. Never referenced from lib/domain/ — layer rule 1 bans AppLocalizations there; it is read once by terminology_bootstrap.dart. See 05-domain-correctness.md §8. Singular form.
  ///
  /// In en, this message translates to:
  /// **'ewe'**
  String get termEweSingular;

  /// The DEFAULT label for AnimalClass.ewe. It is a default, not a constant: the shepherd may rename it in Settings and every screen follows, because the code switches on the AnimalClass enum and only ever renders the resolved label. Never referenced from lib/domain/ — layer rule 1 bans AppLocalizations there; it is read once by terminology_bootstrap.dart. See 05-domain-correctness.md §8. Plural form. NEVER derived by appending 's' — '3 sheeps' is why.
  ///
  /// In en, this message translates to:
  /// **'ewes'**
  String get termEwePlural;

  /// The DEFAULT label for AnimalClass.maidenFemale. It is a default, not a constant: the shepherd may rename it in Settings and every screen follows, because the code switches on the AnimalClass enum and only ever renders the resolved label. Never referenced from lib/domain/ — layer rule 1 bans AppLocalizations there; it is read once by terminology_bootstrap.dart. See 05-domain-correctness.md §8. Singular form.
  ///
  /// In en, this message translates to:
  /// **'gimmer'**
  String get termMaidenFemaleSingular;

  /// The DEFAULT label for AnimalClass.maidenFemale. It is a default, not a constant: the shepherd may rename it in Settings and every screen follows, because the code switches on the AnimalClass enum and only ever renders the resolved label. Never referenced from lib/domain/ — layer rule 1 bans AppLocalizations there; it is read once by terminology_bootstrap.dart. See 05-domain-correctness.md §8. Plural form. NEVER derived by appending 's' — '3 sheeps' is why.
  ///
  /// In en, this message translates to:
  /// **'gimmers'**
  String get termMaidenFemalePlural;

  /// The DEFAULT label for AnimalClass.eweLamb. It is a default, not a constant: the shepherd may rename it in Settings and every screen follows, because the code switches on the AnimalClass enum and only ever renders the resolved label. Never referenced from lib/domain/ — layer rule 1 bans AppLocalizations there; it is read once by terminology_bootstrap.dart. See 05-domain-correctness.md §8. Singular form.
  ///
  /// In en, this message translates to:
  /// **'ewe lamb'**
  String get termEweLambSingular;

  /// The DEFAULT label for AnimalClass.eweLamb. It is a default, not a constant: the shepherd may rename it in Settings and every screen follows, because the code switches on the AnimalClass enum and only ever renders the resolved label. Never referenced from lib/domain/ — layer rule 1 bans AppLocalizations there; it is read once by terminology_bootstrap.dart. See 05-domain-correctness.md §8. Plural form. NEVER derived by appending 's' — '3 sheeps' is why.
  ///
  /// In en, this message translates to:
  /// **'ewe lambs'**
  String get termEweLambPlural;

  /// The DEFAULT label for AnimalClass.ram. It is a default, not a constant: the shepherd may rename it in Settings and every screen follows, because the code switches on the AnimalClass enum and only ever renders the resolved label. Never referenced from lib/domain/ — layer rule 1 bans AppLocalizations there; it is read once by terminology_bootstrap.dart. See 05-domain-correctness.md §8. Singular form.
  ///
  /// In en, this message translates to:
  /// **'tup'**
  String get termRamSingular;

  /// The DEFAULT label for AnimalClass.ram. It is a default, not a constant: the shepherd may rename it in Settings and every screen follows, because the code switches on the AnimalClass enum and only ever renders the resolved label. Never referenced from lib/domain/ — layer rule 1 bans AppLocalizations there; it is read once by terminology_bootstrap.dart. See 05-domain-correctness.md §8. Plural form. NEVER derived by appending 's' — '3 sheeps' is why.
  ///
  /// In en, this message translates to:
  /// **'tups'**
  String get termRamPlural;

  /// The DEFAULT label for AnimalClass.ramLamb. It is a default, not a constant: the shepherd may rename it in Settings and every screen follows, because the code switches on the AnimalClass enum and only ever renders the resolved label. Never referenced from lib/domain/ — layer rule 1 bans AppLocalizations there; it is read once by terminology_bootstrap.dart. See 05-domain-correctness.md §8. Singular form.
  ///
  /// In en, this message translates to:
  /// **'ram lamb'**
  String get termRamLambSingular;

  /// The DEFAULT label for AnimalClass.ramLamb. It is a default, not a constant: the shepherd may rename it in Settings and every screen follows, because the code switches on the AnimalClass enum and only ever renders the resolved label. Never referenced from lib/domain/ — layer rule 1 bans AppLocalizations there; it is read once by terminology_bootstrap.dart. See 05-domain-correctness.md §8. Plural form. NEVER derived by appending 's' — '3 sheeps' is why.
  ///
  /// In en, this message translates to:
  /// **'ram lambs'**
  String get termRamLambPlural;

  /// The DEFAULT label for AnimalClass.wether. It is a default, not a constant: the shepherd may rename it in Settings and every screen follows, because the code switches on the AnimalClass enum and only ever renders the resolved label. Never referenced from lib/domain/ — layer rule 1 bans AppLocalizations there; it is read once by terminology_bootstrap.dart. See 05-domain-correctness.md §8. Singular form.
  ///
  /// In en, this message translates to:
  /// **'wether'**
  String get termWetherSingular;

  /// The DEFAULT label for AnimalClass.wether. It is a default, not a constant: the shepherd may rename it in Settings and every screen follows, because the code switches on the AnimalClass enum and only ever renders the resolved label. Never referenced from lib/domain/ — layer rule 1 bans AppLocalizations there; it is read once by terminology_bootstrap.dart. See 05-domain-correctness.md §8. Plural form. NEVER derived by appending 's' — '3 sheeps' is why.
  ///
  /// In en, this message translates to:
  /// **'wethers'**
  String get termWetherPlural;

  /// The DEFAULT label for AnimalClass.lamb. It is a default, not a constant: the shepherd may rename it in Settings and every screen follows, because the code switches on the AnimalClass enum and only ever renders the resolved label. Never referenced from lib/domain/ — layer rule 1 bans AppLocalizations there; it is read once by terminology_bootstrap.dart. See 05-domain-correctness.md §8. Singular form.
  ///
  /// In en, this message translates to:
  /// **'lamb'**
  String get termLambSingular;

  /// The DEFAULT label for AnimalClass.lamb. It is a default, not a constant: the shepherd may rename it in Settings and every screen follows, because the code switches on the AnimalClass enum and only ever renders the resolved label. Never referenced from lib/domain/ — layer rule 1 bans AppLocalizations there; it is read once by terminology_bootstrap.dart. See 05-domain-correctness.md §8. Plural form. NEVER derived by appending 's' — '3 sheeps' is why.
  ///
  /// In en, this message translates to:
  /// **'lambs'**
  String get termLambPlural;

  /// ICU cannot pluralise a runtime string, so it chooses only the CATEGORY and the terminology map supplies both forms. "{count, plural, other{{count} {term}s}}" yields "3 gimmers" (fine), "3 tups" (fine) and "3 sheeps" (not fine). Both terms are USER-EDITABLE nouns from the terminology overlay: never translate them, never hard-code them. See 10-accessibility-and-i18n.md §8.5.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No {pluralTerm}} =1{1 {singularTerm}} other{{count} {pluralTerm}}}'**
  String nAnimals({required num count, required String singularTerm, required String pluralTerm});

  /// Default label for vocab_terms(list='lambing_ease', key='ease_1'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'No assistance'**
  String get vocabEase1;

  /// Default label for vocab_terms(list='lambing_ease', key='ease_2'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Slight assistance by hand'**
  String get vocabEase2;

  /// Default label for vocab_terms(list='lambing_ease', key='ease_3'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Considerable assistance needed'**
  String get vocabEase3;

  /// Default label for vocab_terms(list='lambing_ease', key='ease_4'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Veterinary assistance needed'**
  String get vocabEase4;

  /// Default label for vocab_terms(list='lambing_ease', key='ease_5'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Caesarean section'**
  String get vocabEase5;

  /// Default label for vocab_terms(list='death_cause', key='dc_starvation'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Starvation'**
  String get vocabDcStarvation;

  /// Default label for vocab_terms(list='death_cause', key='dc_hypothermia'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Hypothermia'**
  String get vocabDcHypothermia;

  /// Default label for vocab_terms(list='death_cause', key='dc_watery_mouth'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Watery mouth'**
  String get vocabDcWateryMouth;

  /// Default label for vocab_terms(list='death_cause', key='dc_joint_ill'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Joint ill'**
  String get vocabDcJointIll;

  /// Default label for vocab_terms(list='death_cause', key='dc_crushed'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Crushed'**
  String get vocabDcCrushed;

  /// Default label for vocab_terms(list='death_cause', key='dc_stillborn'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Stillborn'**
  String get vocabDcStillborn;

  /// Default label for vocab_terms(list='death_cause', key='dc_unknown'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get vocabDcUnknown;

  /// Default label for vocab_terms(list='death_cause', key='dc_other'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get vocabDcOther;

  /// Default label for vocab_terms(list='malpresentation', key='mp_head_back'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Head back'**
  String get vocabMpHeadBack;

  /// Default label for vocab_terms(list='malpresentation', key='mp_one_leg_back'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'One leg back'**
  String get vocabMpOneLegBack;

  /// Default label for vocab_terms(list='malpresentation', key='mp_both_legs_back'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Both legs back'**
  String get vocabMpBothLegsBack;

  /// Default label for vocab_terms(list='malpresentation', key='mp_breech'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Breech'**
  String get vocabMpBreech;

  /// Default label for vocab_terms(list='malpresentation', key='mp_backwards'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Backwards'**
  String get vocabMpBackwards;

  /// Default label for vocab_terms(list='malpresentation', key='mp_twins_together'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Twins together'**
  String get vocabMpTwinsTogether;

  /// Default label for vocab_terms(list='malpresentation', key='mp_ringwomb'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Ringwomb'**
  String get vocabMpRingwomb;

  /// Default label for vocab_terms(list='malpresentation', key='mp_other'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get vocabMpOther;

  /// Default label for vocab_terms(list='treatment_route', key='rt_subcutaneous'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Subcutaneous'**
  String get vocabRtSubcutaneous;

  /// Default label for vocab_terms(list='treatment_route', key='rt_intramuscular'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Intramuscular'**
  String get vocabRtIntramuscular;

  /// Default label for vocab_terms(list='treatment_route', key='rt_oral'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Oral'**
  String get vocabRtOral;

  /// Default label for vocab_terms(list='treatment_route', key='rt_topical'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Topical'**
  String get vocabRtTopical;

  /// Default label for vocab_terms(list='treatment_route', key='rt_intranasal'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Intranasal'**
  String get vocabRtIntranasal;

  /// Default label for vocab_terms(list='treatment_route', key='rt_intravenous'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Intravenous'**
  String get vocabRtIntravenous;

  /// Default label for vocab_terms(list='treatment_route', key='rt_intraperitoneal'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Intraperitoneal'**
  String get vocabRtIntraperitoneal;

  /// Default label for vocab_terms(list='treatment_route', key='rt_other'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get vocabRtOther;

  /// Default label for vocab_terms(list='ewe_observation', key='obs_prolapse'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Prolapse'**
  String get vocabObsProlapse;

  /// Default label for vocab_terms(list='ewe_observation', key='obs_mastitis'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Mastitis'**
  String get vocabObsMastitis;

  /// Default label for vocab_terms(list='ewe_observation', key='obs_poor_mothering'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Poor mothering'**
  String get vocabObsPoorMothering;

  /// Default label for vocab_terms(list='ewe_observation', key='obs_good_mothering'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Good mothering'**
  String get vocabObsGoodMothering;

  /// Default label for vocab_terms(list='ewe_observation', key='obs_no_milk'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'No milk'**
  String get vocabObsNoMilk;

  /// Default label for vocab_terms(list='ewe_observation', key='obs_other'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get vocabObsOther;

  /// Default label for vocab_terms(list='foster_method', key='fm_wet_adopt'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Wet adoption'**
  String get vocabFmWetAdopt;

  /// Default label for vocab_terms(list='foster_method', key='fm_skin'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Skinning'**
  String get vocabFmSkin;

  /// Default label for vocab_terms(list='foster_method', key='fm_crate'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Adoption crate'**
  String get vocabFmCrate;

  /// Default label for vocab_terms(list='foster_method', key='fm_bottle'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Bottle'**
  String get vocabFmBottle;

  /// Default label for vocab_terms(list='foster_method', key='fm_other'). Authored for this app — spec §11 ships no licensed vocabulary and no product, breed or medicine database. It is a DEFAULT, not a constant: the shepherd may rename or hide the term, and vocab_terms.label is NULL until they do. Never a dose, a course or an instruction.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get vocabFmOther;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
