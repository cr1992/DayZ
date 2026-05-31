import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// App 标题
  ///
  /// In zh, this message translates to:
  /// **'DayZ'**
  String get appTitle;

  /// 往年今日条目数
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =0{今天还没有记录} other{今天共 {count} 篇}}'**
  String onThisDayCount(int count);

  /// 相对年份
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =0{今年} =1{1 年前} other{{count} 年前}}'**
  String yearsAgo(int count);

  /// 中文语言名称
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get locale_zh;

  /// 英文语言名称
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get locale_en;

  /// 语言设置：跟随系统
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get followSystem;

  /// 语言设置标题
  ///
  /// In zh, this message translates to:
  /// **'语言设置'**
  String get languageSetting;

  /// No description provided for @toastDefault.
  ///
  /// In zh, this message translates to:
  /// **'提示'**
  String get toastDefault;

  /// No description provided for @toastUndo.
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get toastUndo;

  /// No description provided for @toastView.
  ///
  /// In zh, this message translates to:
  /// **'查看'**
  String get toastView;

  /// No description provided for @toastRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get toastRetry;

  /// No description provided for @toastDismiss.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get toastDismiss;

  /// No description provided for @sheetCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get sheetCancel;

  /// No description provided for @sheetDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get sheetDelete;

  /// No description provided for @sheetConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get sheetConfirm;

  /// No description provided for @sheetSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选择'**
  String get sheetSelected;

  /// No description provided for @emptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'这里还没有内容'**
  String get emptyTitle;

  /// No description provided for @emptyDescription.
  ///
  /// In zh, this message translates to:
  /// **'写下第一篇日记后，它会出现在这里。'**
  String get emptyDescription;

  /// No description provided for @favorite.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get favorite;

  /// No description provided for @unfavorite.
  ///
  /// In zh, this message translates to:
  /// **'取消收藏'**
  String get unfavorite;

  /// No description provided for @menu.
  ///
  /// In zh, this message translates to:
  /// **'菜单'**
  String get menu;

  /// No description provided for @more.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get more;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @search.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get search;

  /// No description provided for @searchCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消搜索'**
  String get searchCancel;

  /// No description provided for @clear.
  ///
  /// In zh, this message translates to:
  /// **'清除'**
  String get clear;

  /// No description provided for @remove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get remove;

  /// No description provided for @add.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @selected.
  ///
  /// In zh, this message translates to:
  /// **'已选中'**
  String get selected;

  /// No description provided for @unselected.
  ///
  /// In zh, this message translates to:
  /// **'未选中'**
  String get unselected;

  /// No description provided for @switchOn.
  ///
  /// In zh, this message translates to:
  /// **'已开启'**
  String get switchOn;

  /// No description provided for @switchOff.
  ///
  /// In zh, this message translates to:
  /// **'已关闭'**
  String get switchOff;

  /// No description provided for @previous.
  ///
  /// In zh, this message translates to:
  /// **'上一项'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In zh, this message translates to:
  /// **'下一项'**
  String get next;

  /// No description provided for @showMore.
  ///
  /// In zh, this message translates to:
  /// **'显示更多'**
  String get showMore;

  /// No description provided for @camera.
  ///
  /// In zh, this message translates to:
  /// **'拍照'**
  String get camera;

  /// No description provided for @voice.
  ///
  /// In zh, this message translates to:
  /// **'语音'**
  String get voice;

  /// No description provided for @plainText.
  ///
  /// In zh, this message translates to:
  /// **'纯文字'**
  String get plainText;

  /// 画廊折叠时剩余图片数
  ///
  /// In zh, this message translates to:
  /// **'+{count}'**
  String galleryMoreCount(int count);

  /// 条目数量
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{{count} 篇}}'**
  String entryCount(int count);

  /// No description provided for @loadingEarlier.
  ///
  /// In zh, this message translates to:
  /// **'载入更早...'**
  String get loadingEarlier;

  /// No description provided for @reachedOldest.
  ///
  /// In zh, this message translates to:
  /// **'已经到最早的一篇了'**
  String get reachedOldest;

  /// No description provided for @timelineEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'这里还没有日记'**
  String get timelineEmptyTitle;

  /// No description provided for @timelineEmptyDescription.
  ///
  /// In zh, this message translates to:
  /// **'轻点右下角，写下第一页。'**
  String get timelineEmptyDescription;

  /// No description provided for @jumpToDate.
  ///
  /// In zh, this message translates to:
  /// **'跳转到日期'**
  String get jumpToDate;

  /// No description provided for @backToToday.
  ///
  /// In zh, this message translates to:
  /// **'回到今天'**
  String get backToToday;

  /// No description provided for @drawerProfileName.
  ///
  /// In zh, this message translates to:
  /// **'DayZ'**
  String get drawerProfileName;

  /// No description provided for @drawerProfileInitial.
  ///
  /// In zh, this message translates to:
  /// **'D'**
  String get drawerProfileInitial;

  /// No description provided for @drawerProfileStatus.
  ///
  /// In zh, this message translates to:
  /// **'本地 · 已加密'**
  String get drawerProfileStatus;

  /// No description provided for @shellPlaceholderSuffix.
  ///
  /// In zh, this message translates to:
  /// **'待页面级 spec 实现'**
  String get shellPlaceholderSuffix;

  /// No description provided for @allJournals.
  ///
  /// In zh, this message translates to:
  /// **'全部日记'**
  String get allJournals;

  /// No description provided for @journalSectionHeader.
  ///
  /// In zh, this message translates to:
  /// **'日记本'**
  String get journalSectionHeader;

  /// No description provided for @browseSectionHeader.
  ///
  /// In zh, this message translates to:
  /// **'浏览'**
  String get browseSectionHeader;

  /// No description provided for @newJournal.
  ///
  /// In zh, this message translates to:
  /// **'新建日记本'**
  String get newJournal;

  /// No description provided for @journalNameInputPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'请输入日记本名称'**
  String get journalNameInputPlaceholder;

  /// No description provided for @journalNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'日记本名称'**
  String get journalNameLabel;

  /// No description provided for @journalColorLabel.
  ///
  /// In zh, this message translates to:
  /// **'日记本颜色'**
  String get journalColorLabel;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @timeline.
  ///
  /// In zh, this message translates to:
  /// **'时间线'**
  String get timeline;

  /// No description provided for @reader.
  ///
  /// In zh, this message translates to:
  /// **'阅读'**
  String get reader;

  /// No description provided for @editor.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get editor;

  /// No description provided for @onThisDay.
  ///
  /// In zh, this message translates to:
  /// **'往年今日'**
  String get onThisDay;

  /// No description provided for @calendar.
  ///
  /// In zh, this message translates to:
  /// **'日历'**
  String get calendar;

  /// No description provided for @favorites.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get favorites;

  /// No description provided for @trash.
  ///
  /// In zh, this message translates to:
  /// **'回收站'**
  String get trash;

  /// No description provided for @memoryCardExport.
  ///
  /// In zh, this message translates to:
  /// **'回忆卡导出'**
  String get memoryCardExport;

  /// No description provided for @debugHome.
  ///
  /// In zh, this message translates to:
  /// **'Debug Home'**
  String get debugHome;

  /// No description provided for @notFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到'**
  String get notFound;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
