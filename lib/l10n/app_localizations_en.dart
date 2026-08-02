// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String withdrawalSource({required int days}) {
    return 'Withdrawal period: $days days, as entered by you';
  }

  @override
  String get termEweSingular => 'ewe';

  @override
  String get termEwePlural => 'ewes';

  @override
  String get termMaidenFemaleSingular => 'gimmer';

  @override
  String get termMaidenFemalePlural => 'gimmers';

  @override
  String get termEweLambSingular => 'ewe lamb';

  @override
  String get termEweLambPlural => 'ewe lambs';

  @override
  String get termRamSingular => 'tup';

  @override
  String get termRamPlural => 'tups';

  @override
  String get termRamLambSingular => 'ram lamb';

  @override
  String get termRamLambPlural => 'ram lambs';

  @override
  String get termWetherSingular => 'wether';

  @override
  String get termWetherPlural => 'wethers';

  @override
  String get termLambSingular => 'lamb';

  @override
  String get termLambPlural => 'lambs';

  @override
  String nAnimals({required num count, required String singularTerm, required String pluralTerm}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count $pluralTerm',
      one: '1 $singularTerm',
      zero: 'No $pluralTerm',
    );
    return '$_temp0';
  }

  @override
  String get vocabEase1 => 'No assistance';

  @override
  String get vocabEase2 => 'Slight assistance by hand';

  @override
  String get vocabEase3 => 'Considerable assistance needed';

  @override
  String get vocabEase4 => 'Veterinary assistance needed';

  @override
  String get vocabEase5 => 'Caesarean section';

  @override
  String get vocabDcStarvation => 'Starvation';

  @override
  String get vocabDcHypothermia => 'Hypothermia';

  @override
  String get vocabDcWateryMouth => 'Watery mouth';

  @override
  String get vocabDcJointIll => 'Joint ill';

  @override
  String get vocabDcCrushed => 'Crushed';

  @override
  String get vocabDcStillborn => 'Stillborn';

  @override
  String get vocabDcUnknown => 'Unknown';

  @override
  String get vocabDcOther => 'Other';

  @override
  String get vocabMpHeadBack => 'Head back';

  @override
  String get vocabMpOneLegBack => 'One leg back';

  @override
  String get vocabMpBothLegsBack => 'Both legs back';

  @override
  String get vocabMpBreech => 'Breech';

  @override
  String get vocabMpBackwards => 'Backwards';

  @override
  String get vocabMpTwinsTogether => 'Twins together';

  @override
  String get vocabMpRingwomb => 'Ringwomb';

  @override
  String get vocabMpOther => 'Other';

  @override
  String get vocabRtSubcutaneous => 'Subcutaneous';

  @override
  String get vocabRtIntramuscular => 'Intramuscular';

  @override
  String get vocabRtOral => 'Oral';

  @override
  String get vocabRtTopical => 'Topical';

  @override
  String get vocabRtIntranasal => 'Intranasal';

  @override
  String get vocabRtIntravenous => 'Intravenous';

  @override
  String get vocabRtIntraperitoneal => 'Intraperitoneal';

  @override
  String get vocabRtOther => 'Other';

  @override
  String get vocabObsProlapse => 'Prolapse';

  @override
  String get vocabObsMastitis => 'Mastitis';

  @override
  String get vocabObsPoorMothering => 'Poor mothering';

  @override
  String get vocabObsGoodMothering => 'Good mothering';

  @override
  String get vocabObsNoMilk => 'No milk';

  @override
  String get vocabObsOther => 'Other';

  @override
  String get vocabFmWetAdopt => 'Wet adoption';

  @override
  String get vocabFmSkin => 'Skinning';

  @override
  String get vocabFmCrate => 'Adoption crate';

  @override
  String get vocabFmBottle => 'Bottle';

  @override
  String get vocabFmOther => 'Other';

  @override
  String get keypadTagEntry => 'Tag entry';

  @override
  String get keypadBackspace => 'Backspace';

  @override
  String get hintDeleteLastDigit => 'delete the last digit';

  @override
  String get keypadNewTag => 'NEW TAG';

  @override
  String keypadEnteredTag({required String tag}) {
    return 'Entered tag $tag';
  }

  @override
  String matchCountClosest({required int count, required String tag}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches, closest $tag',
      one: '1 match, closest $tag',
      zero: 'No matches',
    );
    return '$_temp0';
  }

  @override
  String get quickEntryTitle => 'Tonight';

  @override
  String quickEntryPageHeader({required String night, required int page}) {
    return 'Night of $night · page $page';
  }

  @override
  String get quickEntryStampAuto => 'AUTO';

  @override
  String get quickEntryIndex => 'INDEX';

  @override
  String get quickEntrySlabTagFirst => 'Tag first';

  @override
  String get quickEntryPennedEmpty => 'Nothing penned yet.';

  @override
  String get quickEntryRecentsEmpty => 'No recent animals.';

  @override
  String get quickEntryDeckUnavailable => 'The deck could not be read.';

  @override
  String quickEntryHoursPenned({required int hours}) {
    return '${hours}h';
  }

  @override
  String quickEntryPennedRowLabel({required String tag, required String pen, required int hours}) {
    return 'Tag $tag, in $pen, penned $hours hours';
  }

  @override
  String quickEntryRecentRowLabel({required String tag}) {
    return 'Tag $tag';
  }

  @override
  String get quickEntryLambing => 'Lambing';

  @override
  String quickEntryConfirmCreate({required String tag}) {
    return 'Create $tag';
  }

  @override
  String quickEntryConfirmUse({required String tag}) {
    return 'Use $tag';
  }

  @override
  String get quickEntryStrike => 'STRIKE';

  @override
  String quickEntryStrikeWindow({required int seconds}) {
    return '${seconds}s to strike';
  }

  @override
  String quickEntryStruckAt({required String at}) {
    return 'STRUCK $at';
  }

  @override
  String photoMissingOnThisPhone({required String date, required String time}) {
    return 'Photo taken $date $time — file no longer on this phone';
  }

  @override
  String get photoShowInFullColour => 'Show in full colour';

  @override
  String photoSemanticLabel({
    required String date,
    required String time,
    required String provenance,
  }) {
    return 'Photo taken $date $time, $provenance';
  }

  @override
  String get lambingEntryTitle => 'Lambing';

  @override
  String get lambingEntryLambs => 'Lambs';

  @override
  String get lambingEntryCare => 'Care';

  @override
  String lambingTypeCounted({required String type}) {
    return '$type (COUNTED)';
  }

  @override
  String lambingTypeCountedMany({required int count, required String animals}) {
    return '$count $animals (COUNTED)';
  }

  @override
  String get lambingTypeNotRecorded => 'NOT RECORDED';

  @override
  String lambingAddLamb({required String animal}) {
    return '+ $animal';
  }

  @override
  String lambingTallySemantics({
    required int count,
    required String animal,
    required String animals,
  }) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count $animals',
      one: '1 $animal',
      zero: 'No $animals yet',
    );
    return '$_temp0';
  }

  @override
  String lambingLambOrdinal({required String animal, required int n}) {
    return '$animal $n';
  }

  @override
  String get lambStatusAlive => 'ALIVE';

  @override
  String get lambStatusDead => 'DEAD';

  @override
  String get lambStatusStillborn => 'STILLBORN';

  @override
  String get lambStatusSold => 'SOLD';

  @override
  String lambRowSemantics({required String parts}) {
    return '$parts';
  }

  @override
  String get lambingEaseHeading => 'EASE';

  @override
  String get lambingEaseUnset => 'NOT RECORDED · SKIPPABLE';

  @override
  String get lambingEaseGroupSemantics => 'Ease, 1 to 5, not required';

  @override
  String lambingEaseValueSemantics({required int ordinal, required String description}) {
    return 'Ease $ordinal, $description';
  }

  @override
  String get careColostrum => 'Colostrum';

  @override
  String get careNavelDip => 'Navel dip';

  @override
  String get careStomachTube => 'Stomach tube';

  @override
  String get careWarmed => 'Warmed';

  @override
  String careDoneAt({required String time}) {
    return 'DONE $time';
  }

  @override
  String careUndoneAt({required String time}) {
    return 'UNDONE $time';
  }

  @override
  String get careNotRecorded => 'NOT RECORDED';

  @override
  String careLineSemantics({required String label, required String state}) {
    return '$label, $state';
  }

  @override
  String get colostrumVolumeLabel => 'VOLUME';

  @override
  String get colostrumVolumeUnit => 'ml';

  @override
  String get colostrumMethodLabel => 'METHOD';

  @override
  String get colostrumMethodTeat => 'Teat';

  @override
  String get colostrumMethodTube => 'Tube';

  @override
  String get colostrumMethodBottle => 'Bottle';

  @override
  String colostrumMethodSemantics({required String word}) {
    return '$word';
  }

  @override
  String get colostrumRecord => 'RECORD';

  @override
  String get colostrumRecordSemantics => 'Record the colostrum detail';

  @override
  String get colostrumSheetClose => 'CLOSE';

  @override
  String get colostrumSheetCloseSemantics => 'Close without adding a volume or a method';

  @override
  String get colostrumSheetBarrier => 'Colostrum detail';

  @override
  String queryMarkSemantics({required String finding}) {
    return 'Queried: $finding';
  }

  @override
  String get declareTypeHeading => 'WHAT WE FOUND';

  @override
  String get declareTypeChange => 'CHANGE THE BIRTH TYPE';

  @override
  String get declareTypeLeave => 'LEAVE IT';

  @override
  String declareTypeAcknowledged({required String time}) {
    return 'QUERIED · LEFT AS ENTERED $time';
  }

  @override
  String get birthTypeSingle => 'SINGLE';

  @override
  String get birthTypeTwin => 'TWIN';

  @override
  String get birthTypeTriplet => 'TRIPLET';

  @override
  String get birthTypeQuad => 'QUAD';

  @override
  String get birthTypeQuintPlus => 'QUAD OR MORE';
}
