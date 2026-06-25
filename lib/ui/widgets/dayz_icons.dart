// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

/// Canonical SVG path data used by DayZ UI components.
///
/// Author: @Ray
abstract final class DayzIcons {
  static const String favoriteStarPath =
      'M12 2.5L14.47 8.6 21.04 9.06 16 13.3 17.58 19.69 12 16.2 6.42 19.69 8.01 13.3 2.97 9.06 9.53 8.6Z';

  static const String plusPath = 'M12 5v14M5 12h14';
  static const String menuPath = 'M4 6h16M4 12h16M4 18h16';
  static const String morePath =
      'M12 13a1 1 0 1 0 0-2 1 1 0 0 0 0 2ZM5 13a1 1 0 1 0 0-2 1 1 0 0 0 0 2ZM19 13a1 1 0 1 0 0-2 1 1 0 0 0 0 2Z';
  static const String searchPath =
      'M10.5 18a7.5 7.5 0 1 1 5.3-12.8A7.5 7.5 0 0 1 10.5 18ZM16 16l4 4';
  static const String checkPath = 'M20 6 9 17l-5-5';
  static const String closePath = 'M18 6 6 18M6 6l12 12';
  static const String chevronRightPath = 'm9 18 6-6-6-6';
  static const String clockPath =
      'M12 7v5l3 2M21 12a9 9 0 1 1-9-9 9 9 0 0 1 9 9Z';
  static const String historyClockPath =
      'M3.6 4.6v3.7h3.7M4.3 8.3A8.2 8.2 0 1 1 3.9 12.6M12 7.8v4.4l3.1 1.8';
  static const String notebookPath = 'M4 5h16v14H4zM4 9h16';
  static const String imagePath =
      'M4 5h16v14H4V5Zm3 10 3-3 3 3 2-2 3 3M8 9.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3Z';
  static const String micPath =
      'M12 14a4 4 0 0 0 4-4V6a4 4 0 0 0-8 0v4a4 4 0 0 0 4 4Zm-7-4a7 7 0 0 0 14 0M12 17v4M8 21h8';
  static const String calendarPath =
      'M3.5 9h17M8 3v3M16 3v3M6.5 4.5h11a3 3 0 0 1 3 3v10a3 3 0 0 1-3 3h-11a3 3 0 0 1-3-3v-10a3 3 0 0 1 3-3Z';
  static const String trashPath = 'M4 7h16M9 7V5h6v2M6 7l1 13h10l1-13';
  static const String settingsPath =
      'M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.1a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z';

  // ── 编辑页 meta chip 图标（真源：pages/screens/editor.html 的 .compose-meta
  // .chip-btn）。设计源中的 <circle> 在此等价转写为 path 弧段，便于走单 <path>
  // 渲染器。stroke-linecap=round 使「极简笑脸」的双眼 h.01 渲染为圆点。
  static const String moodPath = 'M9 10h.01 M15 10h.01 M8.5 14.5h7';
  static const String weatherSunPath =
      'M12 7.8a4.2 4.2 0 1 0 0 8.4 4.2 4.2 0 0 0 0-8.4ZM12 3v2M12 19v2M3 12h2M19 12h2M5.5 5.5l1.4 1.4M17.1 17.1l1.4 1.4M18.5 5.5l-1.4 1.4M6.9 17.1l-1.4 1.4';
  static const String locationPinPath =
      'M12 21s7-5.4 7-11a7 7 0 1 0-14 0c0 5.6 7 11 7 11zM12 12.4a2.4 2.4 0 1 0 0-4.8 2.4 2.4 0 0 0 0 4.8Z';
  static const String tagPath =
      'M4 12V6a2 2 0 0 1 2-2h6l8 8-8 8zM9 10.4a1.4 1.4 0 1 0 0-2.8 1.4 1.4 0 0 0 0 2.8Z';

  // 编辑器工具栏「颜色 / 高亮」= 设计稿的马克笔描边（真源：pages/screens/editor.html
  // 的 dock `data-tb="color"`），不是调色盘。设计源两条 <path>（基线 + 笔尖）在此
  // 合成单 path：第二段起点 `m14.5 4.5` 转绝对 `M14.5 4.5`，后续仍走相对 `l`，
  // 避免接在基线末端被位移。
  static const String colorMarkerPath = 'M4 20h16 M14.5 4.5l5 5-8 8-5 .9.9-5z';
}
