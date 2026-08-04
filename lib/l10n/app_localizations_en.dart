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
  String lambingEntryLambs({required String term}) {
    return '$term';
  }

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

  @override
  String get provenanceWasPrefix => 'was';

  @override
  String provenanceHeaderSemantics({required String time, required String provenance}) {
    return 'Lambing time $time, $provenance';
  }

  @override
  String get provenanceEditHint => 'correct the time this lambing happened';

  @override
  String get timeEditorHeading => 'WHEN DID IT HAPPEN';

  @override
  String get timeEditorHint => '24-hour, four digits';

  @override
  String get timeEditorConfirm => 'CORRECT IT';

  @override
  String get timeEditorConfirmSemantics => 'Correct the lambing time to what you typed';

  @override
  String get detailAssistedBy => 'WHO ELSE WAS THERE';

  @override
  String get detailPresentation => 'HOW IT WAS LYING';

  @override
  String get detailPresentationNote => 'ROPES, LUBRICANT, VET';

  @override
  String get detailNote => 'ANYTHING ELSE';

  @override
  String get detailUnset => 'NOT RECORDED · SKIPPABLE';

  @override
  String get detailPresentationSemantics => 'How it was lying, not required';

  @override
  String lambCardTitle({required String animal}) {
    return '$animal';
  }

  @override
  String lambCardBirthDam({required String tag}) {
    return 'BIRTH DAM $tag';
  }

  @override
  String lambCardRearingDam({required String tag}) {
    return 'REARING DAM $tag';
  }

  @override
  String get lambCardPermanent => 'PERMANENT';

  @override
  String get lambCardNoEweBottle => 'ON THE BOTTLE';

  @override
  String get lambCardNoEweNotRecorded => 'REARING DAM NOT RECORDED';

  @override
  String get lambCardNothingElseRecorded => 'NOTHING ELSE RECORDED YET';

  @override
  String get lambCardUntagged => 'UNTAGGED';

  @override
  String get lambCardHistoryBorn => 'BORN';

  @override
  String get lambCardHistoryFoster => 'FOSTERED';

  @override
  String get lambCardHistoryCare => 'CARE';

  @override
  String get lambCardHistoryTreatment => 'TREATMENT';

  @override
  String get lambCardSexLabel => 'SEX';

  @override
  String get lambCardSexUnknown => 'COULD NOT TELL';

  @override
  String get lambCardWeightLabel => 'BIRTHWEIGHT';

  @override
  String get lambCardWeightUnset => 'NOT RECORDED · SKIPPABLE';

  @override
  String get lambCardWeightUnitKg => 'kg';

  @override
  String get lambCardWeightUnitLb => 'lb';

  @override
  String get warningImplausibleBirthWeight => 'That is outside the usual birthweight range.';

  @override
  String get lambCardStatusLabel => 'STATUS';

  @override
  String get lambCardDeathDateLabel => 'WHEN';

  @override
  String get lambCardDeathDateToday => 'TODAY';

  @override
  String get lambCardDeathDateYesterday => 'YESTERDAY';

  @override
  String get lambCardDeathDateTwoDaysAgo => '2 DAYS AGO';

  @override
  String get lambCardDeathCauseLabel => 'CAUSE';

  @override
  String get lambCardDeathCauseUnattributed => 'NOT RECORDED';

  @override
  String get warningDeathBeforeBirth => 'The death date is before the lambing.';

  @override
  String get lambCardPetLambLabel => 'ON THE BOTTLE';

  @override
  String get lambCardFeedsLabel => 'FEEDS';

  @override
  String get lambCardFeedsUnset => 'NOT RECORDED · SKIPPABLE';

  @override
  String get lambCardFeedsAdd => '+';

  @override
  String get lambCardFeedsAddSemantics => 'Record one more bottle feed';

  @override
  String get fosterTitle => 'FOSTER';

  @override
  String fosterOnto({required String tag}) {
    return 'ONTO $tag';
  }

  @override
  String get fosterToBottle => 'ONTO THE BOTTLE';

  @override
  String fosterRemovedUnknown({required String animal}) {
    return 'OFF THE $animal · WHERE NOT RECORDED';
  }

  @override
  String get fosterNoMatch => 'NO MATCH YET';

  @override
  String fosterBirthDamNote({required String tag}) {
    return 'BIRTH DAM $tag · UNCHANGED';
  }

  @override
  String warningFosterToSelf({required String animal, required String dam}) {
    return 'That $animal is already on this $dam.';
  }

  @override
  String penTileHours({required int hours}) {
    return '${hours}h';
  }

  @override
  String get penTileReady => 'READY';

  @override
  String penTileAttention({required String date}) {
    return 'CLEAR $date';
  }

  @override
  String get penTileLoss => 'DEAD';

  @override
  String get penTileEmpty => '— empty —';

  @override
  String penTileSemantics({required String label, required String state}) {
    return 'Pen $label, $state';
  }

  @override
  String get penBoardAddPen => '+ PEN';

  @override
  String get penBoardAddPenSemantics => 'Add a pen';

  @override
  String get penBoardTitle => 'PENS';

  @override
  String withdrawalLabel({required String target}) {
    return 'WITHDRAWAL — $target';
  }

  @override
  String get withdrawalTargetMeat => 'MEAT';

  @override
  String get withdrawalTargetMilk => 'MILK';

  @override
  String get withdrawalEnterDays => 'DAYS OFF THE BOTTLE';

  @override
  String get withdrawalNotApplicable => 'NONE APPLIES';

  @override
  String get withdrawalNotRecorded => 'NOT RECORDED';

  @override
  String get withdrawalUnit => 'days';

  @override
  String get withdrawalDisagrees =>
      'Nothing has been changed. The stored clear date is shown first; the second is what today\'s arithmetic gives.';

  @override
  String withdrawalStored({required String date}) {
    return 'STORED $date';
  }

  @override
  String withdrawalRecomputed({required Object date}) {
    return 'TODAY\'S ARITHMETIC $date';
  }

  @override
  String get exportTitle => 'EXPORT';

  @override
  String get exportWhatThisIs =>
      'This is your notebook\'s contents, as you recorded them. Nothing is sent anywhere: the file goes to the share sheet and you choose where it goes.';

  @override
  String exportCsvRow({required String term}) {
    return 'CSV - ONE ROW PER $term';
  }

  @override
  String get exportCsvTreatments => 'CSV - ONE ROW PER TREATMENT';

  @override
  String get exportCsvAll => 'EXPORT ALL THREE';

  @override
  String exportCounts({
    required int eweCount,
    required String ewePlural,
    required int lambCount,
    required String lambPlural,
    required int treatments,
  }) {
    return '$eweCount $ewePlural, $lambCount $lambPlural, $treatments treatments';
  }

  @override
  String get exportNeverExported => 'Nothing has been exported from this phone yet.';

  @override
  String exportLastExported({required String date}) {
    return 'Last exported $date.';
  }

  @override
  String get exportBuilding => 'Building...';

  @override
  String exportFailed({required String artefact}) {
    return '$artefact could not be built. Nothing was sent.';
  }

  @override
  String exportSemantics({required String label, required int count}) {
    return '$label, $count records';
  }

  @override
  String exportBannerHeadline({required String date}) {
    return 'You have not exported since $date.';
  }

  @override
  String get exportBannerNeverHeadline => 'You have not exported from this phone.';

  @override
  String exportBannerCount({required int count}) {
    return '$count records since then. A lost phone is lost records unless you export.';
  }

  @override
  String get exportBannerAct => 'EXPORT NOW';

  @override
  String get exportBannerDismiss => 'NOT THIS SEASON';

  @override
  String get restoreRefusedNewerApp =>
      'This backup was made by a newer version of Shed Book. Update the app and try again.';

  @override
  String restoreRefusedNewerAppDetail({
    required int foundFormat,
    required int foundSchema,
    required int readsFormat,
    required int readsSchema,
  }) {
    return 'This file: format $foundFormat, records $foundSchema. This app reads format $readsFormat, records $readsSchema.';
  }

  @override
  String get restoreRefusedNotOurs => 'This is not a Shed Book backup file.';

  @override
  String get restoreRefusedDamaged => 'This Shed Book backup is damaged and cannot be read.';

  @override
  String get backupIntegrityLine =>
      'Each backup carries a check that finds a truncated or damaged file. It does not protect the file from being changed.';

  @override
  String get backupRefusedIncomplete =>
      'This backup file is incomplete and has not been restored. Nothing on this phone has changed.';

  @override
  String get restoreRefusedZip =>
      'This looks like a photo archive. Shed Book restores the records file (.json).';

  @override
  String get restoreRefusedDatabaseCopy =>
      'This is a diagnostics copy of a database, not a backup. It cannot be restored in the app.';

  @override
  String get restoreRefusedNotABackup =>
      'This file is not a Shed Book backup. Choose the .json file the app shared when you exported.';

  @override
  String restoreBackupSummary({
    required int seasons,
    required int ewes,
    required int lambs,
    required int treatments,
    required String date,
    required String version,
    required String eweTerm,
    required String lambTerm,
  }) {
    return '$seasons seasons, $ewes $eweTerm, $lambs $lambTerm, $treatments treatments. Made on $date by Shed Book $version.';
  }

  @override
  String restoreLiveSummary({
    required int seasons,
    required int ewes,
    required int lambs,
    required int treatments,
    required String eweTerm,
    required String lambTerm,
  }) {
    return '$seasons seasons, $ewes $eweTerm, $lambs $lambTerm, $treatments treatments.';
  }

  @override
  String get restoreDestruction =>
      'Restoring will delete everything now on this phone and replace it with the backup. This cannot be undone from inside the app.';

  @override
  String restoreMediaNotice({required int count}) {
    return 'Photos and voice notes are not part of a backup. $count were recorded on the other phone and will show as \"not on this phone\".';
  }

  @override
  String get restoreStepOne => 'I UNDERSTAND - CONTINUE';

  @override
  String get restoreReplaceEverything => 'REPLACE EVERYTHING';

  @override
  String get restoreCancel => 'CANCEL';

  @override
  String get restoreDoneTitle => 'Your records are back.';

  @override
  String restoreDoneMedia({required int count}) {
    return '$count photos and voice notes were recorded on the other phone. Photos are not part of a backup in this version - they stay on the phone that took them. Each one still shows in the record it belongs to, marked \"not on this phone\".';
  }

  @override
  String get treatmentsTitle => 'TREATMENTS';

  @override
  String get treatmentsModeCountdown => 'RUNNING';

  @override
  String get treatmentsModeBook => 'BOOK';

  @override
  String treatmentsVoided({required String date}) {
    return 'VOIDED $date';
  }

  @override
  String treatmentsClears({required String date}) {
    return 'CLEARS $date';
  }

  @override
  String get treatmentsNoWithdrawal => 'NOT RECORDED';

  @override
  String treatmentsCountdown({required String tag, required String target}) {
    return '$tag · $target';
  }

  @override
  String treatmentsCountdownSemantics({
    required String tag,
    required String target,
    required String product,
    required String date,
  }) {
    return '$tag, $target, $product, clears $date';
  }

  @override
  String get treatmentsNotApplicable => 'NOT APPLICABLE';

  @override
  String get treatmentsRepeatLast => 'REPEAT LAST';

  @override
  String treatmentsRepeatOnto({required String tag}) {
    return 'ONTO $tag';
  }

  @override
  String get treatmentsEmpty => 'NOTHING RECORDED YET';

  @override
  String get treatmentsUntagged => 'UNTAGGED';

  @override
  String get flockEmpty => 'No animals yet.';

  @override
  String get flockFilteredEmpty => 'No animals match these filters.';

  @override
  String get flockUnavailable => 'The flock could not be read.';

  @override
  String flockRowSummary({required int seasons, required int lambings}) {
    return '$seasons seasons · $lambings lambings';
  }

  @override
  String flockRowLabel({required String tag}) {
    return 'Tag $tag';
  }

  @override
  String flockFilterAll({required int count}) {
    return 'ALL $count';
  }

  @override
  String flockFilterNotYetLambed({required int count}) {
    return 'NOT YET LAMBED $count';
  }

  @override
  String flockFilterCurrentlyPenned({required int count}) {
    return 'IN THE PENS $count';
  }

  @override
  String flockFilterUnderTreatment({required int count}) {
    return 'UNDER TREATMENT $count';
  }

  @override
  String flockFilterTripletBearing({required int count}) {
    return 'TRIPLET-BEARING $count';
  }

  @override
  String flockFilterBarren({required int count}) {
    return 'BARREN $count';
  }

  @override
  String get flockFilterAllUnknown => 'ALL';

  @override
  String get flockStampQueried => 'QUERIED';

  @override
  String get flockStampCulled => 'CULLED';

  @override
  String flockStruckDivider({required int count}) {
    return 'STRUCK — $count';
  }

  @override
  String get eweCardRowLambing => 'Lambed';

  @override
  String eweCardRowTreatment({required String product}) {
    return 'Treated with $product';
  }

  @override
  String eweCardRowCare({required String kind}) {
    return '$kind';
  }

  @override
  String get eweCardRowFoster => 'Fostered';

  @override
  String eweCardRowObserved({required String observation}) {
    return '$observation';
  }

  @override
  String eweCardRowPenned({required String pen}) {
    return 'Penned in $pen';
  }

  @override
  String eweCardRowNote({required String body}) {
    return '$body';
  }

  @override
  String eweCardRowEditedFrom({required String time}) {
    return 'was $time';
  }

  @override
  String eweCardRowStruck({required String time}) {
    return 'STRUCK $time';
  }

  @override
  String eweCardWithdrawalDays({required num days}) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days day withdrawal',
      one: '1 day withdrawal',
      zero: '0 day withdrawal',
    );
    return '$_temp0';
  }

  @override
  String get eweCardWithdrawalNotApplicable => 'No withdrawal';

  @override
  String get eweCardWithdrawalNotRecorded => 'Withdrawal — NOT RECORDED';

  @override
  String eweCardRowSemantics({
    required String time,
    required String body,
    required String provenance,
  }) {
    return '$time. $body. $provenance';
  }

  @override
  String eweCardTitle({required String singularTerm, required String tag}) {
    return '$singularTerm $tag';
  }

  @override
  String eweCardSummarySeasons({required num count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seasons',
      one: '1 season',
      zero: 'No seasons recorded',
    );
    return '$_temp0';
  }

  @override
  String eweCardSummaryAverage({required String average}) {
    return 'avg $average';
  }

  @override
  String eweCardSummaryAssisted({required num count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'assisted $count times',
      two: 'assisted twice',
      one: 'assisted once',
      zero: 'never assisted',
    );
    return '$_temp0';
  }

  @override
  String eweCardSummaryAssistedCoverage({required num scored}) {
    return 'of $scored scored';
  }

  @override
  String eweCardSummaryObservation({required String observation, required String year}) {
    return '$observation $year';
  }

  @override
  String eweCardSummarySemantics({required String clauses}) {
    return '$clauses';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsUnitsWeightKg => 'KG';

  @override
  String get settingsUnitsWeightLb => 'LB';

  @override
  String settingsUnitsWeightSemantics({required String unit}) {
    return 'Weight in $unit';
  }

  @override
  String get settingsUnitsWeightKgSpoken => 'kilograms';

  @override
  String get settingsUnitsWeightLbSpoken => 'pounds';

  @override
  String get settingsPaletteNight => 'NIGHT';

  @override
  String get settingsPaletteAmber => 'AMBER';

  @override
  String get settingsPaletteDeepRed => 'DEEP RED';

  @override
  String settingsPaletteSemantics({required String palette}) {
    return '$palette palette';
  }

  @override
  String get settingsHighContrast => 'HIGH CONTRAST';

  @override
  String get settingsHighContrastOn => 'High contrast on';

  @override
  String get settingsHighContrastOff => 'High contrast off';

  @override
  String get settingsKeepScreenOn => 'KEEP SCREEN ON';

  @override
  String get settingsKeepScreenOnStateOn => 'Keep screen on, on';

  @override
  String get settingsKeepScreenOnStateOff => 'Keep screen on, off';

  @override
  String get settingsLeftHanded => 'LEFT-HANDED';

  @override
  String get settingsLeftHandedStateOn => 'Left-handed, on';

  @override
  String get settingsLeftHandedStateOff => 'Left-handed, off';

  @override
  String settingsSeasonCurrent({required String label, required String date}) {
    return '$label — started $date';
  }

  @override
  String settingsSeasonSwitch({required String label}) {
    return '$label';
  }

  @override
  String settingsSeasonSwitchSemantics({required Object label}) {
    return 'Write into $label';
  }

  @override
  String get settingsSeasonNone => 'No season started.';

  @override
  String get settingsSeasonCapRefused =>
      'The free notebook holds one season. Unlock to start another.';

  @override
  String settingsAboutVersion({required String version}) {
    return 'Version $version';
  }

  @override
  String settingsDiagnosticsCounts({required String records, required String ewes}) {
    return '$records records · $ewes animals';
  }

  @override
  String get settingsDiagnosticsCheck => 'CHECK DATABASE';

  @override
  String get settingsDiagnosticsShareLog => 'SAVE THE LOG';

  @override
  String get settingsDiagnosticsShareSnapshot => 'SAVE A COPY OF THE FILE';

  @override
  String settingsDiagnosticsRecent({required num count}) {
    return 'Last $count events';
  }

  @override
  String get settingsDiagnosticsNoLog => 'Nothing recorded in this session yet.';

  @override
  String get settingsDiagnosticsIntact => 'The records file reads correctly.';

  @override
  String get settingsDiagnosticsDamaged =>
      'The records file reported a problem. Save a copy of it before doing anything else.';

  @override
  String get settingsSectionUnits => 'Units';

  @override
  String get settingsSectionTerminology => 'Terminology';

  @override
  String get settingsSectionReminders => 'Reminders';

  @override
  String get settingsSectionSeason => 'Season';

  @override
  String get settingsSectionPens => 'Pens';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionKeepScreenOn => 'Keep screen on';

  @override
  String get settingsSectionLeftHanded => 'Left-handed';

  @override
  String get settingsSectionDiagnostics => 'Diagnostics';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsUnavailable => 'Settings could not be read.';

  @override
  String get eweCardActionLambing => 'LAMBING';

  @override
  String get eweCardActionObserve => 'OBSERVE';

  @override
  String get eweCardActionBarren => 'BARREN';

  @override
  String get eweCardActionCull => 'CULL';

  @override
  String get eweCardObserveHeading => 'What did you see?';

  @override
  String get eweCardObserveClose => 'CLOSE';

  @override
  String get eweCardObserveCloseHint => 'Close without recording an observation.';

  @override
  String eweCardEarlierAnimal({required String tag, required String status, required String date}) {
    return 'An earlier $tag is on record — $status, last recorded $date. Separate record.';
  }

  @override
  String eweCardEarlierAnimalUndated({required String tag, required String status}) {
    return 'An earlier $tag is on record — $status. Separate record.';
  }

  @override
  String eweCardEarlierAnimalOpen({required String tag}) {
    return 'Open the earlier $tag';
  }

  @override
  String get eweStatusSold => 'sold';

  @override
  String get eweStatusDead => 'died';

  @override
  String get eweStatusCulled => 'culled';

  @override
  String eweCardSeasonHeading({required String year}) {
    return '$year';
  }

  @override
  String get eweCardNoSeasonHeading => 'No season';

  @override
  String get eweCardEmpty => 'Nothing recorded yet.';

  @override
  String get eweCardUnavailable => 'Her records could not be read.';

  @override
  String flockAddSlab({required String term}) {
    return '+ $term';
  }

  @override
  String flockAddHeading({required String term}) {
    return 'Add a $term';
  }

  @override
  String get flockAddFieldLabel => 'Tag';

  @override
  String flockAddDuplicateTag({required String tag, required String term}) {
    return '$tag is already on an active $term.';
  }

  @override
  String flockAddConfirmCreate({required String tag}) {
    return 'Create $tag';
  }

  @override
  String flockAddConfirmOpen({required String tag}) {
    return 'Open $tag';
  }

  @override
  String get flockAddClose => 'CLOSE';

  @override
  String get flockAddCloseHint => 'Close this sheet. Nothing is written until you confirm.';
}
