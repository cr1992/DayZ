// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/painting.dart';

/// 把 [text] 按 [query] 子串（大小写归一）切成「非命中 / 命中」span（D4）。
///
/// 命中段套 [hitStyle]、其余套 [baseStyle]；所有 span 文本拼回等于原文。
/// 空 / 纯空白 query 或无命中时返回单个 [baseStyle] span。
///
/// Author: @Ray
List<InlineSpan> buildHighlightedSpans(
  String text,
  String query,
  TextStyle baseStyle,
  TextStyle hitStyle,
) {
  final trimmed = query.trim();
  if (trimmed.isEmpty || text.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }
  // 个别字符小写后长度会变（如 `İ`），此时退回大小写敏感匹配，保证下标对齐。
  final folded = text.toLowerCase();
  final caseFold = folded.length == text.length;
  final haystack = caseFold ? folded : text;
  final needle = caseFold ? trimmed.toLowerCase() : trimmed;
  final spans = <InlineSpan>[];
  var cursor = 0;
  while (cursor <= text.length) {
    final hit = haystack.indexOf(needle, cursor);
    if (hit < 0) {
      break;
    }
    if (hit > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, hit), style: baseStyle));
    }
    final end = hit + needle.length;
    spans.add(TextSpan(text: text.substring(hit, end), style: hitStyle));
    cursor = end;
  }
  if (spans.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
  }
  return spans;
}

/// 摘要截取（R3）：命中首现位置超过 [lead] 个字符时，从命中前 [lead] 个字符处
/// 截起并加前缀 `…`，保证两行摘要里看得到命中；否则原样返回。
///
/// Author: @Ray
String snippetAround(String text, String query, {int lead = 16}) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) {
    return text;
  }
  final folded = text.toLowerCase();
  final hit = folded.length == text.length
      ? folded.indexOf(trimmed.toLowerCase())
      : text.indexOf(trimmed);
  if (hit <= lead) {
    return text;
  }
  return '…${text.substring(hit - lead)}';
}
