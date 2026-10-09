// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/reader/reader_body.dart';
import 'package:dayz/ui/theme/dayz_fonts.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _paragraphs = [
  '雨后的路面反着光。',
  '我绕过巷口的花店，想起昨天没写完的那一页。',
  '夜里风很轻，窗外只有车灯慢慢划过去。',
];

/// Widget tests for [ReaderBody].
///
/// Author: @Ray
void main() {
  testWidgets('renders one diary text per paragraph', (tester) async {
    await tester.pumpWidget(_ReaderBodyHarness(paragraphs: _paragraphs));

    for (final paragraph in _paragraphs) {
      expect(find.text(paragraph), findsOneWidget);
    }
    expect(_paragraphTexts(), findsNWidgets(_paragraphs.length));
  });

  testWidgets('uses the .t-diary text style for paragraphs', (tester) async {
    await tester.pumpWidget(_ReaderBodyHarness(paragraphs: _paragraphs));

    final text = tester.widget<Text>(find.text(_paragraphs.first));
    final style = text.style!;

    expect(style.height, 1.8);
    expect(style.leadingDistribution, TextLeadingDistribution.even);
    expect(style.fontFamily, DayzFonts.serif);
    expect(style.fontFamilyFallback, DayzFonts.serifFallback);
  });

  testWidgets('bodyBuilder replaces the default paragraph body', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ReaderBodyHarness(
        paragraphs: _paragraphs,
        bodyBuilder: (context, receivedParagraphs) {
          return Text(
            'custom:${receivedParagraphs.length}',
            style: context.dayzText.diary,
          );
        },
      ),
    );

    expect(find.text('custom:3'), findsOneWidget);
    for (final paragraph in _paragraphs) {
      expect(find.text(paragraph), findsNothing);
    }
  });
}

Finder _paragraphTexts() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        _paragraphs.contains(widget.data) &&
        widget.style?.height == 1.8,
  );
}

class _ReaderBodyHarness extends StatelessWidget {
  const _ReaderBodyHarness({required this.paragraphs, this.bodyBuilder});

  final List<String> paragraphs;
  final Widget Function(BuildContext, List<String>)? bodyBuilder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: DayzThemes.purpleLight,
      home: Scaffold(
        body: ReaderBody(paragraphs: paragraphs, bodyBuilder: bodyBuilder),
      ),
    );
  }
}
