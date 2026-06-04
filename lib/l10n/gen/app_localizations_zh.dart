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

  @override
  String get toastDefault => '提示';

  @override
  String get toastUndo => '撤销';

  @override
  String get toastView => '查看';

  @override
  String get toastRetry => '重试';

  @override
  String get toastDismiss => '关闭';

  @override
  String get sheetCancel => '取消';

  @override
  String get sheetDelete => '删除';

  @override
  String get sheetConfirm => '确认';

  @override
  String get sheetSelected => '已选择';

  @override
  String get emptyTitle => '这里还没有内容';

  @override
  String get emptyDescription => '写下第一篇日记后，它会出现在这里。';

  @override
  String get favorite => '收藏';

  @override
  String get unfavorite => '取消收藏';

  @override
  String get menu => '菜单';

  @override
  String get more => '更多';

  @override
  String get close => '关闭';

  @override
  String get search => '搜索';

  @override
  String get searchCancel => '取消搜索';

  @override
  String get searchHint => '搜索日记、标签、地点';

  @override
  String get clear => '清除';

  @override
  String get remove => '移除';

  @override
  String get add => '添加';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get confirm => '确认';

  @override
  String get cancel => '取消';

  @override
  String get selected => '已选中';

  @override
  String get unselected => '未选中';

  @override
  String get switchOn => '已开启';

  @override
  String get switchOff => '已关闭';

  @override
  String get previous => '上一项';

  @override
  String get next => '下一项';

  @override
  String get showMore => '显示更多';

  @override
  String get camera => '拍照';

  @override
  String get voice => '语音';

  @override
  String get plainText => '纯文字';

  @override
  String galleryMoreCount(int count) {
    return '+$count';
  }

  @override
  String entryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 篇',
    );
    return '$_temp0';
  }

  @override
  String get loadingEarlier => '载入更早...';

  @override
  String get reachedOldest => '已经到最早的一篇了';

  @override
  String get timelineEmptyTitle => '这里还没有日记';

  @override
  String get timelineEmptyDescription => '轻点右下角，写下第一页。';

  @override
  String get jumpToDate => '跳转到日期';

  @override
  String get backToToday => '回到今天';

  @override
  String get drawerProfileName => 'DayZ';

  @override
  String get drawerProfileInitial => 'D';

  @override
  String get drawerProfileStatus => '本地 · 已加密';

  @override
  String get shellPlaceholderSuffix => '待页面级 spec 实现';

  @override
  String get allJournals => '全部日记';

  @override
  String get journalSectionHeader => '日记本';

  @override
  String get browseSectionHeader => '浏览';

  @override
  String get newJournal => '新建日记本';

  @override
  String get sheetCreate => '创建';

  @override
  String get journalNameInputPlaceholder => '例如：读书、健身、远行';

  @override
  String get journalNameLabel => '名称';

  @override
  String get journalColorLabel => '封面色';

  @override
  String get settings => '设置';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsGroupPrivacy => '隐私与加密';

  @override
  String get settingsGroupBackup => '备份与导出';

  @override
  String get settingsGroupAppearance => '外观';

  @override
  String get settingsGroupWriting => '书写';

  @override
  String settingsAccountStats(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 篇',
    );
    return '$_temp0 · 本地库 $size';
  }

  @override
  String get settingsAppLockTitle => 'App 锁';

  @override
  String get settingsAppLockSubtitle => 'Face ID / 密码解锁';

  @override
  String get settingsDbEncryptionTitle => '数据库加密';

  @override
  String get settingsDbEncryptionSubtitle => 'SQLCipher · 始终开启';

  @override
  String get settingsDbEncryptedValue => '已加密';

  @override
  String get settingsMediaNotLockedByPassword => '设置主密码不会加密照片，照片始终用设备密钥保护';

  @override
  String get settingsBackupTitle => '本地备份';

  @override
  String get settingsBackupSubtitle => '上次 · 今天 08:30';

  @override
  String get settingsExportTitle => '导出';

  @override
  String get settingsExportSubtitle => 'PDF · Markdown · JSON';

  @override
  String get settingsThemeTitle => '主题色';

  @override
  String get settingsThemeSubtitle => '雾紫 / 暖黄 / 雾绿';

  @override
  String get settingsAppearanceModeTitle => '外观模式';

  @override
  String get settingsAppearanceModeSubtitle => '跟随系统';

  @override
  String get settingsDraftRecoveryTitle => '恢复未完成的编辑';

  @override
  String get settingsDraftRecoverySubtitle => '启动时提示残留草稿';

  @override
  String get settingsThemePurple => '雾紫';

  @override
  String get settingsThemeAmber => '暖黄';

  @override
  String get settingsThemeSage => '雾绿';

  @override
  String get settingsModeSystem => '跟随系统';

  @override
  String get settingsModeLight => '浅色';

  @override
  String get settingsModeDark => '深色';

  @override
  String get settingsBackSemanticLabel => '返回';

  @override
  String get settingsAppLockSemanticLabel => 'App 锁开关';

  @override
  String get settingsDraftRecoverySemanticLabel => '恢复未完成的编辑开关';

  @override
  String get settingsActionUnavailableToast => '功能稍后支持';

  @override
  String get timeline => '时间线';

  @override
  String get reader => '阅读';

  @override
  String get readerMetaDate => '日期';

  @override
  String get readerMetaWeather => '天气';

  @override
  String get readerMetaPlace => '地点';

  @override
  String get readerMetaMood => '心情';

  @override
  String get readerMetaTags => '标签';

  @override
  String readerDateSemantic(String date) {
    return '日记日期：$date';
  }

  @override
  String readerWeatherSemantic(String weather) {
    return '天气：$weather';
  }

  @override
  String readerPlaceSemantic(String place) {
    return '地点：$place';
  }

  @override
  String readerMoodSemantic(String mood) {
    return '心情：$mood';
  }

  @override
  String readerTagSemantic(String tag) {
    return '标签：$tag';
  }

  @override
  String get readerActionsSemantic => '阅读页操作';

  @override
  String get readerActionEdit => '编辑';

  @override
  String get readerActionShare => '分享';

  @override
  String get readerActionMoveToJournal => '移到日记本';

  @override
  String get readerActionFavorite => '收藏';

  @override
  String get readerActionUnfavorite => '取消收藏';

  @override
  String get readerActionDelete => '删除';

  @override
  String get readerDeleteTitle => '删除这篇日记？';

  @override
  String get readerDeleteMessage => '删除后会移到回收站，可在回收站恢复。';

  @override
  String get readerDeleteConfirm => '移到回收站';

  @override
  String get readerEmptyTitle => '没有找到这篇日记';

  @override
  String get readerEmptyDescription => '它可能已被删除，或不在当前日记本中。';

  @override
  String get readerToastFavoriteAdded => '已收藏';

  @override
  String get readerToastFavoriteRemoved => '已取消收藏';

  @override
  String get readerToastDeleted => '已移到回收站';

  @override
  String get readerToastRestored => '已恢复';

  @override
  String readerToastMovedToJournal(String journalName) {
    return '已移到「$journalName」';
  }

  @override
  String get readerToastSharePending => '分享功能稍后支持';

  @override
  String get readerToastActionFailed => '操作失败，请重试';

  @override
  String get editor => '编辑';

  @override
  String get onThisDay => '往年今日';

  @override
  String get calendar => '日历';

  @override
  String get favorites => '收藏';

  @override
  String get trash => '回收站';

  @override
  String get memoryCardExport => '回忆卡导出';

  @override
  String get debugHome => 'Debug Home';

  @override
  String get notFound => '未找到';

  @override
  String get editorTitleNew => '新日记';

  @override
  String get editorTitleDraftSaved => '草稿已存';

  @override
  String get editorTitlePlaceholder => '标题';

  @override
  String get editorBodyPlaceholderEmpty => '写点什么吧……';

  @override
  String get editorBodyPlaceholderWriting => '在这里继续写下今天的故事';

  @override
  String get editorDone => '完成';

  @override
  String get editorCloseSemanticLabel => '关闭编辑页';

  @override
  String get editorDoneSemanticLabel => '完成并返回';

  @override
  String get editorMetaMood => '心情';

  @override
  String get editorMetaWeather => '天气';

  @override
  String get editorMetaLocation => '地点';

  @override
  String get editorMetaTags => '标签';

  @override
  String get editorMetaPlaceholderSheet => '选择器将在后续规格中接入';

  @override
  String editorDateKickerToday(String date, String weekday) {
    return '今天 · $date $weekday';
  }

  @override
  String editorDateKicker(String date, String weekday) {
    return '$date $weekday';
  }

  @override
  String get editorToolbarHeading => '标题';

  @override
  String get editorToolbarBold => '粗体';

  @override
  String get editorToolbarItalic => '斜体';

  @override
  String get editorToolbarUnderline => '下划线';

  @override
  String get editorToolbarStrikethrough => '删除线';

  @override
  String get editorToolbarCode => '行内代码';

  @override
  String get editorToolbarColor => '颜色高亮';

  @override
  String get editorToolbarBulletedList => '无序列表';

  @override
  String get editorToolbarNumberedList => '有序列表';

  @override
  String get editorToolbarTodoList => '待办列表';

  @override
  String get editorToolbarQuote => '引用';

  @override
  String get editorToolbarLink => '链接';

  @override
  String get editorToolbarDivider => '分隔线';

  @override
  String get editorToolbarImage => '图片';

  @override
  String get editorColorTextRust => '红褐';

  @override
  String get editorColorTextAmber => '暖橙';

  @override
  String get editorColorTextBronze => '金棕';

  @override
  String get editorColorTextOlive => '橄榄';

  @override
  String get editorColorTextSlate => '雾蓝';

  @override
  String get editorColorTextLilac => '雾紫';

  @override
  String get editorColorHighlightYellow => '暖黄';

  @override
  String get editorColorHighlightGreen => '浅绿';

  @override
  String get editorColorHighlightBlue => '浅蓝';

  @override
  String get editorColorHighlightPurple => '浅紫';

  @override
  String get editorColorHighlightPink => '浅粉';

  @override
  String get editorHeadingParagraphGlyph => '正文';

  @override
  String get editorHeadingParagraphLabel => '段落';

  @override
  String get editorHeadingLabelH1 => '大标题';

  @override
  String get editorHeadingLabelH2 => '中标题';

  @override
  String get editorHeadingLabelH3 => '小标题';
}
