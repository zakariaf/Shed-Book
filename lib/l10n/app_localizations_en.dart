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
}
