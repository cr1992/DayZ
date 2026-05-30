// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

/// Centralized user-facing strings for DayZ UI components.
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
}
