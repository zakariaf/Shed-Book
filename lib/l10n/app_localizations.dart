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

  /// 07 §5.3. Quick Entry is NEVER empty (§2.2) — the deck and the keypad are always there — so this line is about the page, not the screen, and it says what is true rather than inviting an action the slab already offers.
  ///
  /// In en, this message translates to:
  /// **'NOTHING RECORDED TONIGHT'**
  String get tonightEmpty;

  /// One line of tonight's page: the tag, then the lamb tally's count. The noun is not written — the strokes beside it are what say lambs, and a word here would be the second thing saying it.
  ///
  /// In en, this message translates to:
  /// **'{tag} · {count}'**
  String tonightRow({required String tag, required String count});

  /// An animal with no tag is a real state and prints as a word. It is never blank: a gap reads as missing data, and this is a fact somebody recorded.
  ///
  /// In en, this message translates to:
  /// **'UNTAGGED'**
  String get tonightUntagged;

  /// indelible-marks-and-strikes §6: an UNBOXED stamp, because it is a note about the RECORD rather than a state of the animal. The row keeps its position and its legibility — nothing is removed.
  ///
  /// In en, this message translates to:
  /// **'STRUCK'**
  String get tonightStruck;

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

  /// indelible.md §7.17 line 1. Quick Entry, named for what it is rather than for the screen — the shepherd is already on it, and the line closes the sheet.
  ///
  /// In en, this message translates to:
  /// **'TONIGHT'**
  String get indexTonight;

  /// §7.17 line 2. Every animal, in one list — the screen a shepherd opens in year two to ask what 412 did last year.
  ///
  /// In en, this message translates to:
  /// **'FLOCK'**
  String get indexFlock;

  /// §7.17 line 3. `THE PENS` and not `PEN BOARD`: the shepherd is going to the pens, not to a board.
  ///
  /// In en, this message translates to:
  /// **'THE PENS'**
  String get indexPens;

  /// §7.17 line 4. The word `treatments` is the code's; `MEDICINE BOOK` is what a shepherd calls the thing they show an inspector.
  ///
  /// In en, this message translates to:
  /// **'MEDICINE BOOK'**
  String get indexMedicineBook;

  /// indelible.md §7.17 line 7. It pushes Export rather than exporting: the index is a map of the book, and a line that DID something would be the one line in it that is not a place.
  ///
  /// In en, this message translates to:
  /// **'EXPORT'**
  String get indexExport;

  /// §7.17 line 8, and the last. It is the only line the design draws with no summary beside it, because there is no count to give — settings are settings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get indexSettings;

  /// The index sheet's dismiss word.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get indexClose;

  /// Spoken hint on the index sheet's dismiss target.
  ///
  /// In en, this message translates to:
  /// **'Close the index'**
  String get indexCloseHint;

  /// The margin's SHORT stamp for a time the shepherd typed. indelible-page-and-screens §1.2: an 18px caps-tracked word does not fit the 68px margin cell — six characters is already ~84px — so the long provenance label ('time entered by you') prints in the RECORD COLUMN and the margin keeps only AUTO / ENTERED / EDITED at --t-stamp. Both say the same fact; neither replaces the other.
  ///
  /// In en, this message translates to:
  /// **'ENTERED'**
  String get quickEntryStampEntered;

  /// The margin's short stamp for an edited time (indelible.md §8: the AUTO stamp is replaced by EDITED, and BOTH times stay). Safety rule §12.5 with nothing hidden — the original is never overwritten, in the record or the export.
  ///
  /// In en, this message translates to:
  /// **'EDITED'**
  String get quickEntryStampEdited;

  /// The corner slab's label before an animal is chosen (indelible.md §7.1). It is STILL a 160x140 target: pressing it opens the tag sheet rather than doing nothing, because a dead key under a cold thumb is indistinguishable from a missed tap. Never 'Select an animal' — the word is tag (CONVENTIONS §5.1).
  ///
  /// In en, this message translates to:
  /// **'Tag first'**
  String get quickEntrySlabTagFirst;

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

  /// Event word 2 of 5 on §8's event line. The word is the EVENT, not an intention — never 'Add treatment', never 'Treat'.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get quickEntryEventTreatment;

  /// Event word 3 of 5 on §8's event line.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get quickEntryEventNote;

  /// Event word 4 of 5. The word is plain and it stays plain: 'Loss', 'Casualty' and 'Mortality' are all softer than the fact, and a record that is coy about a dead lamb is a record somebody has to decode a year later.
  ///
  /// In en, this message translates to:
  /// **'Death'**
  String get quickEntryEventDeath;

  /// Event word 5 of 5. Two words, matching indelible.md §8's MOVE PEN — never 'Pen', which reads as a noun.
  ///
  /// In en, this message translates to:
  /// **'Move pen'**
  String get quickEntryEventMovePen;

  /// The event line's group label for a screen reader. It names the QUESTION the five words answer, so the group is announced once and each word is not prefixed with 'event'.
  ///
  /// In en, this message translates to:
  /// **'What happened'**
  String get quickEntryEventLine;

  /// The corner slab once an animal is chosen (indelible.md §8): one press, one of them, one stroke in the tally. It is the product's central act. Never '+ Add' and never 'New' — the plus already says add. The noun is USER-EDITABLE from the terminology overlay (10 §8.5) and arrives as a placeholder; never hard-code it.
  ///
  /// In en, this message translates to:
  /// **'+ {term}'**
  String quickEntrySlabAddLamb({required String term});

  /// Spoken label on the live row's tag cell — the target that opens the tag sheet (§8: 'Tap the TAG cell. The sheet rises 160ms into the bottom half.'). The visible cell shows the tag or the prompt; this says what pressing it does.
  ///
  /// In en, this message translates to:
  /// **'Choose an animal'**
  String get quickEntryTagCell;

  /// What the live row's tag cell prints before an animal is chosen. A word in the pixels the tag will occupy — never a placeholder inside a field, and never blank, because a blank reads as missing data rather than as nothing-chosen-yet.
  ///
  /// In en, this message translates to:
  /// **'TAG'**
  String get quickEntryTagPrompt;

  /// The tag sheet's heading line (indelible.md §8: 'TAG · 3 MATCHES · IN THE PENS FIRST'). It states the count so a shepherd knows whether the list below is everything.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Tag · no matches} =1{Tag · 1 match} other{Tag · {count} matches}}'**
  String quickEntryTagSheetHeading({required int count});

  /// The sheet's LAST PRINTED LINE, present even when there are matches (indelible.md §8): 'at 3am the ewe you are holding might genuinely be a tag you have never entered and the app must never stop to make you go and set something up first.' Never a modal, never a confirm.
  ///
  /// In en, this message translates to:
  /// **'No such tag — write {tag} into the book'**
  String quickEntryTagSheetCreate({required String tag});

  /// The create line before any digit is typed, when there is no tag to write into the book. It names both routes because pressing a listed animal is the common case and costs one tap.
  ///
  /// In en, this message translates to:
  /// **'Type a tag, or press one above'**
  String get quickEntryTagSheetCreateEmpty;

  /// The second half of the tag sheet's heading, printed only while the list is the recents rather than typed matches. indelible.md §8 orders penned animals first because a ewe in a pen is the one you are most likely to be standing in front of at 03:20.
  ///
  /// In en, this message translates to:
  /// **'In the pens first'**
  String get quickEntryTagSheetPennedFirst;

  /// A sheet row's summary for a penned animal (indelible.md §8: '412 · penned 2h · pen 4'). Naming the pen is what makes a row worth pressing rather than reading — it is how a shepherd tells two similar tags apart.
  ///
  /// In en, this message translates to:
  /// **'In {pen}'**
  String quickEntryTagSheetInPen({required String pen});

  /// A sheet row's summary for an animal in the recents bucket rather than a pen. It states what the deck actually knows and NOT a history it has not read — never 'lambed yesterday · twins' unless that was queried.
  ///
  /// In en, this message translates to:
  /// **'Seen recently'**
  String get quickEntryTagSheetSeenRecently;

  /// The tag sheet before the deck has been read — frame 1, when the database has not opened yet (decision #21). DISTINCT from the empty copy, and the distinction is the day-one bug: an empty list means the book WAS read and there is nothing in it, and collapsing the two tells a shepherd on their first night that the app lost their flock.
  ///
  /// In en, this message translates to:
  /// **'Reading the book…'**
  String get quickEntryTagSheetReading;

  /// The tag sheet when the deck has been read and is genuinely empty. It never blocks: the create line below is still there, which is how the first ewe of the first season gets written.
  ///
  /// In en, this message translates to:
  /// **'No animals in the book yet'**
  String get quickEntryTagSheetNoAnimals;

  /// The tag sheet's dismiss word (indelible.md §7.16's 88x64 CLOSE). Never 'Cancel' — nothing is being cancelled, the sheet just goes away and the digits stay.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get quickEntryTagSheetClose;

  /// Spoken hint on the tag sheet's dismiss target.
  ///
  /// In en, this message translates to:
  /// **'Close the tag sheet'**
  String get quickEntryTagSheetCloseHint;

  /// Birth type derived from one stroke (P8 — there is no chooser anywhere). Sentence case, because it prints as a value in the record voice rather than as a stamp.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get quickEntryDerivedSingle;

  /// Birth type derived from two strokes.
  ///
  /// In en, this message translates to:
  /// **'Twin'**
  String get quickEntryDerivedTwin;

  /// Birth type derived from three strokes.
  ///
  /// In en, this message translates to:
  /// **'Triplet'**
  String get quickEntryDerivedTriplet;

  /// Four or more strokes. English has no single word past triplet that a shepherd uses, and inventing 'quadruplet' would be the app choosing a term the terminology table cannot edit. The plural noun is user-editable and arrives as a placeholder (10 §8.5); ICU cannot pluralise a runtime string, so the caller supplies the plural form.
  ///
  /// In en, this message translates to:
  /// **'{count} {term}'**
  String quickEntryDerivedMultiple({required int count, required String term});

  /// The unboxed stamp beside a derived birth type (indelible.md §6, ruling P8). Unboxed because it is a note about the RECORD, not a state of the animal. It is what turns safety rule §12.4 from a validation routine into structure: the app never picked, it counted.
  ///
  /// In en, this message translates to:
  /// **'COUNTED'**
  String get quickEntryDerivedStamp;

  /// The event button that begins a lambing. It is the product's central write: the tap commits the row BEFORE any screen is pushed, so the label names the event rather than an intention — never 'New lambing', never 'Record lambing'.
  ///
  /// In en, this message translates to:
  /// **'Lambing'**
  String get quickEntryLambing;

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

  /// The lambs region's label. NOT a headingLevel — see lambingEntryTitle. It names the region for a screen-reader user without adding a navigation stop. THE NOUNS ARE PLACEHOLDERS, NOT LITERALS (10 §8.5): they vary by county — ewe, gimmer, theave — and a shepherd who renamed them must see their own word here too. This one especially: it is read while deciding whether to destroy their records.
  ///
  /// In en, this message translates to:
  /// **'{term}'**
  String lambingEntryLambs({required String term});

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

  /// 07 §7. The photo action on a lambing. The whole chain — pick, compress, write, attach — landed at N15 with tests and fakes and nothing joined it up, so a shepherd could not photograph a lambing.
  ///
  /// In en, this message translates to:
  /// **'PHOTO'**
  String get lambingEntryPhoto;

  /// 07 §7. Starts a voice note on a lambing. The chain — permission, start, stop, complete — landed at N15 with tests and had no caller.
  ///
  /// In en, this message translates to:
  /// **'VOICE NOTE'**
  String get lambingEntryVoiceStart;

  /// Ends the recording. A separate word rather than a toggle: at 03:20 a control that means two things depending on a state you cannot see is a control that records nothing or never stops.
  ///
  /// In en, this message translates to:
  /// **'STOP'**
  String get lambingEntryVoiceStop;

  /// Printed while the recorder reports sound above the noise floor. It is the only feedback a shepherd gets that the microphone is not muffled by a coat — and it is a WORD rather than a waveform, because §6 has six marks and none of them is a meter.
  ///
  /// In en, this message translates to:
  /// **'HEARING YOU'**
  String get lambingEntryVoiceHearing;

  /// The other half. Silence during a voice note is worth saying out loud: the recording is still running and still being written, and the shepherd is the only one who can tell whether that is right.
  ///
  /// In en, this message translates to:
  /// **'NOT HEARING ANYTHING'**
  String get lambingEntryVoiceSilent;

  /// Shown when the camera could not be reached at all — no camera on the device, or the picker threw. It states the fact and names the consequence, because the shepherd's real question is whether anything was saved. NOT shown when they simply backed out of the picker: that is a decision, not a failure, and rendering it as an error tells somebody they did something wrong when they did not.
  ///
  /// In en, this message translates to:
  /// **'The camera did not open. Nothing was written.'**
  String get lambingEntryPhotoFailed;

  /// Shown when the recorder threw after the row was opened. DISTINCT from lambingEntryVoiceNoPermission: 'no microphone' is answerable (the OS prompt), 'it did not start' is not, and collapsing them would send a shepherd to a settings screen that cannot help.
  ///
  /// In en, this message translates to:
  /// **'The recording did not start. Nothing was written.'**
  String get lambingEntryVoiceFailed;

  /// Shown when `hasPermission` is false. It states the fact and asks for nothing — the OS prompt is another process and appears once, on first use.
  ///
  /// In en, this message translates to:
  /// **'The microphone is not available.'**
  String get lambingEntryVoiceNoPermission;

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

  /// 07 §9.5. The heading over the deck in an empty pen — the only thing an empty pen can be asked.
  ///
  /// In en, this message translates to:
  /// **'WHICH ANIMAL'**
  String get penSheetPenAnimal;

  /// indelible.md §6: every action is a WORD, and this is one of the five the design names. `turn out` is the verb, `turn-out` the adjective, and `turnout` is never written (CLAUDE.md).
  ///
  /// In en, this message translates to:
  /// **'TURN OUT'**
  String get penSheetTurnOut;

  /// 07 §9.5. A ewe moved to a bigger pen has not been turned out — `moved` is its own exit reason and the entered time carries forward.
  ///
  /// In en, this message translates to:
  /// **'MOVE PEN'**
  String get penSheetMove;

  /// 07 §9.6. The §12.5 edit path on a penning time: the board marks the corrected row EDITED and keeps the captured time beside it, because a time the shepherd corrected is a fact about the record and travels with it.
  ///
  /// In en, this message translates to:
  /// **'CORRECT THE TIME'**
  String get penSheetCorrectTime;

  /// One destination row in the move list. It names the consequence rather than the act.
  ///
  /// In en, this message translates to:
  /// **'MOVE TO PEN {label}'**
  String penSheetMoveTo({required String label});

  /// 07 §9.5. Not an error state — a free pen before lambing starts is the commonest thing on the board.
  ///
  /// In en, this message translates to:
  /// **'THIS PEN IS EMPTY'**
  String get penSheetEmpty;

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

  /// 09 §5. The JSON backup — the only file a restore reads. Deliberately not called an export in the button: the three CSVs above are exports, for somebody else's software, and this is the file that comes back. A shepherd who confuses the two loses the provenance quad, the withdrawal rows and every strike, silently.
  ///
  /// In en, this message translates to:
  /// **'SAVE A BACKUP'**
  String get exportBackup;

  /// 09 §5, printed under the backup button. It says the two things a shepherd has to know and no more: a backup is complete and a CSV is not, and a backup that never leaves the phone it was made on protects nothing. It must never claim the file is verified or secure — offline_wording_test refuses both words in this file.
  ///
  /// In en, this message translates to:
  /// **'A backup holds everything, in the form this app reads back. The three files above hold what a spreadsheet reads. Keep a backup somewhere other than this phone.'**
  String get exportBackupWhat;

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

  /// 04 7.3 statement 1 - WHAT YOU ARE ABOUT TO GAIN. It is first because a shepherd deciding whether to restore is deciding whether the backup is the right one, and they cannot judge that from a filename. THE NOUNS ARE PLACEHOLDERS, NOT LITERALS (10 §8.5): they vary by county — ewe, gimmer, theave — and a shepherd who renamed them must see their own word here too. This one especially: it is read while deciding whether to destroy their records.
  ///
  /// In en, this message translates to:
  /// **'{seasons} seasons, {ewes} {eweTerm}, {lambs} {lambTerm}, {treatments} treatments. Made on {date} by Shed Book {version}.'**
  String restoreBackupSummary({
    required int seasons,
    required int ewes,
    required int lambs,
    required int treatments,
    required String date,
    required String version,
    required String eweTerm,
    required String lambTerm,
  });

  /// 04 7.3 statement 2 - WHAT YOU ARE ABOUT TO LOSE. Read with COUNT(*) from the live database at the moment the sheet opens, NEVER from the header: rendering the backup's numbers under this heading is the one bug that makes the whole confirmation a lie, and it looks right in every screenshot. THE NOUNS ARE PLACEHOLDERS, NOT LITERALS (10 §8.5): they vary by county — ewe, gimmer, theave — and a shepherd who renamed them must see their own word here too. This one especially: it is read while deciding whether to destroy their records.
  ///
  /// In en, this message translates to:
  /// **'{seasons} seasons, {ewes} {eweTerm}, {lambs} {lambTerm}, {treatments} treatments.'**
  String restoreLiveSummary({
    required int seasons,
    required int ewes,
    required int lambs,
    required int treatments,
    required String eweTerm,
    required String lambTerm,
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

  /// 07 §10.4, two taps. A SOFT void: the medicine book keeps the row and marks it, because nothing is removed from this book (indelible.md rule 1). The word is `void` and never `delete` — the only two honest deletes in the product are in Settings.
  ///
  /// In en, this message translates to:
  /// **'VOID THIS'**
  String get treatmentsVoid;

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

  /// 07 §10.4 row 1. The entry that N20's seven tasks never built — every one of them is the countdowns, the clear date, the repeat sheet or the void.
  ///
  /// In en, this message translates to:
  /// **'NEW TREATMENT'**
  String get treatmentNewTitle;

  /// 07 §10.4: every field except the animal is skippable, so this is the only heading in the sheet over something required.
  ///
  /// In en, this message translates to:
  /// **'WHICH ANIMAL'**
  String get treatmentNewAnimal;

  /// The spoken label on one animal row in the new-treatment sheet. It names the consequence — which animal the treatment lands on — rather than the act.
  ///
  /// In en, this message translates to:
  /// **'Treat {tag}'**
  String treatmentNewOnto({required String tag});

  /// 07 §10.4. Free text, because the app ships no product database and never will: decision #51 rejects a medicines lookup outright, since a withdrawal period can change for the same medicine and differ between products with the same active ingredient.
  ///
  /// In en, this message translates to:
  /// **'PRODUCT'**
  String get treatmentNewProduct;

  /// 07 §10.4, skippable. NO UNIT HINT in the field — a pre-filled `ml` is the app suggesting a unit it does not know. The label carries what is wanted; the field carries only what they typed.
  ///
  /// In en, this message translates to:
  /// **'DOSE'**
  String get treatmentNewDose;

  /// 07 §10.4, skippable. Free text off the bottle, and the app never validates its shape: batch formats vary by manufacturer and a refused batch number is a record nobody could make.
  ///
  /// In en, this message translates to:
  /// **'BATCH NUMBER'**
  String get treatmentNewBatch;

  /// 07 §10.4, skippable. A closed list from `vocab_terms`, never free text — typing it would make `rt_subcutaneous` and `sub cut` two different routes in the export.
  ///
  /// In en, this message translates to:
  /// **'ROUTE'**
  String get treatmentNewRoute;

  /// The committing tap. It names the act, not a tick: at 03:20 a tick asks the shepherd to remember what they were confirming.
  ///
  /// In en, this message translates to:
  /// **'RECORD THIS TREATMENT'**
  String get treatmentNewCommit;

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

  /// 07 §3.2 Empty. The flock has no active ewes at all.
  ///
  /// In en, this message translates to:
  /// **'No animals yet.'**
  String get flockEmpty;

  /// 07 §3.2 Filtered-empty. Its own state: 'No animals yet' shown to a shepherd with 400 ewes and a filter on says their flock is gone.
  ///
  /// In en, this message translates to:
  /// **'No animals match these filters.'**
  String get flockFilteredEmpty;

  /// 07 §3.2. The flock list could not be read at all — a damaged database, not an empty one. It is deliberately not the empty state: 'no ewes yet' and 'we could not look' are different facts and a shepherd acts differently on each.
  ///
  /// In en, this message translates to:
  /// **'The flock could not be read.'**
  String get flockUnavailable;

  /// Semantics label for a flock row.
  ///
  /// In en, this message translates to:
  /// **'Tag {tag}'**
  String flockRowLabel({required String tag});

  /// 07 §3.2 / indelible.md §8 Screen 1. The filter line's first word — tapping it clears every filter.
  ///
  /// In en, this message translates to:
  /// **'ALL {count}'**
  String flockFilterAll({required int count});

  /// In lamb and still waiting: an ewe_seasons row of to_ram or scanned, and no lambing this season. NOT the same question as barren (R42).
  ///
  /// In en, this message translates to:
  /// **'NOT YET LAMBED {count}'**
  String flockFilterNotYetLambed({required int count});

  /// An open pen_occupancies row. 'penned', never 'housed' (CONVENTIONS §5.1).
  ///
  /// In en, this message translates to:
  /// **'IN THE PENS {count}'**
  String flockFilterCurrentlyPenned({required int count});

  /// A live treatment still running OR one whose withdrawal nobody recorded — unknown is never clear (ruling N1, spec §12.1).
  ///
  /// In en, this message translates to:
  /// **'UNDER TREATMENT {count}'**
  String flockFilterUnderTreatment({required int count});

  /// Three or more lambs on a single lambing.
  ///
  /// In en, this message translates to:
  /// **'TRIPLET-BEARING {count}'**
  String flockFilterTripletBearing({required int count});

  /// ewe_seasons.status = 'barren' (R42). 'barren', never 'empty' or 'not in lamb' (CONVENTIONS §5.1).
  ///
  /// In en, this message translates to:
  /// **'BARREN {count}'**
  String flockFilterBarren({required int count});

  /// The filter line's first word while the list is still loading. The count is omitted rather than shown as 0 — unknown is not zero (#58).
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get flockFilterAllUnknown;

  /// indelible.md §7.7's unboxed stamp for the §12.4 contradiction badge. A WORD, not an icon — this system has no icon set (§1.3), and 07 §3.4's 'icon + count' is superseded by ruling N3.
  ///
  /// In en, this message translates to:
  /// **'QUERIED'**
  String get flockStampQueried;

  /// indelible.md §7.7's boxed form — a state of the ANIMAL, not a note about the record. She stays in the list (§7.4); the stamp says why she is at the bottom.
  ///
  /// In en, this message translates to:
  /// **'CULLED'**
  String get flockStampCulled;

  /// indelible.md §7.4's printed line: the ewes who have left the flock sit at the bottom under it. An em dash, not a hyphen, and the count is the number below the line.
  ///
  /// In en, this message translates to:
  /// **'STRUCK — {count}'**
  String flockStruckDivider({required int count});

  /// The record column's sentence on a lambing row. A past-tense statement of what happened, never a heading and never a count — the tally is its own mark.
  ///
  /// In en, this message translates to:
  /// **'Lambed'**
  String get eweCardRowLambing;

  /// The treatment row. {product} is the shepherd's own typed product name (§12.4 — exactly as typed, never normalised); this app ships no medicine database.
  ///
  /// In en, this message translates to:
  /// **'Treated with {product}'**
  String eweCardRowTreatment({required String product});

  /// The care row. The kind is a stored key rendered through the terminology overlay at the presentation edge.
  ///
  /// In en, this message translates to:
  /// **'{kind}'**
  String eweCardRowCare({required String kind});

  /// The foster row. It names the act, not a direction — a foster is one rearing dam and an outcome, and 'she lost a lamb' is a reading of the previous rearing dam rather than a stored fact.
  ///
  /// In en, this message translates to:
  /// **'Fostered'**
  String get eweCardRowFoster;

  /// The observation row. WHAT WAS OBSERVED, never a consequence: 'Prolapse' is a record, 'prolapse risk' is a diagnosis (§12.2). The label is the shepherd's own when they have renamed the term.
  ///
  /// In en, this message translates to:
  /// **'{observation}'**
  String eweCardRowObserved({required String observation});

  /// The pen row. {pen} is the pen's own label, which the shepherd typed.
  ///
  /// In en, this message translates to:
  /// **'Penned in {pen}'**
  String eweCardRowPenned({required String pen});

  /// The note row. The shepherd's own words, verbatim and never truncated (10 §5).
  ///
  /// In en, this message translates to:
  /// **'{body}'**
  String eweCardRowNote({required String body});

  /// Printed beside the provenance label on an EDITED row. 05 §4.3: an edited row shows BOTH times. The paired SQL CHECK — (time_source = 'edited') = (original_effective IS NOT NULL) — exists precisely so the pre-edit value is always there to show, and omitting it makes the §12.5 label true and uninformative. {time} arrives pre-formatted as 24-hour HH:mm.
  ///
  /// In en, this message translates to:
  /// **'was {time}'**
  String eweCardRowEditedFrom({required String time});

  /// indelible.md §7.3's margin stamp on a struck row. The row STAYS in position, stays legible, and carries the time it was struck. 24-hour HH:mm, pre-formatted.
  ///
  /// In en, this message translates to:
  /// **'STRUCK {time}'**
  String eweCardRowStruck({required String time});

  /// The withdrawal figure on a treatment row. ZERO IS A REAL LABEL VALUE — products genuinely print zero-day withdrawals — so =0 is an explicit case and never falls through to the not-recorded wording. Always rendered beside Disclaimers.withdrawalProvenance, which is referenced and never re-typed.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{0 day withdrawal} =1{1 day withdrawal} other{{days} day withdrawal}}'**
  String eweCardWithdrawalDays({required num days});

  /// The label explicitly states no withdrawal applies. A recorded ANSWER, distinct from zero days and distinct from 'I did not look' — three states, never two.
  ///
  /// In en, this message translates to:
  /// **'No withdrawal'**
  String get eweCardWithdrawalNotApplicable;

  /// No treatment_withdrawals row exists: nobody typed one. §12.1 — never a default, never 0, never blank. indelible.md §5: an unset value prints a dotted rule and the words NOT RECORDED, because a blank reads as missing data and a dotted rule reads as nothing happened.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal — NOT RECORDED'**
  String get eweCardWithdrawalNotRecorded;

  /// One row, one spoken sentence, in the order a shepherd would say it. 10 §3.2 rule 3: the spoken row and the visible row agree on the visible words. Seven Text widgets is seven rotor stops per row and about eighty rows on a five-season card.
  ///
  /// In en, this message translates to:
  /// **'{time}. {body}. {provenance}'**
  String eweCardRowSemantics({
    required String time,
    required String body,
    required String provenance,
  });

  /// The card's headingLevel 1 title. {singularTerm} is a USER-EDITABLE noun from the terminology overlay (ewe/gimmer/theave/...). Never derive the plural by appending an s (10 §8.5) — both forms come from TermLabel.
  ///
  /// In en, this message translates to:
  /// **'{singularTerm} {tag}'**
  String eweCardTitle({required String singularTerm, required String tag});

  /// Clause 1 of the ewe card summary line (spec §7.7). A count of seasons in which this animal has a recorded lambing. Never a judgement. The =0 case is what a ewe created ten seconds ago reads, because ewe_summaries has no row for her yet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No seasons recorded} =1{1 season} other{{count} seasons}}'**
  String eweCardSummarySeasons({required num count});

  /// Clause 2. Average litter size for THIS animal: lambs born divided by her recorded lambings (05 §6.5) — never divided by seasons. {average} arrives pre-formatted to one decimal by lib/core/ui/formatters.dart, never formatted inside this message (10 §8.4 rule 4). Omitted entirely when not computable; never rendered as 0.0.
  ///
  /// In en, this message translates to:
  /// **'avg {average}'**
  String eweCardSummaryAverage({required String average});

  /// Clause 3. Lambings with a recorded ease of 2 or more (05 §6.7). The =1 and =2 cases are explicit because 'assisted 2 times' is not English. Unscored lambings are excluded from both sides and are named by eweCardSummaryAssistedCoverage; a blank ease is NEVER read as unassisted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{never assisted} =1{assisted once} =2{assisted twice} other{assisted {count} times}}'**
  String eweCardSummaryAssisted({required num count});

  /// Appended to clause 3 only when some lambings have no ease score. 05 §6.7: coverage is always reported when it is partial, because a blank ease read as unassisted deflates the number.
  ///
  /// In en, this message translates to:
  /// **'of {scored} scored'**
  String eweCardSummaryAssistedCoverage({required num scored});

  /// Clause 4. The most recent recorded observation and the year of the season it was recorded in — e.g. 'prolapsed 2025'. {observation} is the USER-EDITABLE vocab_terms label for an ewe_observation key; never hard-code it and never translate it. It states WHAT WAS OBSERVED, never a consequence: 'prolapsed 2025' is a record, 'prolapse risk' is a diagnosis (§12.2).
  ///
  /// In en, this message translates to:
  /// **'{observation} {year}'**
  String eweCardSummaryObservation({required String observation, required String year});

  /// The whole summary line as ONE spoken string. The visual separator is a middle dot, which a screen reader swallows; this joins the clauses with a full stop so each is spoken. One node, not four — four means four rotor stops in front of the one line the screen exists to deliver (10 §3.4).
  ///
  /// In en, this message translates to:
  /// **'{clauses}'**
  String eweCardSummarySemantics({required String clauses});

  /// The page header. 07 §16's sticky 44 px header — read-only, never collapses, never parallaxes.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// The kilogram half of the units segmented line (indelible.md §8 screen 12). A DISPLAY choice only: the database stores grams and nothing is rewritten when it changes (#56).
  ///
  /// In en, this message translates to:
  /// **'KG'**
  String get settingsUnitsWeightKg;

  /// The pound half. Rendered as pounds and ounces, because a shepherd who works in pounds does not think in tenths of one.
  ///
  /// In en, this message translates to:
  /// **'LB'**
  String get settingsUnitsWeightLb;

  /// The spoken form of each segment. NO STATE WORD IN IT (10 §3.2 rule 2): the node carries `selected` and a screen reader announces the state itself, so 'Kilograms, selected' is the doubled announcement users report as noise.
  ///
  /// In en, this message translates to:
  /// **'Weight in {unit}'**
  String settingsUnitsWeightSemantics({required String unit});

  /// The spoken noun for kg. Written out because a screen reader reads 'KG' as two letters.
  ///
  /// In en, this message translates to:
  /// **'kilograms'**
  String get settingsUnitsWeightKgSpoken;

  /// The spoken noun for lb. Written out because a screen reader reads 'LB' as two letters.
  ///
  /// In en, this message translates to:
  /// **'pounds'**
  String get settingsUnitsWeightLbSpoken;

  /// R35's frozen palette id 'night'. The default: warm off-white ink on near-black. There is no light theme and no system-follow — the app is dark only, on both platforms.
  ///
  /// In en, this message translates to:
  /// **'NIGHT'**
  String get settingsPaletteNight;

  /// R35's frozen palette id 'amber'. Shifts the ink warm for a shepherd who finds the default too cool under a head torch.
  ///
  /// In en, this message translates to:
  /// **'AMBER'**
  String get settingsPaletteAmber;

  /// R35's frozen palette id 'red' — note the STORED key is 'red' and the label is two words. Red-shift for night vision: it overrides token values and nothing else, because nothing in this app was ever encoded by hue.
  ///
  /// In en, this message translates to:
  /// **'DEEP RED'**
  String get settingsPaletteDeepRed;

  /// The spoken form of each palette choice. No state word in it (10 §3.2 rule 2): the node carries `selected` and announcing it twice is noise.
  ///
  /// In en, this message translates to:
  /// **'{palette} palette'**
  String settingsPaletteSemantics({required String palette});

  /// Raises every ink to the top of its ramp. It is an ADDITION to the palette, not a fourth palette — which is why it is its own row and not a fourth word on the line above.
  ///
  /// In en, this message translates to:
  /// **'HIGH CONTRAST'**
  String get settingsHighContrast;

  /// The spoken form when the setting is on. Written as a sentence rather than as a state word appended to a label, so a screen reader announces it once.
  ///
  /// In en, this message translates to:
  /// **'High contrast on'**
  String get settingsHighContrastOn;

  /// The spoken form when the setting is off.
  ///
  /// In en, this message translates to:
  /// **'High contrast off'**
  String get settingsHighContrastOff;

  /// The wakelock, for a phone propped on a gate while both hands are busy. Released on inactive as well as hidden (#79) — a phone that stays lit in a pocket is a flat battery at 05:00.
  ///
  /// In en, this message translates to:
  /// **'KEEP SCREEN ON'**
  String get settingsKeepScreenOn;

  /// The spoken form when the wakelock is enabled.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on, on'**
  String get settingsKeepScreenOnStateOn;

  /// The spoken form when the wakelock is disabled.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on, off'**
  String get settingsKeepScreenOnStateOff;

  /// R40. Moves exactly three things: the corner slab, the INDEX button and the keypad's bottom row. The spine, the margin cell and the record column do NOT mirror — a book's margin is on the left, and the digits stay where a phone keypad puts them because a shepherd who has used a phone knows where 5 is.
  ///
  /// In en, this message translates to:
  /// **'LEFT-HANDED'**
  String get settingsLeftHanded;

  /// The spoken form when the mirror is on.
  ///
  /// In en, this message translates to:
  /// **'Left-handed, on'**
  String get settingsLeftHandedStateOn;

  /// The spoken form when the mirror is off.
  ///
  /// In en, this message translates to:
  /// **'Left-handed, off'**
  String get settingsLeftHandedStateOff;

  /// The current season row. The date arrives pre-formatted 'd MMM y' — a human-facing date is never all-numeric (R60), because 03/04 reads as a different day on two sides of an ocean.
  ///
  /// In en, this message translates to:
  /// **'{label} — started {date}'**
  String settingsSeasonCurrent({required String label, required String date});

  /// One row per season the shepherd can switch to. The label is theirs — seasons.label is a stored string, not a derived year.
  ///
  /// In en, this message translates to:
  /// **'{label}'**
  String settingsSeasonSwitch({required String label});

  /// The spoken form. It names the CONSEQUENCE — which season tonight's records land in — rather than the act, because 'switch' says nothing about what changes.
  ///
  /// In en, this message translates to:
  /// **'Write into {label}'**
  String settingsSeasonSwitchSemantics({required Object label});

  /// A season is the shepherd's first act, not the installer's: seedFirstRun deliberately writes none (#42). So a genuinely fresh notebook reads this, and it is a normal state rather than an error.
  ///
  /// In en, this message translates to:
  /// **'No season started.'**
  String get settingsSeasonNone;

  /// 07 §14.3 row 4, Settings ▸ Season. The one act that a fresh notebook cannot record anything without: `LambingRepository` refuses to invent a season on the 3am path, correctly, so this row is where one comes from. Calm-gated — it is the second and last place the free tier may honestly refuse.
  ///
  /// In en, this message translates to:
  /// **'START A SEASON'**
  String get settingsSeasonStart;

  /// 11 §7.3's secondSeason refusal, rendered as a static row and never a modal (#92). It names no price and carries no currency symbol — ProductDetails.price arrives at N30-T06. 'Unlock', never purchase, buy or subscribe.
  ///
  /// In en, this message translates to:
  /// **'The free notebook holds one season. Unlock to start another.'**
  String get settingsSeasonCapRefused;

  /// The app version, from kAppVersion — a --dart-define, so a build that forgot to set it reads 0.1.0 and says so rather than claiming a release number it does not have.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsAboutVersion({required String version});

  /// 13 §8.5's first diagnostics row. Counts come from the SAME whole-database count the export uses — a second implementation is a second answer to 'how many ewes are on this phone?'.
  ///
  /// In en, this message translates to:
  /// **'{records} records · {ewes} animals'**
  String settingsDiagnosticsCounts({required String records, required String ewes});

  /// Runs SQLite's own integrity check. It reports what it found and repairs nothing — an app that silently 'fixed' a records file would be the one thing worse than one that could not read it.
  ///
  /// In en, this message translates to:
  /// **'CHECK DATABASE'**
  String get settingsDiagnosticsCheck;

  /// Shares the diagnostics log through the system share sheet, as a file path. There is no telemetry and no analytics in this app, so this is the ONLY way a problem travels — and it travels because the shepherd sent it, deliberately.
  ///
  /// In en, this message translates to:
  /// **'SAVE THE LOG'**
  String get settingsDiagnosticsShareLog;

  /// Shares a VACUUM INTO snapshot of the records file. The snapshot, never the backup — 09 §5 keeps those two words apart because swapping them is how somebody restores the wrong thing.
  ///
  /// In en, this message translates to:
  /// **'SAVE A COPY OF THE FILE'**
  String get settingsDiagnosticsShareSnapshot;

  /// The heading over the log preview. 'Events', because that is what the log holds — 13 §8.4 keeps every value the shepherd typed out of it, so what is left is the shape of what happened and never its content.
  ///
  /// In en, this message translates to:
  /// **'Last {count} events'**
  String settingsDiagnosticsRecent({required num count});

  /// The log is empty or could not be read. A normal state on a fresh launch, and never an error — there is nothing wrong with a session in which nothing has gone wrong.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded in this session yet.'**
  String get settingsDiagnosticsNoLog;

  /// SQLite's own integrity check passed. It says what was checked rather than 'OK', because a shepherd reading this is asking a specific question.
  ///
  /// In en, this message translates to:
  /// **'The records file reads correctly.'**
  String get settingsDiagnosticsIntact;

  /// The integrity check failed. It reports and repairs NOTHING — an app that silently fixed a records file would be the one thing worse than one that could not read it — and the advice is the only action that cannot make things worse.
  ///
  /// In en, this message translates to:
  /// **'The records file reported a problem. Save a copy of it before doing anything else.'**
  String get settingsDiagnosticsDamaged;

  /// The Unlock button's label while a bounded store call is in flight. It replaces the label rather than adding a spinner — ui.spinner bans CircularProgressIndicator under lib/features/, and a spinner is a promise about a duration nobody measured. The call is bounded at ten seconds by the seam.
  ///
  /// In en, this message translates to:
  /// **'CONTACTING THE STORE'**
  String get unlockContactingStore;

  /// Android's slow payment instruments (cash, bank transfer) and Apple's Ask to Buy family-approval hold. Nobody else in the app can tell the shepherd this is happening, which is why the state exists. It says DAYS, honestly — a screen implying minutes would have them come back and tap again.
  ///
  /// In en, this message translates to:
  /// **'Your payment is being confirmed. This can take a few days.'**
  String get unlockAwaitingPayment;

  /// A shed has no signal most of the time the store is asked, so this is the NORMAL case rather than a fault — which is why StoreUnreachable is not a ShedFailure and this never renders through showFailure(). The second sentence is the point: it says what still works.
  ///
  /// In en, this message translates to:
  /// **'The store did not answer. Everything else in Shed Book works without it.'**
  String get unlockStoreUnreachable;

  /// Either the store reported itself unavailable or the product id resolved to nothing. Two causes, one honest sentence: the app cannot tell them apart and must not guess which one to blame.
  ///
  /// In en, this message translates to:
  /// **'This unlock is not available on your store account yet.'**
  String get unlockProductNotFound;

  /// The shepherd backed out of the store's own sheet. It states the ONLY thing they might be uncertain about; there is no 'try again' because the button they just left is still there.
  ///
  /// In en, this message translates to:
  /// **'Nothing was charged.'**
  String get unlockUserCancelled;

  /// The store reported a failure. It says nothing was charged because that is the question, and it never says the app is broken — an entitlement is never revoked, so somebody who already paid still owns the unlock.
  ///
  /// In en, this message translates to:
  /// **'The store could not complete that. Nothing was charged.'**
  String get unlockStoreError;

  /// The unlocked section's one word. No date, no receipt, no product name — the row records THAT the app is unlocked and nothing about how (11 §4.1), because none of it changes what the shepherd may do and each is a fact about their payment method in a file they may hand to a vet.
  ///
  /// In en, this message translates to:
  /// **'UNLOCKED'**
  String get unlockUnlocked;

  /// Mandatory, and it sits ABOVE Unlock (11 §6.4): Apple requires it, and a shepherd who reinstalled must be able to get back what they own without paying twice — so the route to it must not be below the thing that charges them. 'Purchases' is the one permitted use of that word in this product (CONVENTIONS §5.1).
  ///
  /// In en, this message translates to:
  /// **'RESTORE PURCHASES'**
  String get unlockRestore;

  /// 07 §19.2's row, verbatim. It states FACTS — what this version is, what it covers, and the two counts — and asks for nothing. It renders identically at 3 ewes and at 22 (#92: always present, in the same pixels), so a shepherd never learns that its appearance means they are near a line. NO PRICE IN THIS MESSAGE: the price is the store's own localised string and arrives through the action label, never as a literal (copy.currency_literal).
  ///
  /// In en, this message translates to:
  /// **'Free version · covers this season · {ewes} of {cap} {term}'**
  String upgradeRowFree({required num ewes, required num cap, required String term});

  /// The row's primary action. 'Unlock', never purchase, buy or subscribe (CONVENTIONS §5.1) — one non-consumable, bought once, and the word says what the shepherd gets rather than what they do.
  ///
  /// In en, this message translates to:
  /// **'UNLOCK'**
  String get upgradeRowUnlock;

  /// The spoken form. It names the app because a screen reader user arriving on this row from the rotor has no visual context for a bare 'unlock'.
  ///
  /// In en, this message translates to:
  /// **'Unlock Shed Book'**
  String get upgradeRowUnlockSemantics;

  /// 11 §7.3's RefusalReason.eweCap message. The cap is a PLACEHOLDER so the number is never typed twice — kFreeEweCap is the source, and a literal here would go stale the day it moves. It names no price and carries no currency symbol.
  ///
  /// In en, this message translates to:
  /// **'The free notebook holds {cap} {term} in a season. Unlock to add more.'**
  String capRefusedEweCap({required num cap, required String term});

  /// 11 §7.3's RefusalReason.secondSeason message. Season-primary: when both caps are over, this is the one that speaks (§7.0 ruling 8).
  ///
  /// In en, this message translates to:
  /// **'The free notebook holds one season. Unlock to start another.'**
  String get capRefusedSecondSeason;

  /// The Unlock action WHEN THE STORE ANSWERED IN THIS PROCESS. {price} is ProductDetails.price verbatim — the store's own localised, currency-formatted string for the account that will be charged. It is never built here and never reformatted: this app knows neither the currency, nor the tier, nor the tax treatment, and all three differ by territory.
  ///
  /// In en, this message translates to:
  /// **'UNLOCK — {price}'**
  String unlockBuyPriced({required String price});

  /// The Unlock action when the store has not answered. TWO MESSAGES RATHER THAN ONE WITH AN EMPTY PLACEHOLDER: 'UNLOCK — ' with a trailing dash is a rendering of a missing value, and a dash where a price should be reads as free. The action stays tappable, because the store may answer on the next tap.
  ///
  /// In en, this message translates to:
  /// **'UNLOCK'**
  String get unlockBuyUnpriced;

  /// 07 §14.3 section 1. Weight in kg or lb — converted only at the display edge; the database stores grams.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsSectionUnits;

  /// 07 §14.3 section 2. The shepherd's own nouns for their animals. Editing is N29-T03 and ships in v1.1.0; the section renders its current words meanwhile.
  ///
  /// In en, this message translates to:
  /// **'Terminology'**
  String get settingsSectionTerminology;

  /// 07 §14.3 section 3. A row that opens the reminders editor. Reminders themselves are N24 and N25 and ship in v1.1.0.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsSectionReminders;

  /// 07 §14.3 section 4. Which season is current, and when it started.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get settingsSectionSeason;

  /// 07 §14.3 row 4. The ewe cycle length, which the lambing spread reads to say how many lambed in the first cycle. The DEFAULT IS THE SHEPHERD'S, not the app's: 17 days is what onCreate seeds and this row is how they change it. Read by Season Summary (N28, v1.1.0); the value is stored now because the season it describes is happening now.
  ///
  /// In en, this message translates to:
  /// **'CYCLE {days} DAYS'**
  String settingsSeasonCycleDays({required String days});

  /// One day off the cycle. A word rather than a stepper's minus: indelible.md §6 has no icon set, and hold-to-repeat is a banned gesture — one press, one day.
  ///
  /// In en, this message translates to:
  /// **'SHORTER'**
  String get settingsSeasonCycleShorter;

  /// One day on. See SHORTER.
  ///
  /// In en, this message translates to:
  /// **'LONGER'**
  String get settingsSeasonCycleLonger;

  /// 07 §14.3 row 4. WHICH percentage — there are four honest definitions and they give different numbers off the same flock, so the app states which one it is using rather than picking. Read by Season Summary (N28, v1.1.0).
  ///
  /// In en, this message translates to:
  /// **'LAMBING PERCENTAGE'**
  String get settingsSeasonPercentage;

  /// 07 §14.3 section 5. Renaming and deactivating pens, and the turn-out threshold.
  ///
  /// In en, this message translates to:
  /// **'Pens'**
  String get settingsSectionPens;

  /// 07 §14.3 section 6. The palette and high contrast. There is no light theme and no system-follow — the app is dark only.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// 07 §14.3 section 7. The wakelock, for a phone propped on a gate at 03:20.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on'**
  String get settingsSectionKeepScreenOn;

  /// 07 §14.3 section 8. Moves exactly three things — the slab, the INDEX button and the keypad's bottom row (R40). The spine, the margin and the record column do not mirror: a book's margin is on the left.
  ///
  /// In en, this message translates to:
  /// **'Left-handed'**
  String get settingsSectionLeftHanded;

  /// 07 §14.3 section 9. 'Unlock', never Purchase, Buy, Subscribe or Upgrade (CONVENTIONS §5.1) — one non-consumable, bought once, and the word names what the shepherd gets.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get settingsSectionUnlock;

  /// 07 §14.3 section 10. A copy of the records file and the app's own log — there is no telemetry and no analytics in this app, so this is the only way a problem travels.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get settingsSectionDiagnostics;

  /// 07 §14.3 section 11. Backup, restore and the two deletes. The deletes are N29-T06 and ship in v1.1.0.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsSectionData;

  /// 07 §14.3 row 11, Settings ▸ Data. The only row in this section in v1.0.0 — the two deletes are v1.1.0. Caps because it is a word button, and the word is `restore` because the vocabulary has exactly one word for this act: never import, never load, never merge — there is no merge.
  ///
  /// In en, this message translates to:
  /// **'RESTORE FROM BACKUP'**
  String get settingsDataRestore;

  /// 07 §14.3 section 12. The version, the licences, and the offline statement.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// 07 §14.2's error state. It names what could not be read rather than a fault — there is nothing the shepherd can do about a read failure except come back.
  ///
  /// In en, this message translates to:
  /// **'Settings could not be read.'**
  String get settingsUnavailable;

  /// 07 §4.3's first action. The row is committed by this tap, BEFORE Lambing Entry is pushed — so the label names the event rather than an intention. Every action in this system is a word; there is no icon set.
  ///
  /// In en, this message translates to:
  /// **'LAMBING'**
  String get eweCardActionLambing;

  /// Opens the observation picker. The word names the act of recording what was SEEN — never 'diagnose', never 'assess'.
  ///
  /// In en, this message translates to:
  /// **'OBSERVE'**
  String get eweCardActionObserve;

  /// The general note on an animal. `addNote` landed at N15-T04 and had no caller — the one verb for a fact the schema has no column for, with nowhere to write it.
  ///
  /// In en, this message translates to:
  /// **'NOTE'**
  String get eweCardActionNote;

  /// The note field's label, and the same words the lambing screen uses for its own note (indelible.md §8 screen 4). One phrase per concept — a second wording would read as a second kind of note.
  ///
  /// In en, this message translates to:
  /// **'ANYTHING ELSE'**
  String get eweCardNoteHeading;

  /// The note sheet's dismiss word.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get eweCardNoteClose;

  /// Spoken hint on the note sheet's dismiss target.
  ///
  /// In en, this message translates to:
  /// **'Close the note'**
  String get eweCardNoteCloseHint;

  /// Writes ewe_seasons.status = 'barren' for the current season (R42). NOT a status change and NOT an observation — three different columns, three different facts. The app never infers it: no lambing recorded is NOT RECORDED, which is a different thing.
  ///
  /// In en, this message translates to:
  /// **'BARREN'**
  String get eweCardActionBarren;

  /// indelible-marks-and-strikes §9: the per-verb undo label for a foster. It writes a COMPENSATING event rather than editing the original — nothing is removed from this book, so the foster stays in the timeline and the correction sits beside it.
  ///
  /// In en, this message translates to:
  /// **'CORRECT THIS'**
  String get timelineCorrectFoster;

  /// Sets ewes.status = 'culled', which is what releases the tag (03 §6 item 4). There is no undo verb (R41): the previous value is recoverable from the record's own context, not from a history row.
  ///
  /// In en, this message translates to:
  /// **'CULL'**
  String get eweCardActionCull;

  /// The observation sheet's heading. A question about an OBSERVATION, deliberately — 'what is wrong with her' would invite a diagnosis, and this app originates none (§12.2).
  ///
  /// In en, this message translates to:
  /// **'What did you see?'**
  String get eweCardObserveHeading;

  /// indelible.md §7.14's dismiss word. Not 'Cancel' — there is no draft state, so 'Cancel' is not a verb (07 §15.5).
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get eweCardObserveClose;

  /// The dismiss control's semantic label. Nothing is written until a term is tapped, so closing costs nothing.
  ///
  /// In en, this message translates to:
  /// **'Close without recording an observation.'**
  String get eweCardObserveCloseHint;

  /// Shown on a ewe card when a NON-ACTIVE animal holds the same tag. Tags are unique among active animals only (decision-record §7.0 ruling 7), so this is a normal expected state and must not read as an error. {date} is the date of the most recent EVENT on the earlier animal's record, pre-formatted 'd MMM y' — NOT the date her status changed, which this app does not store (R41): updated_at is a row-lifecycle fact and rendering it as an event time is the laundering §12.5 exists to prevent. {status} is the current value of a mutable column and is true now, stated WITHOUT a date for the same reason.
  ///
  /// In en, this message translates to:
  /// **'An earlier {tag} is on record — {status}, last recorded {date}. Separate record.'**
  String eweCardEarlierAnimal({required String tag, required String status, required String date});

  /// The same disclosure for an earlier animal with no recorded events at all. A ewe created and removed with no history is unusual but storable, and naming her without a date is honest where inventing one would not be.
  ///
  /// In en, this message translates to:
  /// **'An earlier {tag} is on record — {status}. Separate record.'**
  String eweCardEarlierAnimalUndated({required String tag, required String status});

  /// The action beside the disclosure. Pushes that animal's own card. 64 x 64 minimum, like every target in this system.
  ///
  /// In en, this message translates to:
  /// **'Open the earlier {tag}'**
  String eweCardEarlierAnimalOpen({required String tag});

  /// ewes.status = 'sold', for prose. Lower case because it appears mid-sentence in the reused-tag disclosure; the boxed stamp form is upper case and lives on the row.
  ///
  /// In en, this message translates to:
  /// **'sold'**
  String get eweStatusSold;

  /// ewes.status = 'dead', for prose. 'died' rather than 'dead' because the sentence reads 'An earlier 412 is on record — died, last recorded ...'.
  ///
  /// In en, this message translates to:
  /// **'died'**
  String get eweStatusDead;

  /// ewes.status = 'culled', for prose. Culling is what releases a tag (03 §6 item 4), which is why this is the common case of the disclosure.
  ///
  /// In en, this message translates to:
  /// **'culled'**
  String get eweStatusCulled;

  /// The season sub-head on the ewe card — a headingLevel 2 stop so a screen reader can jump season to season instead of swiping through eighty rows. The year is the SEASON's, from a stored foreign key, never derived from an event's instant.
  ///
  /// In en, this message translates to:
  /// **'{year}'**
  String eweCardSeasonHeading({required String year});

  /// The group for records with no season. Only notes can be seasonless (03 §5.12); folding them into the newest season would be the app filing a record the shepherd did not file.
  ///
  /// In en, this message translates to:
  /// **'No season'**
  String get eweCardNoSeasonHeading;

  /// 07 §4.2's empty state. A new animal with no history is a normal state, not an error — the shepherd added her a minute ago. The noun is deliberately absent: the tag is already the page heading.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded yet.'**
  String get eweCardEmpty;

  /// 07 §4.2's error state. It says what could not be read rather than naming a fault, because there is nothing the shepherd can do about a read failure at 03:20 except come back.
  ///
  /// In en, this message translates to:
  /// **'Her records could not be read.'**
  String get eweCardUnavailable;

  /// indelible.md §8 Screen 1: 'Quick-add is the corner slab.' The largest target in the system, bottom-right, mirrored to bottom-left when left_handed is set. The noun is fed from termEweSingular (10 §8.5) because it varies by county — a shepherd who calls them gimmers reads GIMMER here.
  ///
  /// In en, this message translates to:
  /// **'+ {term}'**
  String flockAddSlab({required String term});

  /// The add sheet's heading, and its modal barrier label. 'Add', not 'New' — the shepherd is adding an animal that already exists in the field to a notebook that does not yet know her.
  ///
  /// In en, this message translates to:
  /// **'Add a {term}'**
  String flockAddHeading({required String term});

  /// The label ABOVE the line, because indelible.md §7.12 forbids placeholder text inside a field: in the dark a grey placeholder is indistinguishable from an entered value.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get flockAddFieldLabel;

  /// WarningCode.duplicateActiveTag's value, constructed in the UI and never persisted (decision #54 — there is no warnings column). It states the collision; the confirm bar reading OPEN rather than CREATE is what makes the create unreachable. Ruling N4.
  ///
  /// In en, this message translates to:
  /// **'{tag} is already on an active {term}.'**
  String flockAddDuplicateTag({required String tag, required String term});

  /// 06 §12: a confirm bar is 'labelled with the outcome'. Reachable only when no active animal wears this exact tag — a tag held only by a culled, sold or dead one is free (03 §6 item 4).
  ///
  /// In en, this message translates to:
  /// **'Create {tag}'**
  String flockAddConfirmCreate({required String tag});

  /// What the bar reads when an active animal already wears this exact tag. Ruling N4: there is no create to block, so 07 §3.3's 'never blocks the create' is true and vacuous.
  ///
  /// In en, this message translates to:
  /// **'Open {tag}'**
  String flockAddConfirmOpen({required String tag});

  /// indelible.md §7.14's 88 x 64 dismiss word. Not 'Cancel' — 07 §15.5: there is no draft state, so 'Cancel' is not a verb.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get flockAddClose;

  /// The dismiss control's semantic label. It says what closing costs, which is nothing, because there is no draft to discard.
  ///
  /// In en, this message translates to:
  /// **'Close this sheet. Nothing is written until you confirm.'**
  String get flockAddCloseHint;

  /// The 44 pt sticky page header, naming what the book is filtered to (indelible.md 7.16). It carries the NIGHT rather than the event time, because the event time is printed in the margin cell of the first row and a number printed twice is a number two readers disagree about. The separator lives here rather than in Dart so a translator can move it; the caps are the design system's and are applied at the render site, because Flutter has no text-transform.
  ///
  /// In en, this message translates to:
  /// **'{title} · {night}'**
  String lambingEntryPageHeader({required String title, required String night});

  /// indelible.md 8's footer sentence, printed at the HEAD of the optional cells rather than at the foot of them - the sentence says 'below', and a line printed underneath what it describes refers to nothing. It is the permission to walk away mid-lambing: the tally is the record and everything after it is detail, so a shepherd who puts the phone in a pocket after one stroke has lost nothing and must be told so before they reach the cells, not after.
  ///
  /// In en, this message translates to:
  /// **'Every cell below may be left blank. A blank cell prints as a gap, not as an error.'**
  String get lambingEntryBlankCells;

  /// indelible.md 7.9's Selected row: the description prints beside the chosen button and nowhere else. Five sentences printed at once is what pushed every other cell on this screen below the fold - the five buttons carry the digits, and the sentence carries the meaning of the one that was pressed. The words are the shepherd's own vocab_terms label when they have set one, so they are printed verbatim and never re-cased.
  ///
  /// In en, this message translates to:
  /// **'Ease {ordinal} · {description}'**
  String lambingEaseSelected({required int ordinal, required String description});

  /// indelible.md §8 Screen 1's sticky page header, which the screen shipped without. The count is the filtered count — what is on the page, not what is in the notebook — because the line names what the page is filtered to. THE NOUN IS A PLACEHOLDER (10 §8.5): it is fed from termEwePlural today and from the terminology overlay when N29 lands. The date arrives pre-formatted from lib/core/ui/formatters.dart so it is never all-numeric (R60) and there is one formatting authority rather than two.
  ///
  /// In en, this message translates to:
  /// **'Flock · {count} {term} · {date}'**
  String flockPageHeader({required int count, required String term, required String date});

  /// The same header while the list statement has not returned. The count is OMITTED rather than rendered as 0 (#58): 'Flock · 0 ewes' on the frame before the rows land tells a shepherd with four hundred animals that they have none, and it is the frame they see on every cold open.
  ///
  /// In en, this message translates to:
  /// **'Flock · {date}'**
  String flockPageHeaderCounting({required String date});

  /// indelible.md §7.4's trailing state word, BOXED — a state of the animal (§7.7). She carries a live withdrawal, or one whose period nobody recorded: unknown is never clear (spec §12.1, ruling N1), and the stamp reads the same either way because the row does not know which and must not guess. It states the state and never a number of days.
  ///
  /// In en, this message translates to:
  /// **'WITHDRAWAL'**
  String get flockStampWithdrawal;

  /// indelible.md §8 Screen 1's boxed stamp. ewe_seasons.status = 'barren' (R42) — a recorded ANSWER, not the absence of a lambing. 'barren', never 'empty' or 'not in lamb' (CONVENTIONS §5.1).
  ///
  /// In en, this message translates to:
  /// **'BARREN'**
  String get flockStampBarren;

  /// indelible.md §8 Screen 1 draws this stamp as 'TO LAMB'. The words here are the FILTER's words instead, and deliberately: one word per concept means the stamp and the filter that selects it must read the same, and 'TO LAMB' also carries a domain noun as a literal, which 10 §8.5 forbids and the gate catches. She is in lamb and still waiting — a different fact from barren.
  ///
  /// In en, this message translates to:
  /// **'NOT YET LAMBED'**
  String get flockStampNotYetLambed;

  /// An open pen_occupancies row. 'penned', never 'housed' (CONVENTIONS §5.1). §8 prints the pen label and the hours penned in this cell — 'Pen 4 · 31h' — and the flock list statement returns neither, so the row says the one thing it knows.
  ///
  /// In en, this message translates to:
  /// **'PENNED'**
  String get flockStampPenned;

  /// indelible.md §6.2's dagger, in §4.3's margin cell, for §7.4's Warning row state. A printer's mark rather than an icon — §1.3 bans the icon set, not the six marks — and it is never the sole channel: the doubled rule beneath the row and the QUERIED stamp in the trailing cell carry the same fact without colour.
  ///
  /// In en, this message translates to:
  /// **'†'**
  String get flockRowWarningMark;

  /// The sticky page header, from indelible.md 8 screen 7: THE PENS · 27 JULY 04:12 · 5 OCCUPIED · 2 OVER †. ShedPageHeader capitalises it, so it is written in sentence case here - the caps are a typographic decision the design system owns and Flutter has no text-transform. The date and time arrive pre-formatted from formatters.dart, never numeric-only (R60). The zero arm says 'none over' rather than '0 over' and drops the dagger: a dagger printed when nothing needs attention is a mark that stops meaning anything.
  ///
  /// In en, this message translates to:
  /// **'The pens · {date} {time} · {occupied} occupied · {over, plural, =0{none over} =1{1 over †} other{{over} over †}}'**
  String penBoardPageHeader({
    required String date,
    required String time,
    required int occupied,
    required int over,
  });

  /// The in-stream word button that restores physical order - for when the shepherd is walking the row of pens rather than answering the board. The board opens sorted by hours descending, because the pens that need you are the pens you can already see.
  ///
  /// In en, this message translates to:
  /// **'SORT BY PEN NUMBER'**
  String get penBoardSortByPen;

  /// The same button once physical order is showing. It returns the board to its default. Two words rather than one toggle labelled SORT, because at 03:20 a control has to say what it will do, not what is currently true.
  ///
  /// In en, this message translates to:
  /// **'SORT BY HOURS'**
  String get penBoardSortByHours;

  /// The bottom-left navigation anchor on the pen board, 96x64. It is the ONLY navigation affordance in the app - there is no back chevron anywhere (decision record 7.0a). SAME WORD AS quickEntryIndex AND THAT IS ONE KEY TOO MANY: R87 moved the band into lib/core/ui/components/, so the label belongs to the band rather than to a screen, and the two keys should collapse into one shed-wide key. That rename touches Quick Entry and is not this task's to make.
  ///
  /// In en, this message translates to:
  /// **'INDEX'**
  String get penBoardIndex;

  /// The whole board when the flock has made no pens at all. One printed line where a row would be, and the + PEN slab in the thumb band is the one act - an empty ruled page looks broken and a wizard is a decision at 03:20 nobody wants. Distinct from penTileEmpty, which is one empty pen among others.
  ///
  /// In en, this message translates to:
  /// **'No pens yet.'**
  String get penBoardNoPens;

  /// SAFETY REQUIREMENT, safety rule 12.1. It is printed beside REPEAT LAST, permanently, never behind a tap and never scrolled away from the control it qualifies. indelible.md 8 screen 8 and 9 both spell it verbatim: repeat-last copies product, dose, route and batch and explicitly leaves the withdrawal days blank, printing this where the value would be. The reason is the NADIS finding behind decision #51 — a withdrawal period can CHANGE for the same medicine and DIFFER between products with the same active ingredient — so the previous bottle's figure is not evidence about this bottle. Do not shorten it, do not soften READ THE BOTTLE into a suggestion, and never render the repeat control without it.
  ///
  /// In en, this message translates to:
  /// **'DAYS NOT COPIED — READ THE BOTTLE'**
  String get treatmentsDaysNotCopied;

  /// The ruled section line over the countdown segment, from the screen 8 mockup. The count is one line per TARGET, not per treatment — a product printing a meat figure and a milk figure is two countdowns. The sibling treatmentsModeCountdown forbids the word 'active' for the SEGMENT, where the question is what a withdrawal does (it runs); this names what the filter let through and is the mockup's own wording.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE WITHDRAWALS · {count}'**
  String treatmentsSectionRunning({required String count});

  /// The ruled section line over the book segment, from the screen 8 mockup. THE SEASON WAS STRUCK BEFORE IT SHIPPED. The mockup prints MEDICINE BOOK · 2026 and the first build followed it — but TreatmentRepository.watchTreatments applies no season filter, so the line stated a scope the list below it does not have: a shepherd reading MEDICINE BOOK · 2026 on a view they hand to a vet would be reading every treatment ever recorded. Naming a filter that is not applied is worse on this screen than on any other in the app. Restoring the season means filtering the statement, which is a data change and a ruling of its own.
  ///
  /// In en, this message translates to:
  /// **'MEDICINE BOOK'**
  String get treatmentsSectionBook;

  /// The corner slab, 160 x 140, bottom right — the screen's primary act and the only way a treatment is recorded. It opens the new-treatment sheet; it never writes, because the withdrawal control inside that sheet is where safety rule 12.1's three explicit choices are made. A word, not an icon: there is no icon set (indelible.md 1.3).
  ///
  /// In en, this message translates to:
  /// **'+ DOSE'**
  String get treatmentsSlab;

  /// The label above the kg/lb line, in indelible.md §7.12's shape: the label states what is set, the control sits on the rule under it. It names the quantity rather than the section, because 07 §14.3 row 1 rules OUT a second unit (°C/°F) rather than omitting it — so a row that named only its section would become ambiguous the day a temperature column ships. Uppercased by the widget, not here.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get settingsUnitsWeightLabel;

  /// The label above the three palette words. Appearance holds two independent controls — the palette and high contrast (07 §14.3 row 6) — so neither row may rely on the section heading to say which one it is. Uppercased by the widget, not here.
  ///
  /// In en, this message translates to:
  /// **'Palette'**
  String get settingsPaletteLabel;

  /// The value a boolean setting prints on its rule. indelible.md §7.12 puts the label above and the VALUE on the rule; the button used to print the setting's name with the state carried only by the selected fill, so nothing on the line ever said on or off. The spoken form is the settings*StateOn message, which names the setting too — the visible word is the value alone because the label above already names it.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get settingsStateOn;

  /// The off value of a boolean setting. Never rendered as a disabled or dimmed control: indelible.md §7.13 has no disabled state, and an off setting is a value rather than an absence.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get settingsStateOff;

  /// indelible.md §8 prints this directly beneath the theme buttons, and nothing in the app had ever rendered it. It is NOT §8's own sentence: that one reads 'if it is serif, it happened; if it is sans, it is a thing you can press', written when two faces were planned. P7 (2026-08-02) closed that — one family ships, Atkinson Hyperlegible Next, which is a sans — and §1.2 rule 2 was amended to the axis that actually shipped. Printing the serif sentence would be the app describing a typeface it does not have.
  ///
  /// In en, this message translates to:
  /// **'Sentence case means it happened. Capitals mean it is a thing you can press.'**
  String get settingsAppearanceVoices;

  /// indelible.md §3.5 rule 5, and §3.5 requires it to be documented HERE, beside the two-voices line, 'because an unexplained exception is a bug'. The shepherd is matching a digit on a key against a digit already printed in the recents list and in the row above: same shape, same width, no translation step.
  ///
  /// In en, this message translates to:
  /// **'One exception: the keypad digits are set in the record voice, so the digit you press is the shape that prints.'**
  String get settingsAppearanceKeypadVoice;

  /// The line above the seven read-only terms. The section used to print a heading over nothing, on the reading that editing is N29-T03 and ships in v1.1.0 — but docs/RELEASE-SCOPE.md is explicit that the authored defaults ship in v1.0.0 and only the editing waits, so the words themselves are not deferred and the section can say what it is currently using. AND IN EVERY EXPORT WAS STRUCK BEFORE IT SHIPPED: it was not true. No export path reads the terminology — the CSV writer emits stable column keys and the backup emits table columns, neither of which is a printed noun — so the sentence claimed a behaviour the build does not have. The second sentence is the deferral stated plainly rather than a promise about a date: it says what is true today and nothing about when it changes.
  ///
  /// In en, this message translates to:
  /// **'These are the words this app prints on screen. They cannot be changed on this version.'**
  String get settingsTerminologyNote;

  /// One class's two words on one ruled line. BOTH forms, because a plural is never derived by appending an s (10 §8.5) — '3 sheeps' is the cheap example and tup/tups against ox/oxen is why no rule works. The separator is here rather than composed in Dart so a translator can move it. The words themselves arrive from terminologyProvider or from the term<Class>Singular/Plural defaults; this message carries no noun of its own. The placeholders are named singularTerm and pluralTerm rather than singular and plural — `plural` is an ICU keyword and a placeholder that shadows it stops parsing on the next gen-l10n release, which l10n_bootstrap_test.dart catches and which nAnimals already obeys.
  ///
  /// In en, this message translates to:
  /// **'{singularTerm} · {pluralTerm}'**
  String settingsTerminologyPair({required String singularTerm, required String pluralTerm});

  /// The margin stamp on the definition the app is currently using, and on the season tonight's records are written into. A WORD, because indelible.md §1.2 rule 3 carries meaning by form first and hue never alone — the stamp, the row's position and the heavier text role are three channels, none of them a colour, so the row survives the OS grayscale filter. It is never the sole carrier of its meaning, which is what keeps §3.4's sub-18px stamp exemption valid here.
  ///
  /// In en, this message translates to:
  /// **'IN USE'**
  String get settingsSeasonPercentageInUse;
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
