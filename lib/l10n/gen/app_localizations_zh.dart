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
  String get journalNameInputPlaceholder => '请输入日记本名称';

  @override
  String get journalNameLabel => '日记本名称';

  @override
  String get journalColorLabel => '日记本颜色';

  @override
  String get settings => '设置';

  @override
  String get timeline => '时间线';

  @override
  String get reader => '阅读';

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
}
