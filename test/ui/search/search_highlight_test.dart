// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/ui/search/search_highlight.dart';

const base = TextStyle(color: Color(0xFF111111));
const hit = TextStyle(
  color: Color(0xFF6B4FA0),
  backgroundColor: Color(0xFFE7DEF5),
);

/// (片段文本, 是否命中)
List<(String, bool)> segments(List<InlineSpan> spans) {
  return [
    for (final span in spans)
      (
        (span as TextSpan).text!,
        identical(span.style, hit)
            ? true
            : identical(span.style, base)
            ? false
            : throw StateError('unexpected style'),
      ),
  ];
}

String joined(List<InlineSpan> spans) =>
    spans.map((span) => (span as TextSpan).text).join();

void main() {
  group('buildHighlightedSpans', () {
    test('empty / blank query → single base span', () {
      for (final query in ['', '   ']) {
        final spans = buildHighlightedSpans('外婆教我腌的梅子', query, base, hit);
        expect(segments(spans), [('外婆教我腌的梅子', false)]);
      }
    });

    test('no hit → single base span', () {
      final spans = buildHighlightedSpans('开了去年的那罐', '梅子', base, hit);
      expect(segments(spans), [('开了去年的那罐', false)]);
    });

    test('hit at end (design sample)', () {
      final spans = buildHighlightedSpans('外婆教我腌的梅子', '梅子', base, hit);
      expect(segments(spans), [('外婆教我腌的', false), ('梅子', true)]);
    });

    test('multiple hits in the middle keep order and full text', () {
      const text = '玻璃罐要先用开水烫过，梅子和冰糖一层一层码好。梅子要等一整个夏天。';
      final spans = buildHighlightedSpans(text, '梅子', base, hit);
      expect(joined(spans), text);
      expect(segments(spans), [
        ('玻璃罐要先用开水烫过，', false),
        ('梅子', true),
        ('和冰糖一层一层码好。', false),
        ('梅子', true),
        ('要等一整个夏天。', false),
      ]);
    });

    test('adjacent hits and hit at start', () {
      final spans = buildHighlightedSpans('哈哈哈x', '哈', base, hit);
      expect(segments(spans), [
        ('哈', true),
        ('哈', true),
        ('哈', true),
        ('x', false),
      ]);
    });

    test('case-insensitive match keeps original casing', () {
      const text = 'Plum jam and PLUM wine';
      final spans = buildHighlightedSpans(text, 'plum', base, hit);
      expect(joined(spans), text);
      expect(segments(spans), [
        ('Plum', true),
        (' jam and ', false),
        ('PLUM', true),
        (' wine', false),
      ]);
    });

    test('query is trimmed before matching', () {
      final spans = buildHighlightedSpans('梅子酱', ' 梅子 ', base, hit);
      expect(segments(spans), [('梅子', true), ('酱', false)]);
    });
  });

  group('snippetAround', () {
    test('near hit → unchanged', () {
      const text = '放了一整年，梅子的颜色变得很深。';
      expect(snippetAround(text, '梅子'), text);
    });

    test('far hit → cut to lead chars before hit with ellipsis', () {
      final text = '${'甲' * 40}梅子的颜色变得很深';
      final snippet = snippetAround(text, '梅子', lead: 4);
      expect(snippet, '…甲甲甲甲梅子的颜色变得很深');
      expect(snippet.contains('梅子'), isTrue);
    });

    test('no hit / empty query → unchanged', () {
      final text = '甲' * 40;
      expect(snippetAround(text, '梅子'), text);
      expect(snippetAround(text, ''), text);
    });

    test('case-insensitive', () {
      final text = '${'a' * 30}PLUM';
      expect(snippetAround(text, 'plum', lead: 2), '…aaPLUM');
    });
  });
}
