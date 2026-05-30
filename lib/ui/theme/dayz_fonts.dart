// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

/// DayZ font configuration including custom brand families and CJK system fallbacks.
///
/// Author: @Ray
abstract final class DayzFonts {
  static const String sans = 'Hanken Grotesk';
  static const String serif = 'Newsreader';

  static const List<String> sansFallback = [
    'PingFang SC',
    'Heiti SC',
    'Microsoft YaHei',
    'Noto Sans CJK SC',
    'system-ui',
    'sans-serif',
  ];

  static const List<String> serifFallback = [
    'Songti SC',
    'SimSun',
    'Noto Serif CJK SC',
    'Georgia',
    'serif',
  ];
}
