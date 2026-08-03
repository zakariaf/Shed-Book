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

  /// Container label for the keypad, announced when a VoiceOver user lands inside it so they know what they have arrived in rather than hearing ten unrelated buttons. Not a heading and never rendered visually — the pad's job is obvious to a sighted shepherd at a glance.
  ///
  /// In en, this message translates to:
  /// **'Tag entry'**
  String get keypadTagEntry;

  /// Semantic label for the backspace key, whose glyph is the erase-left character. It carries no role word: the platform already announces 'button' and the user would hear it twice (10 §3.2 rule 1).
  ///
  /// In en, this message translates to:
  /// **'Backspace'**
  String get keypadBackspace;

  /// onTapHint for backspace, so an assistive technology announces 'double tap to delete the last digit' rather than the generic verb. Singular DIGIT, deliberately: there is no key repeat, and a hint saying 'clear' would promise something the key does not do.
  ///
  /// In en, this message translates to:
  /// **'delete the last digit'**
  String get hintDeleteLastDigit;

  /// The bottom-right key when the pad is entering a tag — create-on-the-fly. Capitals because it is the control voice (indelible.md §3.1, as amended 2026-08-02): capitals and heavy weight mean 'a thing you can press', sentence case means 'it happened'.
  ///
  /// In en, this message translates to:
  /// **'NEW TAG'**
  String get keypadNewTag;

  /// Live region carrying the digits typed so far, announced as they change. The digits are spelled out rather than read as a number, because 412 is a name and not a quantity — a screen reader saying 'four hundred and twelve' has translated it into something the shepherd cannot match against the ear tag in their hand.
  ///
  /// In en, this message translates to:
  /// **'Entered tag {tag}'**
  String keypadEnteredTag({required String tag});

  /// The second live region. It carries the CLOSEST match as well as the count, because counting alone re-announces nothing when three matches become a different three matches — and the shepherd is listening for whether the animal in front of them is on the list.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No matches} =1{1 match, closest {tag}} other{{count} matches, closest {tag}}}'**
  String matchCountClosest({required int count, required String tag});

  /// The screen's headingLevel: 1 title. Quick Entry has NO level-2 headings (10 §3.4): it is one task, and heading stops would add navigation to a screen whose whole purpose is not having any.
  ///
  /// In en, this message translates to:
  /// **'Tonight'**
  String get quickEntryTitle;

  /// indelible.md §7.16 page header. {night} arrives PRE-FORMATTED as `d MMM y` from formatShedDate (10 §8.4 rule 4) — never format a date inside a message, and never render an all-numeric date (R60, decision #108). The widget applies toUpperCase(); do not store shouty caps here, because the caps are a typographic decision owned by the design system and Flutter has no text-transform.
  ///
  /// In en, this message translates to:
  /// **'Night of {night} · page {page}'**
  String quickEntryPageHeader({required String night, required int page});

  /// indelible.md §3.4's stamp: at most 12 characters, all-caps, and NEVER the sole carrier of its meaning — it sits beside a time that is obviously the current time. Safety rule §12.5: auto-captured time is labelled as such. The moment this stamp is the only thing distinguishing an auto time from an edited one, the sub-18px exemption is void.
  ///
  /// In en, this message translates to:
  /// **'AUTO'**
  String get quickEntryStampAuto;

  /// The bottom-left navigation anchor, 96x64. It is the ONLY navigation affordance in the app — P3's affordance half went to indelible.md, so there is no back chevron anywhere (decision record §7.0a). Capitals because it is the control voice.
  ///
  /// In en, this message translates to:
  /// **'INDEX'**
  String get quickEntryIndex;

  /// The corner slab's label before an animal is chosen (indelible.md §7.1). It is STILL a 160x140 target: pressing it opens the tag sheet rather than doing nothing, because a dead key under a cold thumb is indistinguishable from a missed tap. Never 'Select an animal' — the word is tag (CONVENTIONS §5.1).
  ///
  /// In en, this message translates to:
  /// **'Tag first'**
  String get quickEntrySlabTagFirst;

  /// The pens strip's empty state (07 §2.2). DISTINCT from the recents strip's, deliberately: a shared 'Nothing here yet' passes a careless test and tells a shepherd nothing about WHICH list is empty.
  ///
  /// In en, this message translates to:
  /// **'Nothing penned yet.'**
  String get quickEntryPennedEmpty;

  /// The recents strip's empty state (07 §2.2). Distinct from the pens strip's — see quickEntryPennedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent animals.'**
  String get quickEntryRecentsEmpty;

  /// Shown when the deck stream carries a failure. It names no code and no cause, because neither is actionable at 03:20.
  ///
  /// In en, this message translates to:
  /// **'The deck could not be read.'**
  String get quickEntryDeckUnavailable;

  /// The penned strip's trailing figure — elapsed PHYSICAL time from timeSincePenned, never two subtracted wall clocks. 03 §8 rule 1: a ewe penned at 22:00 before UK spring-forward and seen at 08:00 has been penned 9 hours, not 10.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String quickEntryHoursPenned({required int hours});

  /// The penned row's semantic label. It spells out 'hours' where the figure abbreviates to h, because a screen reader saying 'nine aitch' is not a duration.
  ///
  /// In en, this message translates to:
  /// **'Tag {tag}, in {pen}, penned {hours} hours'**
  String quickEntryPennedRowLabel({required String tag, required String pen, required int hours});

  /// The recents row's semantic label. It carries NO time, because the recents strip shows none (07 §5.2).
  ///
  /// In en, this message translates to:
  /// **'Tag {tag}'**
  String quickEntryRecentRowLabel({required String tag});

  /// The event button that begins a lambing. It is the product's central write: the tap commits the row BEFORE any screen is pushed, so the label names the event rather than an intention — never 'New lambing', never 'Record lambing'.
  ///
  /// In en, this message translates to:
  /// **'Lambing'**
  String get quickEntryLambing;

  /// The confirm key when the typed tag matches no active animal. Labelled with the OUTCOME, never a bare tick (06 §8.2): at 03:20 a tick asks the shepherd to remember what they were confirming.
  ///
  /// In en, this message translates to:
  /// **'Create {tag}'**
  String quickEntryConfirmCreate({required String tag});

  /// The confirm key when the typed tag matches an existing active animal. The counterpart to quickEntryConfirmCreate — the two words are the whole difference between finding an animal and making one.
  ///
  /// In en, this message translates to:
  /// **'Use {tag}'**
  String quickEntryConfirmUse({required String tag});

  /// The in-stream word button in the just-committed row's margin. STRIKE, never 'Undo': 07 §15.3 reserves 'Undo' for where the record DISAPPEARS, and after P1 the record never disappears — the row stays in position, legible, permanently marked. Capitals because it is the control voice.
  ///
  /// In en, this message translates to:
  /// **'STRIKE'**
  String get quickEntryStrike;

  /// The window, STATED IN SECONDS beside the affordance (P2). The number arrives as a placeholder read from kStrikeWindow.inSeconds and is NEVER typed into copy, so a changed constant changes the sentence rather than making it a lie. No copy anywhere may say 'you can undo this later' — there is no state restoration and the affordance is never rebuilt after a restart.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s to strike'**
  String quickEntryStrikeWindow({required int seconds});

  /// The stamp that REPLACES the strike word once the row is struck. It keeps indelible §3.4's sub-18px stamp exemption: at most 12 characters, all-caps, and never the sole carrier of its meaning — the 3px madder line across the row says it too. {at} is pre-formatted HH:mm by formatShedTime.
  ///
  /// In en, this message translates to:
  /// **'STRUCK {at}'**
  String quickEntryStruckAt({required String at});

  /// 04 §5.2. The media_assets row SURVIVES when its file does not; deleting the row would make the app lie by omission (spec §12.4) — the shepherd remembers taking the photo. {date} and {time} arrive PRE-FORMATTED from formatShedDate and formatShedTime; never format a date inside a message (10 §8.4 rule 4).
  ///
  /// In en, this message translates to:
  /// **'Photo taken {date} {time} — file no longer on this phone'**
  String photoMissingOnThisPhone({required String date, required String time});

  /// 06 §4.7. PERMANENT, not conditional. A shepherd looking at a photo of a prolapse needs the colour information, and a tinted view of tissue is useless. It is also what keeps the app on the right side of §12.2: it shows what was photographed and never interprets it.
  ///
  /// In en, this message translates to:
  /// **'Show in full colour'**
  String get photoShowInFullColour;

  /// The cell's semantic label. It carries the PROVENANCE as well as the time, because a screen-reader user has no margin stamp to read — the label is the only place §12.5's claim reaches them.
  ///
  /// In en, this message translates to:
  /// **'Photo taken {date} {time}, {provenance}'**
  String photoSemanticLabel({
    required String date,
    required String time,
    required String provenance,
  });

  /// The screen's headingLevel: 1 title. Lambing Entry deliberately has NO level-2 headings (10 §3.4): it is one task, and heading stops would add navigation to a screen whose whole purpose is not having any. The title still emits a level-1 node, because 12 §7.3's gate asserts at least one heading on every variant.
  ///
  /// In en, this message translates to:
  /// **'Lambing'**
  String get lambingEntryTitle;

  /// The lambs region's label. NOT a headingLevel — see lambingEntryTitle. It names the region for a screen-reader user without adding a navigation stop.
  ///
  /// In en, this message translates to:
  /// **'Lambs'**
  String get lambingEntryLambs;

  /// The care region's label. 'Care' rather than 'Treatments': a treatment is a medicine with a withdrawal period (§12.1) and care is colostrum, warming and drying. Merging the two words would put a withdrawal question on a screen that has none.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get lambingEntryCare;

  /// The DERIVED birth type. P8 abolished the chooser: the type is counted from the tally strokes and labelled so, which is what makes §12.4 structural rather than procedural — the app never declares a type the shepherd did not. The stamp is unboxed and all-caps; it is never the sole carrier of its meaning, because the strokes are on screen beside it.
  ///
  /// In en, this message translates to:
  /// **'{type} (COUNTED)'**
  String lambingTypeCounted({required String type});

  /// Five or more. countedBirthType returns null there deliberately — quintPlus means 'more than four, count NOT declared', and a counted five is not open-ended. So the count itself is printed rather than a word that would throw the number away. The animal noun comes from terminologyProvider, never a literal.
  ///
  /// In en, this message translates to:
  /// **'{count} {animals} (COUNTED)'**
  String lambingTypeCountedMany({required int count, required String animals});

  /// No strokes yet. NOT 'single': zero strokes is not recorded, and defaulting would be the app answering for the shepherd. It replaces 07 §6.3's 'the five buttons are unselected', which described a control P8 removed.
  ///
  /// In en, this message translates to:
  /// **'NOT RECORDED'**
  String get lambingTypeNotRecorded;

  /// The corner slab. One press is one stroke and one committed lamb row — there is no confirmation step, because the row is the confirmation. The animal noun comes from terminologyProvider (10 §8): a shepherd who renamed 'lamb' sees their own word.
  ///
  /// In en, this message translates to:
  /// **'+ {animal}'**
  String lambingAddLamb({required String animal});

  /// The tally's semantic label. The marks are painted, so a screen reader has nothing to read without this — and it says the NUMBER rather than describing the marks, because the number is what the shepherd wants.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No {animals} yet} =1{1 {animal}} other{{count} {animals}}}'**
  String lambingTallySemantics({
    required int count,
    required String animal,
    required String animals,
  });

  /// The lamb sub-row's leading cell. The ordinal is STROKE ORDER, not a name and not a tag: it is which lamb this was in this lambing, and it stays put when a later lamb is struck. Uppercased by the widget rather than in the string, so a locale whose script has no case is unharmed. The animal noun comes from the shepherd's own word.
  ///
  /// In en, this message translates to:
  /// **'{animal} {n}'**
  String lambingLambOrdinal({required String animal, required int n});

  /// LambStatus.alive. The schema default, and the only default in the lamb row that encodes nothing veterinary — a lamb that was born is alive until the shepherd says otherwise.
  ///
  /// In en, this message translates to:
  /// **'ALIVE'**
  String get lambStatusAlive;

  /// LambStatus.dead — died after birth. Distinct from stillborn, which is a different fact and a different line in every count. Never 'died at age 0' and never a cause: the cause is a separate record and may be unattributed.
  ///
  /// In en, this message translates to:
  /// **'DEAD'**
  String get lambStatusDead;

  /// LambStatus.stillborn — born dead. Never 'died at birth' and never 'dead-born'; stillborn is the word the trade and every count use.
  ///
  /// In en, this message translates to:
  /// **'STILLBORN'**
  String get lambStatusStillborn;

  /// LambStatus.sold — left the flock alive. It is a status rather than a deletion, because a sold lamb's history is exactly what year two is for.
  ///
  /// In en, this message translates to:
  /// **'SOLD'**
  String get lambStatusSold;

  /// The whole lamb sub-row as one utterance. The screen joins the cells with a comma and a space before passing them here, because a middot is read aloud as 'middle dot' by at least one screen reader and as nothing at all by another. The visible row keeps the middot; the voice gets punctuation it can pause on.
  ///
  /// In en, this message translates to:
  /// **'{parts}'**
  String lambRowSemantics({required String parts});

  /// The ease group's heading. One word, because the five buttons under it carry the meaning and a longer heading would push the group below the fold on a small phone.
  ///
  /// In en, this message translates to:
  /// **'EASE'**
  String get lambingEaseHeading;

  /// The ease group's unset state. NOT '0' and NOT 'unassisted': decision #59 makes an unscored lambing absent from both halves of the assisted rate, and inferring 'no assistance' would deflate that rate invisibly for years. SKIPPABLE is on the line because a shepherd at 03:20 needs to know they may walk away without answering.
  ///
  /// In en, this message translates to:
  /// **'NOT RECORDED · SKIPPABLE'**
  String get lambingEaseUnset;

  /// The ease group's container label for a screen reader. It says the range and that the group may be skipped. It does NOT say which value is selected — the buttons carry `selected:` and a screen reader announces state itself (10 §3.2 rule 2); a state word in a label is the doubled announcement users report as noise.
  ///
  /// In en, this message translates to:
  /// **'Ease, 1 to 5, not required'**
  String get lambingEaseGroupSemantics;

  /// One ease button's label. The ordinal and the description, and NO state word: 'Ease 3, selected' is the exact failure 10 §3.2 rule 2 names, because the node's own `selected` flag already says so.
  ///
  /// In en, this message translates to:
  /// **'Ease {ordinal}, {description}'**
  String lambingEaseValueSemantics({required int ordinal, required String description});

  /// One of the four frozen care kinds (key 'colostrum'). The label is the NOUN, not a claim: 'Colostrum' with a DONE stamp beside it says when the shepherd pressed it, which is a better record than a tick. Never 'Colostrum given?' - the line is not a question.
  ///
  /// In en, this message translates to:
  /// **'Colostrum'**
  String get careColostrum;

  /// Care kind 'navel_dip'. Two words, the trade term. Never 'Navel dipped' - the past tense would read as a claim on a line that has not been pressed.
  ///
  /// In en, this message translates to:
  /// **'Navel dip'**
  String get careNavelDip;

  /// Care kind 'stomach_tube'. Never 'Tubed', which is shed shorthand a screen reader cannot render, and never 'Tube fed', which is a different act.
  ///
  /// In en, this message translates to:
  /// **'Stomach tube'**
  String get careStomachTube;

  /// Care kind 'warmed'. Covers a warming box, a jacket or a hot box; the app records that it happened and never how, because how is not a field and inventing one would be the app asking a question at 03:20.
  ///
  /// In en, this message translates to:
  /// **'Warmed'**
  String get careWarmed;

  /// The done stamp. UNBOXED (indelible.md 7.10): DONE in the chrome voice, the time tabular beside it. The time is when the shepherd PRESSED IT, which is the fact being recorded - not when the care was planned and not when the lambing was.
  ///
  /// In en, this message translates to:
  /// **'DONE {time}'**
  String careDoneAt({required String time});

  /// The undone stamp, printed BESIDE the struck DONE stamp rather than replacing it (indelible.md 7.10, rule 1). Both times stay on the page: the shepherd pressed it at 03:24 and unpressed it at 03:31, and both are true.
  ///
  /// In en, this message translates to:
  /// **'UNDONE {time}'**
  String careUndoneAt({required String time});

  /// A care line that has not been pressed. NEVER 'No', NEVER 'Not given', NEVER '0' - decision #43 and 07 6.2: a shepherd who did not dip a navel has recorded NOTHING, and the app must not turn that into a claim. There is no way to record 'no' anywhere in this product, on purpose.
  ///
  /// In en, this message translates to:
  /// **'NOT RECORDED'**
  String get careNotRecorded;

  /// One care line as one utterance for a screen reader. The state is the not-recorded label or the done stamp - the same words the eye gets, so a support call about 'the third line' is about the same thing for both users.
  ///
  /// In en, this message translates to:
  /// **'{label}, {state}'**
  String careLineSemantics({required String label, required String state});

  /// The volume field's label, ABOVE the line in the control voice (indelible.md 7.12). It is never placeholder text inside the field: in the dark a grey placeholder is indistinguishable from an entered value. The field is empty until the shepherd types - no default, no suggested figure, no last-value autofill (05 7.3).
  ///
  /// In en, this message translates to:
  /// **'VOLUME'**
  String get colostrumVolumeLabel;

  /// The unit beside the volume field. Millilitres are the stored unit and the only one: volume_ml is canonical, and unlike weight there is no imperial alternative a UK shepherd would want for colostrum.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get colostrumVolumeUnit;

  /// The method group's label. Skippable, like the volume: a shepherd who fed colostrum without saying how has recorded the feed, which is the fact that matters at 03:20.
  ///
  /// In en, this message translates to:
  /// **'METHOD'**
  String get colostrumMethodLabel;

  /// ColostrumMethod.teat - the lamb sucked. The stored key is 'teat'.
  ///
  /// In en, this message translates to:
  /// **'Teat'**
  String get colostrumMethodTeat;

  /// ColostrumMethod.tube - stomach tube. The stored key is 'tube'. Distinct from the 'stomach_tube' CARE KIND, which records that tubing happened at all; this records how the colostrum went in.
  ///
  /// In en, this message translates to:
  /// **'Tube'**
  String get colostrumMethodTube;

  /// ColostrumMethod.bottle. The stored key is 'bottle'.
  ///
  /// In en, this message translates to:
  /// **'Bottle'**
  String get colostrumMethodBottle;

  /// One method button's label. The word and nothing else: the node carries `selected` and a screen reader announces state itself, so a state word here would be the doubled announcement 10 3.2 rule 2 names.
  ///
  /// In en, this message translates to:
  /// **'{word}'**
  String colostrumMethodSemantics({required String word});

  /// The sheet's commit button. NOT 'Save' and NOT 'Done': indelible.md 11 test 7 bans Save, and the word names the act - the care event itself was already committed by the line that opened this sheet, so this adds the detail rather than saving a draft.
  ///
  /// In en, this message translates to:
  /// **'RECORD'**
  String get colostrumRecord;

  /// The commit button for a screen reader. It says what is recorded, because RECORD alone does not say record what.
  ///
  /// In en, this message translates to:
  /// **'Record the colostrum detail'**
  String get colostrumRecordSemantics;

  /// The sheet's dismiss word (indelible.md 7.14). Never 'Cancel' - 07 15.5: Cancel is not a verb here, and nothing is lost by closing, because the care event is already recorded.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get colostrumSheetClose;

  /// The dismiss word for a screen reader. It says explicitly that closing loses nothing, because a shepherd who cannot see the page above needs to know the colostrum event is already recorded.
  ///
  /// In en, this message translates to:
  /// **'Close without adding a volume or a method'**
  String get colostrumSheetCloseSemantics;

  /// The modal barrier's label, required by showModalBottomSheet for accessibility.
  ///
  /// In en, this message translates to:
  /// **'Colostrum detail'**
  String get colostrumSheetBarrier;

  /// The margin query mark for a screen reader. It says WHAT was observed, because a bare '?' is unreadable aloud. Never 'Error' and never 'Warning' as a role word - the app observed something and is showing it, which is not the same as the app objecting.
  ///
  /// In en, this message translates to:
  /// **'Queried: {finding}'**
  String queryMarkSemantics({required String finding});

  /// The heading of the sheet a query mark opens. The observation voice: we found this, here it is. Never 'Problem', never 'Error', never 'Fix this' - 07 6.3 forbids a dialog and 12.2 forbids advice.
  ///
  /// In en, this message translates to:
  /// **'WHAT WE FOUND'**
  String get declareTypeHeading;

  /// The first of exactly two options. It writes a new declaration and LEAVES THE LAMBS ALONE - no lamb is added, none is struck, nothing is reconciled. The label names the act rather than the outcome, so it cannot be read as 'make this right'.
  ///
  /// In en, this message translates to:
  /// **'CHANGE THE BIRTH TYPE'**
  String get declareTypeChange;

  /// The second of exactly two options. It writes nothing to either value. It exists so that leaving it is an act the shepherd performs rather than something that happens when they walk away.
  ///
  /// In en, this message translates to:
  /// **'LEAVE IT'**
  String get declareTypeLeave;

  /// The line recorded when the shepherd chooses LEAVE IT. It is written as a NOTE against the lambing (decision #54: there is no warnings column and there never will be), so the answer survives the next open - an ephemeral line vanishes while the mark stays, which reads as the app forgetting what they said.
  ///
  /// In en, this message translates to:
  /// **'QUERIED · LEFT AS ENTERED {time}'**
  String declareTypeAcknowledged({required String time});

  /// BirthType.single, stored code 1. Used ONLY in the deliberate declaration sheet - the five-tap path derives birth type from the strokes and prints (COUNTED), and P8 abolished the chooser.
  ///
  /// In en, this message translates to:
  /// **'SINGLE'**
  String get birthTypeSingle;

  /// BirthType.twin, stored code 2. Declaration sheet only - see birthTypeSingle.
  ///
  /// In en, this message translates to:
  /// **'TWIN'**
  String get birthTypeTwin;

  /// BirthType.triplet, stored code 3. Declaration sheet only.
  ///
  /// In en, this message translates to:
  /// **'TRIPLET'**
  String get birthTypeTriplet;

  /// BirthType.quad, stored code 4. Declaration sheet only.
  ///
  /// In en, this message translates to:
  /// **'QUAD'**
  String get birthTypeQuad;

  /// BirthType.quintPlus, stored code 5, and the word is OPEN-ENDED on purpose. expectedLambCount returns null for it, so six lambs on a declared quintPlus is undefined rather than contradictory and prints NO query mark. Encoding it as exactly 5 would put a false mark on every set of sextuplets - the litters a shepherd is most likely to be looking at.
  ///
  /// In en, this message translates to:
  /// **'QUAD OR MORE'**
  String get birthTypeQuintPlus;

  /// Prefixes the ORIGINAL time on the header's second line - 'was 03:20'. It is the FIRST value, never the previous one: an unbounded chain of edits keeps what we first thought, because recording THAT a time was edited while losing WHAT IT WAS EDITED FROM makes the 12.5 label true and useless.
  ///
  /// In en, this message translates to:
  /// **'was'**
  String get provenanceWasPrefix;

  /// The header for a screen reader. The provenance travels with the time here exactly as it does on screen - a spoken time without its source would be the one place 12.5's claim goes silent. The provenance string is RecordedTime.provenanceLabel itself, never a second spelling of it.
  ///
  /// In en, this message translates to:
  /// **'Lambing time {time}, {provenance}'**
  String provenanceHeaderSemantics({required String time, required String provenance});

  /// onTapHint for the header. 07 6.4 gives this screen exactly one time-editing action and this is it. The verb is CORRECT rather than EDIT or CHANGE: the record is not wrong, the clock reading was.
  ///
  /// In en, this message translates to:
  /// **'correct the time this lambing happened'**
  String get provenanceEditHint;

  /// The time editor's heading. A question without a question mark, in the sheet's own voice. Never 'Set time' - the app is not setting anything, the shepherd is saying what they remember.
  ///
  /// In en, this message translates to:
  /// **'WHEN DID IT HAPPEN'**
  String get timeEditorHeading;

  /// How to type it. 24-hour because the whole app is (en_GB, HH:mm) and because 03:20 and 15:20 are a lambing apart. Four digits because the keypad has no colon key - the colon is punctuation the field adds, never something to type.
  ///
  /// In en, this message translates to:
  /// **'24-hour, four digits'**
  String get timeEditorHint;

  /// The commit button. Never 'Save' (indelible.md 11 test 7) and never 'OK'. An impossible time leaves this inert rather than clamping - silently turning 25:99 into 23:59 is 12.4.
  ///
  /// In en, this message translates to:
  /// **'CORRECT IT'**
  String get timeEditorConfirm;

  /// The commit button for a screen reader. It names what changes, because CORRECT IT alone does not say what.
  ///
  /// In en, this message translates to:
  /// **'Correct the lambing time to what you typed'**
  String get timeEditorConfirmSemantics;

  /// The assisted_by field's label, above the line. Free text, never a picker: the app has no people table, and inventing one would ask a shepherd to maintain a contacts list at 03:20. Never 'Assisted by' as a heading - the trade phrasing is who was with you.
  ///
  /// In en, this message translates to:
  /// **'WHO ELSE WAS THERE'**
  String get detailAssistedBy;

  /// The malpresentation picker's label. Plain words rather than the clinical noun, because the picker's own entries are the vocabulary and a heading that repeats it teaches nothing.
  ///
  /// In en, this message translates to:
  /// **'HOW IT WAS LYING'**
  String get detailPresentation;

  /// The presentation_note field's label, and it is DELIBERATELY SPECIFIC. Spec 7.2 lists lubricant/ropes/vet under assistance detail; 03 5.4 ships no column for it and the schema froze at N07-T08, so it lands here as free text. The label names the three so the next reader does not go looking for a column or propose one. A structured version is a v2 migration, not a widget.
  ///
  /// In en, this message translates to:
  /// **'ROPES, LUBRICANT, VET'**
  String get detailPresentationNote;

  /// The lambing's own note column. Distinct from a notes ROW, which is the attachment-bearing kind NoteRepository owns.
  ///
  /// In en, this message translates to:
  /// **'ANYTHING ELSE'**
  String get detailNote;

  /// Every detail field's unset state. SKIPPABLE is on the line because a shepherd at 03:20 needs to know they may walk away without answering - the tally is the record, and everything after it is detail. Never a placeholder inside the field (indelible.md 7.12): in the dark a grey placeholder is indistinguishable from an entered value.
  ///
  /// In en, this message translates to:
  /// **'NOT RECORDED · SKIPPABLE'**
  String get detailUnset;

  /// The presentation group's container label. It says the field may be skipped and does NOT say which word is selected - the buttons carry `selected` and a screen reader announces state itself (10 3.2 rule 2).
  ///
  /// In en, this message translates to:
  /// **'How it was lying, not required'**
  String get detailPresentationSemantics;

  /// The Lamb Card's heading, headingLevel 1. It is the animal noun and the tag when there is one - never 'Lamb details' or 'Lamb record', because the shepherd came here from a row that already said which lamb.
  ///
  /// In en, this message translates to:
  /// **'{animal}'**
  String lambCardTitle({required String animal});

  /// The birth dam row. A lamb has ONE birth dam, forever - no verb in the app moves it. A foster moves the REARING dam, and making a foster look like a rewrite of history is the failure the lamb_rearing view exists to prevent.
  ///
  /// In en, this message translates to:
  /// **'BIRTH DAM {tag}'**
  String lambCardBirthDam({required String tag});

  /// The rearing dam row, projected by the lamb_rearing view and never copied onto the lamb. On an unfostered lamb it is the birth dam, which is what the view's COALESCE says and is NOT the same as having no rearing dam.
  ///
  /// In en, this message translates to:
  /// **'REARING DAM {tag}'**
  String lambCardRearingDam({required String tag});

  /// Marks a foster whose outcome was recorded as permanent. It is a fact about the foster event, never a judgement about the lamb.
  ///
  /// In en, this message translates to:
  /// **'PERMANENT'**
  String get lambCardPermanent;

  /// One of the TWO reasons a rearing dam can be absent, and 07 7.2 forbids rendering them with one string. This one is a fact the shepherd recorded: the lamb came off a ewe and onto a bottle.
  ///
  /// In en, this message translates to:
  /// **'ON THE BOTTLE'**
  String get lambCardNoEweBottle;

  /// The OTHER reason a rearing dam can be absent: the lamb was removed from a ewe and where it went was not recorded. Merging this with ON THE BOTTLE would have the app claim a bottle feed that nobody wrote down.
  ///
  /// In en, this message translates to:
  /// **'REARING DAM NOT RECORDED'**
  String get lambCardNoEweNotRecorded;

  /// The history list when only the birth row exists. NOT an empty state - the born row is always there, because a lamb that exists was born. It says nothing ELSE, which is the true statement.
  ///
  /// In en, this message translates to:
  /// **'NOTHING ELSE RECORDED YET'**
  String get lambCardNothingElseRecorded;

  /// A lamb with no tag yet, which is most lambs for most of their first week. Never a blank and never a generated number: a tag the app invented would be a tag on no ear.
  ///
  /// In en, this message translates to:
  /// **'UNTAGGED'**
  String get lambCardUntagged;

  /// The 'born' arm of the history union. Always present - it is the one row a lamb card can never be missing.
  ///
  /// In en, this message translates to:
  /// **'BORN'**
  String get lambCardHistoryBorn;

  /// The 'foster' arm. Past tense because it is an event that happened, not a state the lamb is in.
  ///
  /// In en, this message translates to:
  /// **'FOSTERED'**
  String get lambCardHistoryFoster;

  /// The 'care' arm - a care event recorded against this lamb rather than against the lambing.
  ///
  /// In en, this message translates to:
  /// **'CARE'**
  String get lambCardHistoryCare;

  /// The 'treatment' arm. The withdrawal that may hang off it is the treatment record's own business and is never summarised here.
  ///
  /// In en, this message translates to:
  /// **'TREATMENT'**
  String get lambCardHistoryTreatment;

  /// The sex group's label on the Lamb Card. Three targets, not two: not-recorded is reached by clearing, and recorded-as-unknown is its own answer.
  ///
  /// In en, this message translates to:
  /// **'SEX'**
  String get lambCardSexLabel;

  /// Sex.unknown, and the words are chosen to be UNMISTAKABLE for not-recorded (R45). The shepherd LOOKED and could not say - which is a fact worth keeping, and merging it with an empty field would have the app answer a question they deliberately left open. Never 'Unknown' alone, which reads like a missing value.
  ///
  /// In en, this message translates to:
  /// **'COULD NOT TELL'**
  String get lambCardSexUnknown;

  /// The weight cell's label, above the line. One word, the trade's own.
  ///
  /// In en, this message translates to:
  /// **'BIRTHWEIGHT'**
  String get lambCardWeightLabel;

  /// The weight cell before anything is typed. Never a zero and never a placeholder figure: 05 7.3 - the app may transform a number the shepherd supplied, never originate one.
  ///
  /// In en, this message translates to:
  /// **'NOT RECORDED · SKIPPABLE'**
  String get lambCardWeightUnset;

  /// The kg suffix beside the weight keypad. The unit comes from unitsProvider (R68), never from the locale: a UK smallholder may genuinely want lb, and a wrong inference silently mislabels every weight ever recorded.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get lambCardWeightUnitKg;

  /// The lb suffix. Entry is in whole pounds and the decimal key adds a fraction of one; the decomposition into ounces happens at display, where poundsOunces rounds once and carries at sixteen.
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get lambCardWeightUnitLb;

  /// The implausible-birthweight observation. It says WHAT WE OBSERVED and never what to do - a warning that instructs is advice (12.2) and a warning that changes a value is a correction (12.4). It NEVER blocks the write: a blocked write produces a lost record, which is worse than a queried one. Never 'too heavy', never 'please check', never a suggested figure. It also carries NO ANIMAL NOUN: 10 8.5 keeps domain nouns out of sentences because they vary by county, and l10n_bootstrap_test.dart caught the first draft of this message for saying 'for a lamb'. There is no placeholder to use here either, because the string is a Warning.message from lib/domain/, which cannot reach terminologyProvider.
  ///
  /// In en, this message translates to:
  /// **'That is outside the usual birthweight range.'**
  String get warningImplausibleBirthWeight;

  /// The status group's label. Three targets - alive, dead, stillborn - because those are the three the shepherd records at the shed. SOLD is set elsewhere, from the flock list, and putting it here would offer a sale as a thing that happens in a lambing pen.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get lambCardStatusLabel;

  /// The death date's label. One word, because the three quick answers under it carry the meaning.
  ///
  /// In en, this message translates to:
  /// **'WHEN'**
  String get lambCardDeathDateLabel;

  /// The commonest answer, first. A death recorded at the shed is almost always today's, and 07 7.3 puts the three quick answers ahead of the stepper so the usual case is one tap.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get lambCardDeathDateToday;

  /// The second quick answer. It exists because a shepherd who finds a dead lamb at 06:00 often means the night before.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get lambCardDeathDateYesterday;

  /// The third quick answer, and the last: beyond this the stepper is more honest than another word, because 'THREE DAYS AGO' and 'FOUR DAYS AGO' are guesses dressed as buttons.
  ///
  /// In en, this message translates to:
  /// **'2 DAYS AGO'**
  String get lambCardDeathDateTwoDaysAgo;

  /// The death cause's label. The list is user-editable vocabulary (vocab_terms, list='death_cause'), never a fixed enum: causes vary by farm and by county.
  ///
  /// In en, this message translates to:
  /// **'CAUSE'**
  String get lambCardDeathCauseLabel;

  /// No cause recorded. This is UNATTRIBUTED, and it is NOT the same as the dc_unknown term the shepherd can pick - a lamb died and nobody wrote down why is a different fact from a lamb died and the shepherd recorded that the cause was unknown. The vocabulary keeps them apart and so does this label.
  ///
  /// In en, this message translates to:
  /// **'NOT RECORDED'**
  String get lambCardDeathCauseUnattributed;

  /// The deathBeforeBirth observation, and it is the ARB copy of a string the domain also holds - lib/domain/ ships English because v1 is en-only (#108). It says what we observed and never what to do: it does not say 'check the date' and it does not offer to swap them. It never blocks the write, because a blocked write produces a lost record and this one is about a lamb that died.
  ///
  /// In en, this message translates to:
  /// **'The death date is before the lambing.'**
  String get warningDeathBeforeBirth;

  /// The pet-lamb toggle's label. The trade phrase, not 'Pet lamb status': a shepherd says a lamb is on the bottle. Clearing it does NOT zero the feed count - which lambs cost six weeks of bottles is exactly the April question, and a lamb weaned off the bottle is still a lamb that was on it.
  ///
  /// In en, this message translates to:
  /// **'ON THE BOTTLE'**
  String get lambCardPetLambLabel;

  /// The bottle-feed counter's label. It counts feeds, and the total is the stored fact: indelible.md 8 asks for a timestamped FEED 4 - 06:40 line per feed, and no table can hold one (care_events.kind is a closed CHECK wired to frozen notification channel ids). Printing that line from a counter would invent a timestamp the record does not have.
  ///
  /// In en, this message translates to:
  /// **'FEEDS'**
  String get lambCardFeedsLabel;

  /// The feed count before the lamb is marked as on the bottle. It is NOT a zero: bottle_feeds has DEFAULT 0 and that column's 0 means 'no feeds recorded', while pet_lamb is what says whether the count is meaningful at all. A confident 0 on a lamb nobody bottle-fed would be the app originating a number the shepherd never pressed.
  ///
  /// In en, this message translates to:
  /// **'NOT RECORDED · SKIPPABLE'**
  String get lambCardFeedsUnset;

  /// The increment target's glyph. There is no minus: a feed that happened cannot un-happen, and a decrement would be an undo for an event rather than a correction of a value. If a mis-tap needs undoing that is a screens decision, not a local one.
  ///
  /// In en, this message translates to:
  /// **'+'**
  String get lambCardFeedsAdd;

  /// The increment target for a screen reader. A bare '+' is unreadable aloud, and the label says what is counted.
  ///
  /// In en, this message translates to:
  /// **'Record one more bottle feed'**
  String get lambCardFeedsAddSemantics;

  /// The Foster screen's heading, headingLevel 1. The verb, not 'Foster lamb' - the shepherd arrived here from a lamb and already knows which one.
  ///
  /// In en, this message translates to:
  /// **'FOSTER'**
  String get fosterTitle;

  /// One ewe target in the match list. ONE TAP COMMITS - there is no confirm step, because 07 8.2's budget is one tap and spec 7.3 names this as the flow most likely to be abandoned if it takes five. The tag is the ewe's, and it is what the shepherd reads off the ear.
  ///
  /// In en, this message translates to:
  /// **'ONTO {tag}'**
  String fosterOnto({required String tag});

  /// The to_bottle outcome, and it is a DELIBERATE fact: the shepherd put this lamb on a bottle. It is NOT the same as the removed-from-a-ewe outcome beside it, and merging the two would change a season's rearing-credit figures silently - which is why setRearingDam(LambId, EweId?) is a banned signature (07 8.4 rule 1).
  ///
  /// In en, this message translates to:
  /// **'ONTO THE BOTTLE'**
  String get fosterToBottle;

  /// The removed_unknown outcome. The lamb came off a ewe and where it went was not written down - null BY OMISSION, where the bottle outcome is null BY INTENT. The label says both halves out loud so the two can never be read as the same button. The animal noun is a PLACEHOLDER: 10 8.5 keeps domain nouns out of sentences because they vary by county, and l10n_bootstrap_test.dart caught the first draft of this message for spelling it.
  ///
  /// In en, this message translates to:
  /// **'OFF THE {animal} · WHERE NOT RECORDED'**
  String fosterRemovedUnknown({required String animal});

  /// The match list before enough digits are typed. NOT an error and NOT an empty state: the shepherd is mid-tag, and a screen that said 'not found' after two digits would be arguing with someone who has not finished.
  ///
  /// In en, this message translates to:
  /// **'NO MATCH YET'**
  String get fosterNoMatch;

  /// Printed on the Foster screen so the shepherd can see that fostering does not rewrite the birth dam. It is the product's own promise made visible at the moment it matters: a lamb has one birth dam forever, and lamb_birth_dam_is_immutable is the trigger that holds it.
  ///
  /// In en, this message translates to:
  /// **'BIRTH DAM {tag} · UNCHANGED'**
  String fosterBirthDamNote({required String tag});

  /// The fosterToSelf observation. It says WHAT WE OBSERVED and never what to do, and it NEVER blocks: fostering a lamb onto the ewe she is already on is a thing a shepherd does at 03:20 by mistake, and refusing it would lose the record of an action they took. The comparison is against the CURRENT REARING DAM, never the birth dam - after a foster to B, fostering the lamb back to her birth dam is not a self-foster at all. BOTH nouns are placeholders: 10 8.5 keeps domain nouns out of sentences because they vary by county, and l10n_bootstrap_test.dart caught the first draft for spelling 'ewe'.
  ///
  /// In en, this message translates to:
  /// **'That {animal} is already on this {dam}.'**
  String warningFosterToSelf({required String animal, required String dam});

  /// The elapsed-hours readout on a pen tile. Truncated, never rounded: a ewe penned 59 minutes ago has been in there for 0h, and the readout is only worth having if it is not flattering. Tabular figures, so twelve tiles line up.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String penTileHours({required int hours});

  /// The ready status word. It means settled for at least the SHEPHERD'S OWN threshold - never a recommendation to turn out, which would be advice (12.2). The dagger in the margin and the doubled rule carry the same fact without colour.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get penTileReady;

  /// The attention status. It prints the withdrawal's CLEAR DATE, which is the fact the shepherd needs - never 'do not turn out', which would be an instruction. Attention outranks ready because turning out a ewe still under withdrawal is the mistake this app exists to prevent.
  ///
  /// In en, this message translates to:
  /// **'CLEAR {date}'**
  String penTileAttention({required String date});

  /// The loss status word, printed in full ink in the lamb column. It carries NO COLOUR CHANNEL AT ALL, ever: a colour-coded death reads wrong at 4am through a wet freezer bag, and 10 5.2 has no status palette to use anyway.
  ///
  /// In en, this message translates to:
  /// **'DEAD'**
  String get penTileLoss;

  /// An empty pen. It is a STATUS, not an absence - the pen with nothing in it is the pen the shepherd is about to use, so it is drawn rather than omitted. The dotted rule where the value would be is the second channel.
  ///
  /// In en, this message translates to:
  /// **'— empty —'**
  String get penTileEmpty;

  /// One tile as one utterance. The label is the number chalked on the hurdle; the state is the same words the eye gets, so a support call about 'pen 3' is about the same thing for both users.
  ///
  /// In en, this message translates to:
  /// **'Pen {label}, {state}'**
  String penTileSemantics({required String label, required String state});

  /// The add-pen target. ONE TAP, no wizard and no naming step: the shepherd is standing in front of a pen at 03:20 and asking what to call it is asking for a decision they do not have. The number is chosen for them and renaming happens in daylight.
  ///
  /// In en, this message translates to:
  /// **'+ PEN'**
  String get penBoardAddPen;

  /// The add-pen target for a screen reader. A bare plus is unreadable aloud.
  ///
  /// In en, this message translates to:
  /// **'Add a pen'**
  String get penBoardAddPenSemantics;

  /// The pen board grid container label. One word: the shepherd got here from a named destination and the tiles carry the meaning.
  ///
  /// In en, this message translates to:
  /// **'PENS'**
  String get penBoardTitle;

  /// The withdrawal control's label. The target is meat or milk and they are asked separately, because one entered period implies nothing about the other. Never 'withholding', never 'WHP', never 'the days' - CONVENTIONS 5 fixes the word.
  ///
  /// In en, this message translates to:
  /// **'WITHDRAWAL — {target}'**
  String withdrawalLabel({required String target});

  /// WithdrawalTarget.meat. The stored key is 'meat'.
  ///
  /// In en, this message translates to:
  /// **'MEAT'**
  String get withdrawalTargetMeat;

  /// WithdrawalTarget.milk. The stored key is 'milk'. R75 keeps it in the v1 schema even though few flocks milk.
  ///
  /// In en, this message translates to:
  /// **'MILK'**
  String get withdrawalTargetMilk;

  /// The days choice. The label names WHERE THE NUMBER COMES FROM - the bottle in the shepherd's hand - because 12.1 is that the app never originates one. There is no placeholder inside the field and no prefill: in the dark a grey figure is indistinguishable from an entered one, and a prefilled 28 is a clinical decision the app made.
  ///
  /// In en, this message translates to:
  /// **'DAYS OFF THE BOTTLE'**
  String get withdrawalEnterDays;

  /// WithdrawalNotApplicable - the label says no withdrawal applies. It is a RECORDED FACT, something the shepherd read, and NOT the same as nobody writing a number down.
  ///
  /// In en, this message translates to:
  /// **'NONE APPLIES'**
  String get withdrawalNotApplicable;

  /// WithdrawalNotRecorded. Absence IS the state and it stores no row at all. It is NOT pre-selected: a control that pre-selects this is as wrong as one that prefills 28, because it makes a decision the shepherd did not make.
  ///
  /// In en, this message translates to:
  /// **'NOT RECORDED'**
  String get withdrawalNotRecorded;

  /// The unit beside the days keypad. Days, always - 05 4.4 fixes the unit even for milk, where a different milking frequency could be argued, because one unit is one thing to get wrong.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get withdrawalUnit;

  /// Printed when the stored clear date and a recomputation disagree - which happens when the device changed timezone between the write and the read. BOTH numbers are shown and NEITHER is updated: 12.4 forbids silently correcting a user's entry, and the stored one is what the shepherd was told and may have written in a book. The line says nothing was changed, in as many words, and there is no control offering to reconcile them - offering would make the app the arbiter of a clinical date.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been changed. The stored clear date is shown first; the second is what today\'s arithmetic gives.'**
  String get withdrawalDisagrees;

  /// Labels the stored clear date, which renders FIRST because it is the one the shepherd was told and the one in the book.
  ///
  /// In en, this message translates to:
  /// **'STORED {date}'**
  String withdrawalStored({required String date});

  /// Labels the recomputed date, shown second and only when it disagrees. It is an observation, never an offer: there is no button beside it.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S ARITHMETIC {date}'**
  String withdrawalRecomputed({required Object date});

  /// The screen's heading, headingLevel 1. Spec 7.9 calls export a SAFETY feature rather than a convenience, because there is no cloud: this screen is the only backup the shepherd has.
  ///
  /// In en, this message translates to:
  /// **'EXPORT'**
  String get exportTitle;

  /// Above the buttons, on the first painted frame. It says what an export IS, in the shepherd's words. It deliberately does NOT say what an export is not - that is Disclaimers.exportFooter's job, referenced beneath it and never re-typed. The first draft said 'it is not a compliance record' and the anchor test refused it: the banned phrases are banned in OUR prose too, including in a sentence that denies them, because a screen that argues with the disclaimer is a second wording somebody will improve.
  ///
  /// In en, this message translates to:
  /// **'This is your notebook\'s contents, as you recorded them. Nothing is sent anywhere: the file goes to the share sheet and you choose where it goes.'**
  String get exportWhatThisIs;

  /// 07 13.3 rows 1 and 2, as ONE message with the noun as a placeholder. The first draft spelled LAMB and EWE into two separate messages and l10n_bootstrap_test refused both: a domain noun in a message value is a noun a shepherd cannot rename, and these vary by county before they vary by country. The word CSV stays literal because a shepherd who is going to open the file in a spreadsheet needs to know that is what it is.
  ///
  /// In en, this message translates to:
  /// **'CSV - ONE ROW PER {term}'**
  String exportCsvRow({required String term});

  /// 07 13.3 row 3. It is the medicine record in spreadsheet form; the PDF version ships in v1.1.0 (P15) and this row is what covers it until then.
  ///
  /// In en, this message translates to:
  /// **'CSV - ONE ROW PER TREATMENT'**
  String get exportCsvTreatments;

  /// One tap for all three CSVs, which is what a shepherd exporting at the end of a day actually wants - three separate share sheets is three chances to send the wrong one.
  ///
  /// In en, this message translates to:
  /// **'EXPORT ALL THREE'**
  String get exportCsvAll;

  /// The counts, READ and never estimated. No LIMIT, no sampling, no 'about 400' - a count the shepherd can compare against their own flock list is a count that has to be right. The two animal nouns are PLACEHOLDERS fed from Terminology (10 8.5): a shepherd who renamed ewe to gimmer sees gimmers here, and a literal noun in an ARB value is what l10n_bootstrap_test refuses. Treatment is not an animal class and stays a literal.
  ///
  /// In en, this message translates to:
  /// **'{eweCount} {ewePlural}, {lambCount} {lambPlural}, {treatments} treatments'**
  String exportCounts({
    required int eweCount,
    required String ewePlural,
    required int lambCount,
    required String lambPlural,
    required int treatments,
  });

  /// The honest status line before the first export. It does NOT say 'a lost phone is lost data' - that wording is banned unqualified - and it does not nag; it states a fact the shepherd can act on.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been exported from this phone yet.'**
  String get exportNeverExported;

  /// The honest status line after an export. It is the date the SHARE SHEET reported, not the date the file was written: a file assembled and then dismissed did not leave the phone.
  ///
  /// In en, this message translates to:
  /// **'Last exported {date}.'**
  String exportLastExported({required String date});

  /// On the row that was tapped, and on no other. 07 13.2: the screen never blocks and never covers itself with a modal, and there is no spinner anywhere under lib/features/.
  ///
  /// In en, this message translates to:
  /// **'Building...'**
  String get exportBuilding;

  /// The failure line, in the row that failed. It names the artefact, because a shepherd with three rows needs to know which one - and it says nothing was sent, because the alternative is a shepherd who believes a file left the phone when it did not.
  ///
  /// In en, this message translates to:
  /// **'{artefact} could not be built. Nothing was sent.'**
  String exportFailed({required String artefact});

  /// The spoken form of one export row: what it produces and how much of it. The count is spoken because a screen reader user cannot glance at the number beside the label.
  ///
  /// In en, this message translates to:
  /// **'{label}, {count} records'**
  String exportSemantics({required String label, required int count});

  /// 07 16.3. It states a fact and asks nothing. There is no 'you should' and no 'we recommend' - copy.vet_advice bans the first and 12.2's origination line bans the app having an opinion about how often somebody ought to export.
  ///
  /// In en, this message translates to:
  /// **'You have not exported since {date}.'**
  String exportBannerHeadline({required String date});

  /// The same banner before there is any export to date. A blank date or the word 'never' in the dated sentence would both read as a bug.
  ///
  /// In en, this message translates to:
  /// **'You have not exported from this phone.'**
  String get exportBannerNeverHeadline;

  /// The count is READ, never estimated. The second sentence is the qualified form of spec 7.9's warning: 'a lost phone is lost data' UNQUALIFIED is banned (CLAUDE.md), because it is only true if they have not exported - and this banner exists precisely to make that qualification actionable.
  ///
  /// In en, this message translates to:
  /// **'{count} records since then. A lost phone is lost records unless you export.'**
  String exportBannerCount({required int count});

  /// Pushes the Export screen and STARTS NO WORK. A banner action that begins a share is a banner that has decided for the shepherd which artefacts they wanted.
  ///
  /// In en, this message translates to:
  /// **'EXPORT NOW'**
  String get exportBannerAct;

  /// Writes export_prompt_dismissed_for_season and the banner never appears again this season. There is NO third 'later' action and no close X: not answering is already free, and a dismiss-for-now button would be a third decision at the one moment the app promised not to ask for any.
  ///
  /// In en, this message translates to:
  /// **'NOT THIS SEASON'**
  String get exportBannerDismiss;

  /// Shown when formatVersion or schema in the file is higher than this build can read. DO NOT soften this to 'may not be compatible': guessing at a newer schema is spec 12.4 applied to restore, and a partial import would destroy records rather than decline to touch them. 09 5.5.
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer version of Shed Book. Update the app and try again.'**
  String get restoreRefusedNewerApp;

  /// The second line under restoreRefusedNewerApp. Named numbers, so a shepherd on the phone to a friend can say which build wrote the file. It NEVER replaces the sentence above it - a pair of version numbers with no sentence is a screen that has told somebody their records are unreachable without telling them what to do.
  ///
  /// In en, this message translates to:
  /// **'This file: format {foundFormat}, records {foundSchema}. This app reads format {readsFormat}, records {readsSchema}.'**
  String restoreRefusedNewerAppDetail({
    required int foundFormat,
    required int foundSchema,
    required int readsFormat,
    required int readsSchema,
  });

  /// A different sentence from restoreRefusedDamaged on purpose: 'this is not ours' and 'this is ours and it is damaged' send a shepherd to two different next steps - find the right file, versus find an older copy.
  ///
  /// In en, this message translates to:
  /// **'This is not a Shed Book backup file.'**
  String get restoreRefusedNotOurs;

  /// Ours, and a required header key is missing or the wrong type. It does not say 'try again' - re-picking the same file will not help, and a shepherd who has just been told their backup is damaged should not be sent in a circle.
  ///
  /// In en, this message translates to:
  /// **'This Shed Book backup is damaged and cannot be read.'**
  String get restoreRefusedDamaged;

  /// On the backup row of the Export screen. FNV-1a is a CORRUPTION check: it finds a truncated download, a half-written file and a bad card, and it finds nothing an author intended. Six words are banned from this message and from every file near it - see offline_wording_test.dart - because a shepherd who reads one of them has been told their backup is proof against something it is not proof against at all. The second sentence exists so the first cannot be read as more than it is.
  ///
  /// In en, this message translates to:
  /// **'Each backup carries a check that finds a truncated or damaged file. It does not protect the file from being changed.'**
  String get backupIntegrityLine;

  /// Shown when the checksum or a per-table count disagrees. The second sentence is the load-bearing one: a shepherd who has just been told a restore failed needs to know whether their current records survived it, and the answer is always yes because the restore builds a new file beside the live one. It does NOT say 'try again' - re-picking the same damaged file will not help.
  ///
  /// In en, this message translates to:
  /// **'This backup file is incomplete and has not been restored. Nothing on this phone has changed.'**
  String get backupRefusedIncomplete;

  /// Shown when the picked file starts with the ZIP magic bytes. Media is not part of a v1 backup (decision 85), so a photo archive is never restorable. It names what was picked AND what was expected; never 'invalid file', which at 2am is not an instruction.
  ///
  /// In en, this message translates to:
  /// **'This looks like a photo archive. Shed Book restores the records file (.json).'**
  String get restoreRefusedZip;

  /// Shown for a file starting 'SQLite format 3'. That is the VACUUM INTO snapshot from Settings, Diagnostics - deliberately not an in-app restore path (04 2.8). tool/snapshot_to_backup.dart converts it, and that is a developer tool rather than a code path on a phone.
  ///
  /// In en, this message translates to:
  /// **'This is a diagnostics copy of a database, not a backup. It cannot be restored in the app.'**
  String get restoreRefusedDatabaseCopy;

  /// The catch-all for an unrecognised first byte - most often a photo the shepherd renamed. It says what to pick INSTEAD, because a refusal that names no next step leaves somebody holding a phone at 2am with nothing to try.
  ///
  /// In en, this message translates to:
  /// **'This file is not a Shed Book backup. Choose the .json file the app shared when you exported.'**
  String get restoreRefusedNotABackup;

  /// 04 7.3 statement 1 - WHAT YOU ARE ABOUT TO GAIN. It is first because a shepherd deciding whether to restore is deciding whether the backup is the right one, and they cannot judge that from a filename.
  ///
  /// In en, this message translates to:
  /// **'{seasons} seasons, {ewes} ewes, {lambs} lambs, {treatments} treatments. Made on {date} by Shed Book {version}.'**
  String restoreBackupSummary({
    required int seasons,
    required int ewes,
    required int lambs,
    required int treatments,
    required String date,
    required String version,
  });

  /// 04 7.3 statement 2 - WHAT YOU ARE ABOUT TO LOSE. Read with COUNT(*) from the live database at the moment the sheet opens, NEVER from the header: rendering the backup's numbers under this heading is the one bug that makes the whole confirmation a lie, and it looks right in every screenshot.
  ///
  /// In en, this message translates to:
  /// **'{seasons} seasons, {ewes} ewes, {lambs} lambs, {treatments} treatments.'**
  String restoreLiveSummary({
    required int seasons,
    required int ewes,
    required int lambs,
    required int treatments,
  });

  /// 04 7.3 statement 3. 'Cannot be undone FROM INSIDE THE APP' is exact and is not softened: the old database is kept for one launch by the rollback file, so a developer can recover it - and a shepherd cannot. Saying 'cannot be undone' flat would be a smaller truth than the one available.
  ///
  /// In en, this message translates to:
  /// **'Restoring will delete everything now on this phone and replace it with the backup. This cannot be undone from inside the app.'**
  String get restoreDestruction;

  /// 04 7.3 statement 4 - WHAT THIS DOES NOT INCLUDE, said BEFORE the controls rather than after the restore. Media is records-only by decision 85, and a shepherd who learns that afterwards has been told too late to choose differently.
  ///
  /// In en, this message translates to:
  /// **'Photos and voice notes are not part of a backup. {count} were recorded on the other phone and will show as \"not on this phone\".'**
  String restoreMediaNotice({required int count});

  /// Step one of two. It commits to nothing; it unlocks step two. Two steps rather than one because a single 72pt button under a wall of text is one cold thumb away from destroying a season.
  ///
  /// In en, this message translates to:
  /// **'I UNDERSTAND - CONTINUE'**
  String get restoreStepOne;

  /// Step two, 72pt, DISABLED until step one is taken, and on the OPPOSITE side of the screen from Cancel. It says what it does rather than 'OK' or 'Confirm' - a shepherd reading only the buttons still learns the outcome.
  ///
  /// In en, this message translates to:
  /// **'REPLACE EVERYTHING'**
  String get restoreReplaceEverything;

  /// Always live, always reachable, and never the destructive side. Backing out of a destruction confirmation is the expected answer, not the exceptional one.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get restoreCancel;

  /// 04 7.6. A statement, not a celebration - no tick, no 'Success!'. The shepherd asked for their records and here they are.
  ///
  /// In en, this message translates to:
  /// **'Your records are back.'**
  String get restoreDoneTitle;

  /// 04 7.6 verbatim, and one of the two places in the product where the app admits a limitation in full sentences rather than in a shortened label. It says where the photos ARE, not only that they are absent - a shepherd who reads 'not included' assumes they are gone.
  ///
  /// In en, this message translates to:
  /// **'{count} photos and voice notes were recorded on the other phone. Photos are not part of a backup in this version - they stay on the phone that took them. Each one still shows in the record it belongs to, marked \"not on this phone\".'**
  String restoreDoneMedia({required int count});

  /// The screen's heading, headingLevel 1.
  ///
  /// In en, this message translates to:
  /// **'TREATMENTS'**
  String get treatmentsTitle;

  /// The countdown segment. It shows what is still under withdrawal - the question at the gate, 'can she go?'. It is the segment the screen OPENS on, because the book is what they open in the office. Never 'Active' and never 'Current': running is what a withdrawal does.
  ///
  /// In en, this message translates to:
  /// **'RUNNING'**
  String get treatmentsModeCountdown;

  /// The medicine-book segment. indelible.md 8 screen 8: the book is not a separate view, it is the book filtered to treatments. It shows voided rows too, struck and marked, because a voided treatment may already be printed in a book handed to a vet.
  ///
  /// In en, this message translates to:
  /// **'BOOK'**
  String get treatmentsModeBook;

  /// The voided stamp in book mode. The row STAYS and is struck rather than removed - 12.3 and 09 3.2: the export marks voided rows rather than dropping them, because the app must never disagree with a book somebody already has.
  ///
  /// In en, this message translates to:
  /// **'VOIDED {date}'**
  String treatmentsVoided({required String date});

  /// The countdown line. It prints the STORED clear date and never recomputes one. There is no 'she is clear' copy anywhere: leaving the countdown is not the same as claiming a negative, and only the shepherd and their vet can say the second.
  ///
  /// In en, this message translates to:
  /// **'CLEARS {date}'**
  String treatmentsClears({required String date});

  /// WithdrawalUnknown on a treatment row - no withdrawal row exists at all. Absence IS the state (12.1) and it says so - it does NOT say the animal is clear, which would be the app answering a clinical question nobody asked it. 10 5.2 names this word: NOT RECORDED, never 0 and never blank. It is NOT the same as treatmentsNotApplicable, and the row that printed one sentence for both was the defect that split them.
  ///
  /// In en, this message translates to:
  /// **'NOT RECORDED'**
  String get treatmentsNoWithdrawal;

  /// The line above a countdown, naming WHO and WHICH TARGET. The target is spelled on every countdown because one product routinely prints a meat figure and a milk figure, and a countdown with no target named is a number a shepherd could apply to the wrong one.
  ///
  /// In en, this message translates to:
  /// **'{tag} · {target}'**
  String treatmentsCountdown({required String tag, required String target});

  /// The spoken form of one countdown row. It does NOT speak the day tally - the tally and the figure are the same fact in two channels, and a screen reader that read both would say the number twice.
  ///
  /// In en, this message translates to:
  /// **'{tag}, {target}, {product}, clears {date}'**
  String treatmentsCountdownSemantics({
    required String tag,
    required String target,
    required String product,
    required String date,
  });

  /// NoWithdrawal on a treatment row - the shepherd read the label and it said none applies. A RECORDED FACT, and the whole reason it cannot share a word with treatmentsNoWithdrawal: one is something somebody read, the other is a gap nobody filled. 10 5.2 row 8.
  ///
  /// In en, this message translates to:
  /// **'NOT APPLICABLE'**
  String get treatmentsNotApplicable;

  /// Opens the repeat flow. It shows the previous entry WITH its provenance so the shepherd can read what they entered last time, and the withdrawal days are NOT carried across - copying them would make the app the source of a clinical figure for a treatment nobody read a label for (12.1).
  ///
  /// In en, this message translates to:
  /// **'REPEAT LAST'**
  String get treatmentsRepeatLast;

  /// One animal target in the repeat flow. One tap commits, which is the second of the two taps 07 10 budgets.
  ///
  /// In en, this message translates to:
  /// **'ONTO {tag}'**
  String treatmentsRepeatOnto({required String tag});

  /// The empty state. Not an error and not a prompt: a flock that has treated nothing has treated nothing, and the screen says so rather than inviting them to start.
  ///
  /// In en, this message translates to:
  /// **'NOTHING RECORDED YET'**
  String get treatmentsEmpty;

  /// A treatment on a lamb with no tag yet, which is most lambs for most of their first week. Never a blank and never a generated number.
  ///
  /// In en, this message translates to:
  /// **'UNTAGGED'**
  String get treatmentsUntagged;
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
