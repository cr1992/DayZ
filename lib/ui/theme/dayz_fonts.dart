// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

/// DayZ font configuration including custom brand families and CJK system fallbacks.
///
/// Author: @Ray
abstract final class DayzFonts {
  static const String sans = 'Hanken Grotesk';
  static const String serif = 'Newsreader';
  static const String mono = 'SF Mono';

  // CJK 兜底栈：打包的「思源黑体」(Noto Sans SC) 置顶，作为中文主力，使各平台
  // 渲染一致、不再依赖系统字；其后接系统 PingFang/雅黑，兜「思源未覆盖的生僻字」
  // (打包子集约 8200 字)。`-apple-system` 是 Web-only 关键字，Flutter 不识别故略去。
  static const List<String> sansFallback = [
    'Noto Sans SC',
    'PingFang SC',
    'Microsoft YaHei',
    'system-ui',
    'sans-serif',
  ];

  // CJK 兜底栈：打包的「思源宋体」(Noto Serif SC) 置顶（日记/标题书卷气主力），
  // 其后接系统 Songti/SimSun 兜生僻字。
  static const List<String> serifFallback = [
    'Noto Serif SC',
    'Songti SC',
    'SimSun',
    'Georgia',
    'serif',
  ];

  static const List<String> monoFallback = [
    'ui-monospace',
    'JetBrains Mono',
    'Menlo',
    'monospace',
  ];
}
