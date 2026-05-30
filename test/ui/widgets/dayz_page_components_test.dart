// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/strings/app_strings.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:dayz/ui/widgets/dayz_empty_state.dart';
import 'package:dayz/ui/widgets/dayz_month_header.dart';
import 'package:dayz/ui/widgets/dayz_search_field.dart';
import 'package:dayz/ui/widgets/dayz_set_row.dart';
import 'package:dayz/ui/widgets/dayz_year_separator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Widget tests for page-level DayZ components.
///
/// Author: @Ray
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: DayzThemes.purpleLight,
      home: Scaffold(body: child),
    );
  }

  testWidgets('month header formats month/count and handles tap/icon state', (
    tester,
  ) async {
    var taps = 0;
    const locale = 'en_US';
    final month = DateTime(2026, 5);
    final count = 1234;
    final monthText = DateFormat.MMM(locale).format(month);
    final countText = AppStrings.entryCount(count).replaceFirst(
      count.toString(),
      NumberFormat.decimalPattern(locale).format(count),
    );
    final metaText = '${DateFormat.y(locale).format(month)} · $countText';

    await tester.pumpWidget(
      wrap(
        DayzMonthHeader(
          month: month,
          entryCount: count,
          locale: locale,
          onTap: () => taps += 1,
        ),
      ),
    );

    expect(find.text(monthText), findsOneWidget);
    expect(find.text(metaText), findsOneWidget);
    expect(
      tester
          .widget<AnimatedScale>(find.byKey(DayzMonthHeader.calendarIconKey))
          .scale,
      1,
    );
    expect(
      tester.getSize(find.byType(DayzMonthHeader)).height,
      greaterThanOrEqualTo(44),
    );

    await tester.tap(find.byType(DayzMonthHeader));
    await tester.pump();

    expect(taps, 1);

    await tester.pumpWidget(
      wrap(
        DayzMonthHeader(
          month: month,
          entryCount: count,
          expanded: true,
          locale: locale,
        ),
      ),
    );

    expect(
      tester
          .widget<AnimatedScale>(find.byKey(DayzMonthHeader.calendarIconKey))
          .scale,
      0.92,
    );
  });

  testWidgets('year separator renders year, relative text, and divider', (
    tester,
  ) async {
    const locale = 'en_US';
    const year = 2024;
    final expectedYear = DateFormat.y(locale).format(DateTime(year));
    final yearsAgo = 2;
    final expectedAgo = AppStrings.yearsAgo(yearsAgo).replaceFirst(
      yearsAgo.toString(),
      NumberFormat.decimalPattern(locale).format(yearsAgo),
    );

    await tester.pumpWidget(
      wrap(
        DayzYearSeparator(
          year: year,
          referenceDate: DateTime(2026, 5, 1),
          locale: locale,
        ),
      ),
    );

    expect(find.text(expectedYear), findsOneWidget);
    expect(find.text(expectedAgo), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('dayz-year-separator-line')),
      findsOneWidget,
    );
  });

  testWidgets('set row supports value, chevron, switch, and 44px hit target', (
    tester,
  ) async {
    var taps = 0;
    bool? switchValue;

    await tester.pumpWidget(
      wrap(
        Column(
          children: [
            DayzSetRow(
              icon: const Icon(Icons.palette_outlined),
              title: 'Theme',
              subtitle: 'Accent',
              value: 'Purple',
              showChevron: true,
              onTap: () => taps += 1,
            ),
            DayzSetRow(
              icon: const Icon(Icons.notifications_outlined),
              title: 'Reminder',
              switchValue: true,
              onSwitchChanged: (value) => switchValue = value,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Accent'), findsOneWidget);
    expect(find.text('Purple'), findsOneWidget);
    expect(find.byKey(DayzSetRow.chevronKey), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    final rows = find.byType(DayzSetRow);
    expect(tester.getSize(rows.first).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(rows.last).height, greaterThanOrEqualTo(44));

    await tester.tap(rows.first);
    await tester.pump();
    expect(taps, 1);

    await tester.tap(rows.last);
    await tester.pump();
    expect(switchValue, false);
  });

  testWidgets('empty state renders illustration and AppStrings copy', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const DayzEmptyState()));

    expect(find.byKey(DayzEmptyState.illustrationKey), findsOneWidget);
    expect(find.text(AppStrings.emptyTitle), findsOneWidget);
    expect(find.text(AppStrings.emptyDescription), findsOneWidget);
  });

  testWidgets('search field handles typing, clear, and cancel callbacks', (
    tester,
  ) async {
    final controller = TextEditingController();
    final changes = <String>[];
    var clears = 0;
    var cancels = 0;

    await tester.pumpWidget(
      wrap(
        DayzSearchField(
          controller: controller,
          onChanged: changes.add,
          onClear: () => clears += 1,
          onCancel: () => cancels += 1,
        ),
      ),
    );

    expect(find.text(AppStrings.search), findsOneWidget);
    expect(find.text(AppStrings.cancel), findsOneWidget);

    await tester.enterText(find.byKey(DayzSearchField.inputKey), 'plum');
    await tester.pump();

    expect(changes, contains('plum'));
    expect(find.byKey(DayzSearchField.clearButtonKey), findsOneWidget);

    await tester.tap(find.byKey(DayzSearchField.clearButtonKey));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(changes.last, '');
    expect(clears, 1);

    await tester.tap(find.byKey(DayzSearchField.cancelButtonKey));
    await tester.pump();

    expect(cancels, 1);

    controller.dispose();
  });
}
