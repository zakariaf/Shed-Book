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
