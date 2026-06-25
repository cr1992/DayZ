// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

/// DayZ font configuration including custom brand families and CJK system fallbacks.
///
/// Author: @Ray
abstract final class DayzFonts {
  static const String sans = 'Hanken Grotesk';
  static const String serif = 'Newsreader';
  static const String mono = 'SF Mono';

  // 兜底栈对齐设计稿 tokens.css `--font-sans`。`-apple-system` 是 Web-only
  // 关键字，Flutter 不识别，故不纳入（系统 UI 字本就是最终兜底）。
  static const List<String> sansFallback = [
    'PingFang SC',
    'Microsoft YaHei',
    'Noto Sans SC',
    'system-ui',
    'sans-serif',
  ];

  // 兜底栈对齐设计稿 tokens.css `--font-serif`。
  static const List<String> serifFallback = [
    'Songti SC',
    'SimSun',
    'Noto Serif SC',
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
