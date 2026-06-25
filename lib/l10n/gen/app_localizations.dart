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

  /// 搜索输入框的占位提示词
  ///
  /// In zh, this message translates to:
  /// **'搜索日记、标签、地点'**
  String get searchHint;

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

  /// No description provided for @sheetCreate.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get sheetCreate;

  /// No description provided for @journalNameInputPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'例如：读书、健身、远行'**
  String get journalNameInputPlaceholder;

  /// No description provided for @journalNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get journalNameLabel;

  /// No description provided for @journalColorLabel.
  ///
  /// In zh, this message translates to:
  /// **'封面色'**
  String get journalColorLabel;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsGroupPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'隐私与加密'**
  String get settingsGroupPrivacy;

  /// No description provided for @settingsGroupBackup.
  ///
  /// In zh, this message translates to:
  /// **'备份与导出'**
  String get settingsGroupBackup;

  /// No description provided for @settingsGroupAppearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get settingsGroupAppearance;

  /// No description provided for @settingsGroupWriting.
  ///
  /// In zh, this message translates to:
  /// **'书写'**
  String get settingsGroupWriting;

  /// 设置页账户头卡统计
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{{count} 篇}} · 本地库 {size}'**
  String settingsAccountStats(int count, String size);

  /// No description provided for @settingsAppLockTitle.
  ///
  /// In zh, this message translates to:
  /// **'App 锁'**
  String get settingsAppLockTitle;

  /// No description provided for @settingsAppLockSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'Face ID / 密码解锁'**
  String get settingsAppLockSubtitle;

  /// No description provided for @settingsDbEncryptionTitle.
  ///
  /// In zh, this message translates to:
  /// **'数据库加密'**
  String get settingsDbEncryptionTitle;

  /// No description provided for @settingsDbEncryptionSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'SQLCipher · 始终开启'**
  String get settingsDbEncryptionSubtitle;

  /// No description provided for @settingsDbEncryptedValue.
  ///
  /// In zh, this message translates to:
  /// **'已加密'**
  String get settingsDbEncryptedValue;

  /// No description provided for @settingsMediaNotLockedByPassword.
  ///
  /// In zh, this message translates to:
  /// **'设置主密码不会加密照片，照片始终用设备密钥保护'**
  String get settingsMediaNotLockedByPassword;

  /// No description provided for @settingsBackupTitle.
  ///
  /// In zh, this message translates to:
  /// **'本地备份'**
  String get settingsBackupTitle;

  /// No description provided for @settingsBackupSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'上次 · 今天 08:30'**
  String get settingsBackupSubtitle;

  /// No description provided for @settingsExportTitle.
  ///
  /// In zh, this message translates to:
  /// **'导出'**
  String get settingsExportTitle;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'PDF · Markdown · JSON'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsThemeTitle.
  ///
  /// In zh, this message translates to:
  /// **'主题色'**
  String get settingsThemeTitle;

  /// No description provided for @settingsThemeSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'雾紫 / 暖黄 / 雾绿'**
  String get settingsThemeSubtitle;

  /// No description provided for @settingsAppearanceModeTitle.
  ///
  /// In zh, this message translates to:
  /// **'外观模式'**
  String get settingsAppearanceModeTitle;

  /// No description provided for @settingsAppearanceModeSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get settingsAppearanceModeSubtitle;

  /// No description provided for @settingsDraftRecoveryTitle.
  ///
  /// In zh, this message translates to:
  /// **'恢复未完成的编辑'**
  String get settingsDraftRecoveryTitle;

  /// No description provided for @settingsDraftRecoverySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'启动时提示残留草稿'**
  String get settingsDraftRecoverySubtitle;

  /// No description provided for @settingsThemePurple.
  ///
  /// In zh, this message translates to:
  /// **'雾紫'**
  String get settingsThemePurple;

  /// No description provided for @settingsThemeAmber.
  ///
  /// In zh, this message translates to:
  /// **'暖黄'**
  String get settingsThemeAmber;

  /// No description provided for @settingsThemeSage.
  ///
  /// In zh, this message translates to:
  /// **'雾绿'**
  String get settingsThemeSage;

  /// No description provided for @settingsModeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get settingsModeSystem;

  /// No description provided for @settingsModeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get settingsModeLight;

  /// No description provided for @settingsModeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get settingsModeDark;

  /// No description provided for @settingsBackSemanticLabel.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get settingsBackSemanticLabel;

  /// No description provided for @settingsAppLockSemanticLabel.
  ///
  /// In zh, this message translates to:
  /// **'App 锁开关'**
  String get settingsAppLockSemanticLabel;

  /// No description provided for @settingsDraftRecoverySemanticLabel.
  ///
  /// In zh, this message translates to:
  /// **'恢复未完成的编辑开关'**
  String get settingsDraftRecoverySemanticLabel;

  /// No description provided for @settingsActionUnavailableToast.
  ///
  /// In zh, this message translates to:
  /// **'功能稍后支持'**
  String get settingsActionUnavailableToast;

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

  /// No description provided for @readerMetaDate.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get readerMetaDate;

  /// No description provided for @readerMetaWeather.
  ///
  /// In zh, this message translates to:
  /// **'天气'**
  String get readerMetaWeather;

  /// No description provided for @readerMetaPlace.
  ///
  /// In zh, this message translates to:
  /// **'地点'**
  String get readerMetaPlace;

  /// No description provided for @readerMetaMood.
  ///
  /// In zh, this message translates to:
  /// **'心情'**
  String get readerMetaMood;

  /// No description provided for @readerMetaTags.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get readerMetaTags;

  /// 阅读页日期语义标签
  ///
  /// In zh, this message translates to:
  /// **'日记日期：{date}'**
  String readerDateSemantic(String date);

  /// 阅读页天气语义标签
  ///
  /// In zh, this message translates to:
  /// **'天气：{weather}'**
  String readerWeatherSemantic(String weather);

  /// 阅读页地点语义标签
  ///
  /// In zh, this message translates to:
  /// **'地点：{place}'**
  String readerPlaceSemantic(String place);

  /// 阅读页心情语义标签
  ///
  /// In zh, this message translates to:
  /// **'心情：{mood}'**
  String readerMoodSemantic(String mood);

  /// 阅读页标签语义标签
  ///
  /// In zh, this message translates to:
  /// **'标签：{tag}'**
  String readerTagSemantic(String tag);

  /// No description provided for @readerActionsSemantic.
  ///
  /// In zh, this message translates to:
  /// **'阅读页操作'**
  String get readerActionsSemantic;

  /// No description provided for @readerActionEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get readerActionEdit;

  /// No description provided for @readerActionShare.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get readerActionShare;

  /// No description provided for @readerActionMoveToJournal.
  ///
  /// In zh, this message translates to:
  /// **'移到日记本'**
  String get readerActionMoveToJournal;

  /// No description provided for @readerActionFavorite.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get readerActionFavorite;

  /// No description provided for @readerActionUnfavorite.
  ///
  /// In zh, this message translates to:
  /// **'取消收藏'**
  String get readerActionUnfavorite;

  /// No description provided for @readerActionDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get readerActionDelete;

  /// No description provided for @readerDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除这篇日记？'**
  String get readerDeleteTitle;

  /// No description provided for @readerDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'删除后会移到回收站，可在回收站恢复。'**
  String get readerDeleteMessage;

  /// No description provided for @readerDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'移到回收站'**
  String get readerDeleteConfirm;

  /// No description provided for @readerEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'没有找到这篇日记'**
  String get readerEmptyTitle;

  /// No description provided for @readerEmptyDescription.
  ///
  /// In zh, this message translates to:
  /// **'它可能已被删除，或不在当前日记本中。'**
  String get readerEmptyDescription;

  /// No description provided for @readerToastFavoriteAdded.
  ///
  /// In zh, this message translates to:
  /// **'已收藏'**
  String get readerToastFavoriteAdded;

  /// No description provided for @readerToastFavoriteRemoved.
  ///
  /// In zh, this message translates to:
  /// **'已取消收藏'**
  String get readerToastFavoriteRemoved;

  /// No description provided for @readerToastDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已移到回收站'**
  String get readerToastDeleted;

  /// No description provided for @readerToastRestored.
  ///
  /// In zh, this message translates to:
  /// **'已恢复'**
  String get readerToastRestored;

  /// 阅读页移本成功 toast
  ///
  /// In zh, this message translates to:
  /// **'已移到「{journalName}」'**
  String readerToastMovedToJournal(String journalName);

  /// No description provided for @readerToastSharePending.
  ///
  /// In zh, this message translates to:
  /// **'分享功能稍后支持'**
  String get readerToastSharePending;

  /// No description provided for @readerToastActionFailed.
  ///
  /// In zh, this message translates to:
  /// **'操作失败，请重试'**
  String get readerToastActionFailed;

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

  /// No description provided for @editorTitleNew.
  ///
  /// In zh, this message translates to:
  /// **'新日记'**
  String get editorTitleNew;

  /// No description provided for @editorTitleDraftSaved.
  ///
  /// In zh, this message translates to:
  /// **'草稿已存'**
  String get editorTitleDraftSaved;

  /// No description provided for @editorTitlePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'标题'**
  String get editorTitlePlaceholder;

  /// No description provided for @editorBodyPlaceholderEmpty.
  ///
  /// In zh, this message translates to:
  /// **'写点什么吧……'**
  String get editorBodyPlaceholderEmpty;

  /// No description provided for @editorBodyPlaceholderWriting.
  ///
  /// In zh, this message translates to:
  /// **'在这里继续写下今天的故事'**
  String get editorBodyPlaceholderWriting;

  /// No description provided for @editorDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get editorDone;

  /// No description provided for @editorCloseSemanticLabel.
  ///
  /// In zh, this message translates to:
  /// **'关闭编辑页'**
  String get editorCloseSemanticLabel;

  /// No description provided for @editorDoneSemanticLabel.
  ///
  /// In zh, this message translates to:
  /// **'完成并返回'**
  String get editorDoneSemanticLabel;

  /// No description provided for @editorMetaMood.
  ///
  /// In zh, this message translates to:
  /// **'心情'**
  String get editorMetaMood;

  /// No description provided for @editorMetaWeather.
  ///
  /// In zh, this message translates to:
  /// **'天气'**
  String get editorMetaWeather;

  /// No description provided for @editorMetaLocation.
  ///
  /// In zh, this message translates to:
  /// **'地点'**
  String get editorMetaLocation;

  /// No description provided for @editorMetaTags.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get editorMetaTags;

  /// No description provided for @editorMetaPlaceholderSheet.
  ///
  /// In zh, this message translates to:
  /// **'选择器将在后续规格中接入'**
  String get editorMetaPlaceholderSheet;

  /// 编辑页今天日期 kicker
  ///
  /// In zh, this message translates to:
  /// **'今天 · {date} {weekday}'**
  String editorDateKickerToday(String date, String weekday);

  /// 编辑页非今天日期 kicker
  ///
  /// In zh, this message translates to:
  /// **'{date} {weekday}'**
  String editorDateKicker(String date, String weekday);

  /// No description provided for @editorToolbarFormat.
  ///
  /// In zh, this message translates to:
  /// **'Aa·格式'**
  String get editorToolbarFormat;

  /// No description provided for @editorToolbarHeading.
  ///
  /// In zh, this message translates to:
  /// **'标题'**
  String get editorToolbarHeading;

  /// No description provided for @editorToolbarBold.
  ///
  /// In zh, this message translates to:
  /// **'粗体'**
  String get editorToolbarBold;

  /// No description provided for @editorToolbarItalic.
  ///
  /// In zh, this message translates to:
  /// **'斜体'**
  String get editorToolbarItalic;

  /// No description provided for @editorToolbarUnderline.
  ///
  /// In zh, this message translates to:
  /// **'下划线'**
  String get editorToolbarUnderline;

  /// No description provided for @editorToolbarStrikethrough.
  ///
  /// In zh, this message translates to:
  /// **'删除线'**
  String get editorToolbarStrikethrough;

  /// No description provided for @editorToolbarCode.
  ///
  /// In zh, this message translates to:
  /// **'行内代码'**
  String get editorToolbarCode;

  /// No description provided for @editorToolbarColor.
  ///
  /// In zh, this message translates to:
  /// **'颜色高亮'**
  String get editorToolbarColor;

  /// No description provided for @editorToolbarBulletedList.
  ///
  /// In zh, this message translates to:
  /// **'无序列表'**
  String get editorToolbarBulletedList;

  /// No description provided for @editorToolbarNumberedList.
  ///
  /// In zh, this message translates to:
  /// **'有序列表'**
  String get editorToolbarNumberedList;

  /// No description provided for @editorToolbarTodoList.
  ///
  /// In zh, this message translates to:
  /// **'待办列表'**
  String get editorToolbarTodoList;

  /// No description provided for @editorToolbarQuote.
  ///
  /// In zh, this message translates to:
  /// **'引用'**
  String get editorToolbarQuote;

  /// No description provided for @editorToolbarCallout.
  ///
  /// In zh, this message translates to:
  /// **'标注'**
  String get editorToolbarCallout;

  /// No description provided for @editorToolbarLink.
  ///
  /// In zh, this message translates to:
  /// **'链接'**
  String get editorToolbarLink;

  /// No description provided for @editorToolbarDivider.
  ///
  /// In zh, this message translates to:
  /// **'分隔线'**
  String get editorToolbarDivider;

  /// No description provided for @editorToolbarImage.
  ///
  /// In zh, this message translates to:
  /// **'图片'**
  String get editorToolbarImage;

  /// No description provided for @editorImagePickerDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get editorImagePickerDone;

  /// No description provided for @editorImagePickerCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get editorImagePickerCancel;

  /// No description provided for @editorImagePickerPreview.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get editorImagePickerPreview;

  /// No description provided for @editorImagePickerOriginal.
  ///
  /// In zh, this message translates to:
  /// **'原图'**
  String get editorImagePickerOriginal;

  /// No description provided for @editorImagePickerCamera.
  ///
  /// In zh, this message translates to:
  /// **'拍照'**
  String get editorImagePickerCamera;

  /// No description provided for @editorImagePickerAllPhotos.
  ///
  /// In zh, this message translates to:
  /// **'最近项目'**
  String get editorImagePickerAllPhotos;

  /// No description provided for @editorFormatSectionParagraph.
  ///
  /// In zh, this message translates to:
  /// **'段落'**
  String get editorFormatSectionParagraph;

  /// No description provided for @editorFormatSectionBlocks.
  ///
  /// In zh, this message translates to:
  /// **'列表与块'**
  String get editorFormatSectionBlocks;

  /// No description provided for @editorFormatSectionText.
  ///
  /// In zh, this message translates to:
  /// **'文字样式'**
  String get editorFormatSectionText;

  /// No description provided for @editorColorTextRust.
  ///
  /// In zh, this message translates to:
  /// **'红褐'**
  String get editorColorTextRust;

  /// No description provided for @editorColorTextAmber.
  ///
  /// In zh, this message translates to:
  /// **'暖橙'**
  String get editorColorTextAmber;

  /// No description provided for @editorColorTextBronze.
  ///
  /// In zh, this message translates to:
  /// **'金棕'**
  String get editorColorTextBronze;

  /// No description provided for @editorColorTextOlive.
  ///
  /// In zh, this message translates to:
  /// **'橄榄'**
  String get editorColorTextOlive;

  /// No description provided for @editorColorTextSlate.
  ///
  /// In zh, this message translates to:
  /// **'雾蓝'**
  String get editorColorTextSlate;

  /// No description provided for @editorColorTextLilac.
  ///
  /// In zh, this message translates to:
  /// **'雾紫'**
  String get editorColorTextLilac;

  /// No description provided for @editorColorHighlightYellow.
  ///
  /// In zh, this message translates to:
  /// **'暖黄'**
  String get editorColorHighlightYellow;

  /// No description provided for @editorColorHighlightGreen.
  ///
  /// In zh, this message translates to:
  /// **'浅绿'**
  String get editorColorHighlightGreen;

  /// No description provided for @editorColorHighlightBlue.
  ///
  /// In zh, this message translates to:
  /// **'浅蓝'**
  String get editorColorHighlightBlue;

  /// No description provided for @editorColorHighlightPurple.
  ///
  /// In zh, this message translates to:
  /// **'浅紫'**
  String get editorColorHighlightPurple;

  /// No description provided for @editorColorHighlightPink.
  ///
  /// In zh, this message translates to:
  /// **'浅粉'**
  String get editorColorHighlightPink;

  /// No description provided for @editorHeadingParagraphGlyph.
  ///
  /// In zh, this message translates to:
  /// **'正文'**
  String get editorHeadingParagraphGlyph;

  /// No description provided for @editorHeadingParagraphLabel.
  ///
  /// In zh, this message translates to:
  /// **'段落'**
  String get editorHeadingParagraphLabel;

  /// No description provided for @editorHeadingLabelH1.
  ///
  /// In zh, this message translates to:
  /// **'大标题'**
  String get editorHeadingLabelH1;

  /// No description provided for @editorHeadingLabelH2.
  ///
  /// In zh, this message translates to:
  /// **'中标题'**
  String get editorHeadingLabelH2;

  /// No description provided for @editorHeadingLabelH3.
  ///
  /// In zh, this message translates to:
  /// **'小标题'**
  String get editorHeadingLabelH3;
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
