// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

/// Legacy user-facing strings bucket kept only for older UI surfaces.
///
/// Do not add new copy here. New user-visible strings must live in
/// `lib/l10n/app_zh.arb` and `lib/l10n/app_en.arb`, and be read via
/// `AppLocalizations.of(context)`.
///
/// Author: @Ray
abstract final class AppStrings {
  static const String toastDefault = '提示';
  static const String toastUndo = '撤销';
  static const String toastView = '查看';
  static const String toastRetry = '重试';
  static const String toastDismiss = '关闭';

  static const String sheetCancel = '取消';
  static const String sheetDelete = '删除';
  static const String sheetConfirm = '确认';
  static const String sheetSelected = '已选择';

  static const String emptyTitle = '这里还没有内容';
  static const String emptyDescription = '写下第一篇日记后，它会出现在这里。';

  static const String favorite = '收藏';
  static const String unfavorite = '取消收藏';
  static const String menu = '菜单';
  static const String more = '更多';
  static const String close = '关闭';
  static const String search = '搜索';
  static const String searchCancel = '取消搜索';
  static const String clear = '清除';
  static const String remove = '移除';
  static const String add = '添加';
  static const String edit = '编辑';
  static const String delete = '删除';
  static const String confirm = '确认';
  static const String cancel = '取消';
  static const String selected = '已选中';
  static const String unselected = '未选中';
  static const String switchOn = '已开启';
  static const String switchOff = '已关闭';
  static const String previous = '上一项';
  static const String next = '下一项';
  static const String showMore = '显示更多';
  static const String camera = '拍照';
  static const String voice = '语音';
  static const String plainText = '纯文字';

  static String galleryMoreCount(int count) => '+$count';
  static String entryCount(int count) => '$count 篇';
  static String yearsAgo(int years) => '$years 年前';
  static const String loadingEarlier = '载入更早...';
  static const String reachedOldest = '已经到最早的一篇了';
  static const String timelineEmptyTitle = '这里还没有日记';
  static const String timelineEmptyDescription = '轻点右下角，写下第一页。';
  static const String jumpToDate = '跳转到日期';
  static const String backToToday = '回到今天';

  // Shell and Navigation strings
  static const String drawerProfileName = 'DayZ';
  static const String drawerProfileInitial = 'D';
  static const String drawerProfileStatus = '本地 · 已加密';
  static const String shellPlaceholderSuffix = '待页面级 spec 实现';
  static const String allJournals = '全部日记';
  static const String journalSectionHeader = '日记本';
  static const String browseSectionHeader = '浏览';
  static const String newJournal = '新建日记本';
  static const String journalNameInputPlaceholder = '请输入日记本名称';
  static const String journalNameLabel = '日记本名称';
  static const String journalColorLabel = '日记本颜色';
  static const String settings = '设置';
  static const String timeline = '时间线';
  static const String reader = '阅读';
  static const String editor = '编辑';
  static const String onThisDay = '往年今日';
  static const String calendar = '日历';
  static const String favorites = '收藏';
  static const String trash = '回收站';
  static const String memoryCardExport = '回忆卡导出';
  static const String debugHome = 'Debug Home';
}
