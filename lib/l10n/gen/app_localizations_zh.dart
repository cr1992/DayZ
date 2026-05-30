// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'DayZ';

  @override
  String onThisDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今天共 $count 篇',
      zero: '今天还没有记录',
    );
    return '$_temp0';
  }

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 年前',
      one: '1 年前',
      zero: '今年',
    );
    return '$_temp0';
  }

  @override
  String get locale_zh => '中文';

  @override
  String get locale_en => 'English';

  @override
  String get followSystem => '跟随系统';

  @override
  String get languageSetting => '语言设置';
}
