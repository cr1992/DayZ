// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../../l10n/localized_test_app.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:dayz/ui/timeline/timeline_calendar_panel.dart';
import 'package:dayz/ui/timeline/timeline_controller.dart';
import 'package:dayz/ui/timeline/timeline_month_section.dart';
import 'package:dayz/ui/timeline/timeline_page.dart';

import 'fake_entry_repo.dart';

const _panel = ValueKey<String>('timeline-calendar-panel');
const _scrim = ValueKey<String>('timeline-calendar-scrim');
const _motion = ValueKey<String>('timeline-calendar-motion');
const _dot = ValueKey<String>('timeline-calendar-day-dot');

void main() {
  group('Timeline calendar panel · page wiring', () {
    testWidgets('opens from month header and closes via same header or scrim', (
      tester,
    ) async {
      final controller = await _buildController(pageSize: 2);

      await tester.pumpWidget(_Harness(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(timelineMonthHeaderTestKey(2026, 6)));
      await tester.pumpAndSettle();
      expect(find.byKey(_panel), findsOneWidget);

      // 面板落在吸顶月份头正下方，月份头仍可点。
      final headerRect = tester.getRect(
        find.byKey(timelineMonthHeaderTestKey(2026, 6)),
      );
      final panelRect = tester.getRect(find.byKey(_panel));
      expect(panelRect.top, moreOrLessEquals(headerRect.bottom, epsilon: 1));

      await tester.tap(find.byKey(timelineMonthHeaderTestKey(2026, 6)));
      await tester.pumpAndSettle();
      expect(find.byKey(_panel), findsNothing);

      await tester.tap(find.byKey(timelineMonthHeaderTestKey(2026, 6)));
      await tester.pumpAndSettle();
      final scrimRect = tester.getRect(find.byKey(_scrim));
      // 360 高的测试视口里面板盖住了底部，从面板两侧 `--sp-3` 槽里点 scrim。
      await tester.tapAt(Offset(scrimRect.left + 4, scrimRect.bottom - 12));
      await tester.pumpAndSettle();
      expect(find.byKey(_panel), findsNothing);
    });

    testWidgets('opens on the tapped month in month view', (tester) async {
      final controller = await _buildController(pageSize: 2);

      await tester.pumpWidget(_Harness(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(timelineMonthHeaderTestKey(2026, 6)));
      await tester.pumpAndSettle();

      expect(find.text(_monthTitle(2026, 6)), findsOneWidget);
      // 已加载的 6 月有条目日带圆点：8/18/22/28/29/30 共 6 天。
      expect(
        find.descendant(of: find.byKey(_panel), matching: find.byKey(_dot)),
        findsNWidgets(6),
      );
    });

    testWidgets(
      'selecting a far unloaded month loads it and docks its header under the app bar',
      (tester) async {
        final controller = await _buildController(pageSize: 2);

        await tester.pumpWidget(_Harness(controller: controller));
        await tester.pumpAndSettle();

        expect(find.byKey(timelineMonthHeaderTestKey(2026, 5)), findsNothing);
        expect(
          controller.sections.any((s) => s.year == 2026 && s.month == 5),
          isFalse,
        );

        await tester.tap(find.byKey(timelineMonthHeaderTestKey(2026, 6)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(TimelineCalendarPanel.titleKey));
        await tester.pumpAndSettle();

        final mayButton = find.byKey(
          timelineCalendarMonthButtonTestKey(2026, 5),
        );
        final mayRect = tester.getRect(mayButton);
        expect(mayRect.width, greaterThanOrEqualTo(44));
        expect(mayRect.height, greaterThanOrEqualTo(44));

        await tester.tap(mayButton);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byKey(_panel), findsNothing);
        expect(
          controller.sections.any((s) => s.year == 2026 && s.month == 5),
          isTrue,
        );
        final mayHeader = find.byKey(timelineMonthHeaderTestKey(2026, 5));
        expect(mayHeader, findsOneWidget);
        expect(
          tester.getRect(mayHeader).top,
          moreOrLessEquals(kToolbarHeight, epsilon: 1),
        );
      },
    );

    testWidgets(
      'without its own app bar (shell owns it) the panel and docking use the page top',
      (tester) async {
        final controller = await _buildController(pageSize: 2);

        await tester.pumpWidget(
          _Harness(controller: controller, showAppBar: false),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(timelineMonthHeaderTestKey(2026, 6)));
        await tester.pumpAndSettle();
        final headerRect = tester.getRect(
          find.byKey(timelineMonthHeaderTestKey(2026, 6)),
        );
        expect(
          tester.getRect(find.byKey(_panel)).top,
          moreOrLessEquals(headerRect.bottom, epsilon: 1),
        );

        await tester.tap(find.byKey(TimelineCalendarPanel.titleKey));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(timelineCalendarMonthButtonTestKey(2026, 5)),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          tester.getRect(find.byKey(timelineMonthHeaderTestKey(2026, 5))).top,
          moreOrLessEquals(0, epsilon: 1),
        );
      },
    );

    testWidgets('exposes dialog semantics labelled jump-to-date', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = await _buildController(pageSize: 2);

      await tester.pumpWidget(_Harness(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(timelineMonthHeaderTestKey(2026, 6)));
      await tester.pumpAndSettle();

      final dialog = find.bySemanticsLabel(testL10n.jumpToDate);
      expect(dialog, findsOneWidget);
      expect(tester.getSemantics(dialog).role, SemanticsRole.dialog);
      expect(find.bySemanticsLabel(testL10n.backToToday), findsOneWidget);
      expect(
        find.bySemanticsLabel(testL10n.calendarPreviousMonth),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(testL10n.calendarNextMonth), findsOneWidget);

      semantics.dispose();
    });

    testWidgets('switching journal while open closes the panel', (
      tester,
    ) async {
      final controller = await _buildController(pageSize: 2);

      await tester.pumpWidget(_Harness(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(timelineMonthHeaderTestKey(2026, 6)));
      await tester.pumpAndSettle();
      expect(find.byKey(_panel), findsOneWidget);

      await controller.switchJournal('journal-b');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(_panel), findsNothing);
    });

    testWidgets('back-to-today closes the panel', (tester) async {
      final controller = await _buildController(pageSize: 2);

      // 月视图面板约 410 高，用接近真机的视口高度让底栏按钮可见。
      await tester.pumpWidget(_Harness(controller: controller, height: 760));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(timelineMonthHeaderTestKey(2026, 6)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(TimelineCalendarPanel.todayKey));
      await tester.pumpAndSettle();
      expect(find.byKey(_panel), findsNothing);
    });

    testWidgets('panel drops in over the motion duration', (tester) async {
      final controller = await _buildController(pageSize: 2);

      await tester.pumpWidget(_Harness(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(timelineMonthHeaderTestKey(2026, 6)));
      await tester.pump();
      expect(_panelOpacity(tester), 0);
      final startTop = tester.getRect(find.byKey(_panel)).top;

      await tester.pump(const Duration(milliseconds: 80));
      final midOpacity = _panelOpacity(tester);
      expect(midOpacity, greaterThan(0));
      expect(midOpacity, lessThan(1));

      await tester.pumpAndSettle();
      expect(_panelOpacity(tester), 1);
      // 自上而下落：起始在终点上方（`translateY(-10px)`）。
      expect(tester.getRect(find.byKey(_panel)).top - startTop, greaterThan(5));
    });

    testWidgets('disableAnimations makes the panel drop instantly', (
      tester,
    ) async {
      final controller = await _buildController(pageSize: 2);

      await tester.pumpWidget(
        _Harness(controller: controller, disableAnimations: true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(timelineMonthHeaderTestKey(2026, 6)));
      await tester.pump();
      expect(_panelOpacity(tester), 1);

      // 收起同样瞬时：不推进时钟，下一帧面板即移除。
      await tester.tap(find.byKey(timelineMonthHeaderTestKey(2026, 6)));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(_panel), findsNothing);
    });
  });

  group('Timeline calendar panel · month / year views', () {
    final today = DateTime(2026, 5, 12);
    final colors = DayzThemes.purpleLight.extension<DayzColors>()!;

    Future<List<TimelineMonthKey>> pumpPanel(
      WidgetTester tester, {
      List<int>? todayTaps,
    }) async {
      final picks = <TimelineMonthKey>[];
      await tester.pumpWidget(
        localizedTestApp(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              // 390 宽屏 − 两侧 `--sp-3`。
              width: 366,
              child: TimelineCalendarPanel(
                months: const [
                  TimelineMonthKey(2026, 6),
                  TimelineMonthKey(2026, 5),
                  TimelineMonthKey(2025, 12),
                ],
                selectedMonth: const TimelineMonthKey(2026, 5),
                today: today,
                monthCountFor: (key) => switch ((key.year, key.month)) {
                  (2026, 6) => 6,
                  (2026, 5) => 4,
                  (2025, 12) => 2,
                  _ => null,
                },
                entryDaysFor: (key) async =>
                    key == const TimelineMonthKey(2026, 5)
                    ? <int>{12, 22, 26}
                    : <int>{},
                onMonthSelected: picks.add,
                onToday: () => todayTaps?.add(1),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return picks;
    }

    Finder day(int y, int m, int d) =>
        find.byKey(timelineCalendarDayTestKey(y, m, d));
    Finder month(int y, int m) =>
        find.byKey(timelineCalendarMonthButtonTestKey(y, m));

    testWidgets(
      'month view lays out Monday-first with pad, has and today states',
      (tester) async {
        await pumpPanel(tester);

        // 2026-05-01 是周五：前置 4 个 pad；5/4（周一）落第二行第一列。
        final day1 = tester.getRect(day(2026, 5, 1));
        final day4 = tester.getRect(day(2026, 5, 4));
        final day5 = tester.getRect(day(2026, 5, 5));
        final step = day5.left - day4.left;
        expect(day1.left - day4.left, moreOrLessEquals(step * 4, epsilon: 0.5));
        expect(day4.top, greaterThan(day1.top));

        // `.has`：有条目日带 4×4 圆点；今天 12 号同时 has → accent-strong。
        Finder dotOf(int d) =>
            find.descendant(of: day(2026, 5, d), matching: find.byKey(_dot));
        expect(dotOf(22), findsOneWidget);
        expect(dotOf(26), findsOneWidget);
        expect(dotOf(9), findsNothing);
        expect(tester.getSize(dotOf(22)), const Size(4, 4));
        BoxDecoration dotDecoration(int d) =>
            tester.widget<Container>(dotOf(d)).decoration! as BoxDecoration;
        expect(dotDecoration(22).color, colors.accent);
        expect(dotDecoration(12).color, colors.accentStrong);

        // `.today`：1.5px accent-ring 内描边；非今天无描边。
        BoxDecoration cellDecoration(int d) =>
            tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: day(2026, 5, d),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        final todayBorder = cellDecoration(12).border! as Border;
        expect(todayBorder.top.color, colors.accentRing);
        expect(todayBorder.top.width, 1.5);
        expect(cellDecoration(22).border, isNull);

        // 日格文字：无条目 ink-4、有条目 ink、今天 accent-ink。
        Color dayColor(int d) => tester
            .widget<Text>(
              find.descendant(of: day(2026, 5, d), matching: find.text('$d')),
            )
            .style!
            .color!;
        expect(dayColor(9), colors.ink4);
        expect(dayColor(22), colors.ink);
        expect(dayColor(12), colors.accentInk);
      },
    );

    testWidgets('day cells, month cells and controls are at least 44x44', (
      tester,
    ) async {
      await pumpPanel(tester);

      for (final finder in [
        day(2026, 5, 22),
        day(2026, 5, 9),
        find.byKey(TimelineCalendarPanel.previousKey),
        find.byKey(TimelineCalendarPanel.nextKey),
        find.byKey(TimelineCalendarPanel.titleKey),
        find.byKey(TimelineCalendarPanel.todayKey),
      ]) {
        final size = tester.getSize(finder);
        expect(size.width, greaterThanOrEqualTo(44), reason: '$finder');
        expect(size.height, greaterThanOrEqualTo(44), reason: '$finder');
      }

      await tester.tap(find.byKey(TimelineCalendarPanel.titleKey));
      await tester.pumpAndSettle();
      for (var m = 1; m <= 12; m++) {
        final size = tester.getSize(month(2026, m));
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      }
    });

    testWidgets(
      'only days with entries are selectable and report their month',
      (tester) async {
        final picks = await pumpPanel(tester);

        await tester.tap(day(2026, 5, 9));
        await tester.pump();
        expect(picks, isEmpty);

        await tester.tap(day(2026, 5, 22));
        await tester.pump();
        expect(picks, [const TimelineMonthKey(2026, 5)]);
      },
    );

    testWidgets('nav arrows page months; title toggles the year view', (
      tester,
    ) async {
      final picks = await pumpPanel(tester);

      expect(find.text(_monthTitle(2026, 5)), findsOneWidget);
      await tester.tap(find.byKey(TimelineCalendarPanel.nextKey));
      await tester.pumpAndSettle();
      expect(find.text(_monthTitle(2026, 6)), findsOneWidget);
      await tester.tap(find.byKey(TimelineCalendarPanel.previousKey));
      await tester.tap(find.byKey(TimelineCalendarPanel.previousKey));
      await tester.pumpAndSettle();
      expect(find.text(_monthTitle(2026, 4)), findsOneWidget);

      // 年视图：3 列 12 个月格，有条目月显示篇数、其余「—」，今天所在月 `.cur`。
      await tester.tap(find.byKey(TimelineCalendarPanel.titleKey));
      await tester.pumpAndSettle();
      expect(find.text(_yearTitle(2026)), findsOneWidget);
      expect(day(2026, 4, 1), findsNothing);
      final jan = tester.getRect(month(2026, 1));
      final apr = tester.getRect(month(2026, 4));
      expect(apr.left, moreOrLessEquals(jan.left, epsilon: 0.5));
      expect(apr.top, greaterThan(jan.top));
      expect(
        find.descendant(
          of: month(2026, 6),
          matching: find.text(testL10n.entryCount(6)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: month(2026, 3),
          matching: find.text(testL10n.calendarMonthNoEntries),
        ),
        findsOneWidget,
      );
      BorderSide sideOf(int m) =>
          (tester
                      .widget<Material>(
                        find
                            .descendant(
                              of: month(2026, m),
                              matching: find.byType(Material),
                            )
                            .first,
                      )
                      .shape!
                  as RoundedRectangleBorder)
              .side;
      expect(sideOf(5).color, colors.accent);
      expect(sideOf(6).color, Colors.transparent);

      // 年视图翻年；无条目月不可点，有条目月回传该月。
      await tester.tap(find.byKey(TimelineCalendarPanel.previousKey));
      await tester.pumpAndSettle();
      expect(find.text(_yearTitle(2025)), findsOneWidget);
      await tester.tap(month(2025, 11));
      await tester.pump();
      expect(picks, isEmpty);
      await tester.tap(month(2025, 12));
      await tester.pump();
      expect(picks, [const TimelineMonthKey(2025, 12)]);

      // 再点标题回月视图。
      await tester.tap(find.byKey(TimelineCalendarPanel.titleKey));
      await tester.pumpAndSettle();
      expect(find.text(_monthTitle(2025, 4)), findsOneWidget);
    });

    testWidgets('back-to-today button fires onToday', (tester) async {
      final taps = <int>[];
      await pumpPanel(tester, todayTaps: taps);

      expect(find.text(testL10n.backToToday), findsOneWidget);
      await tester.tap(find.byKey(TimelineCalendarPanel.todayKey));
      await tester.pump();
      expect(taps, [1]);
    });
  });
}

String _monthTitle(int year, int month) =>
    DateFormat.yMMMM('zh').format(DateTime(year, month));

String _yearTitle(int year) => DateFormat.y('zh').format(DateTime(year));

double _panelOpacity(WidgetTester tester) {
  return tester
      .widget<Opacity>(
        find
            .descendant(of: find.byKey(_motion), matching: find.byType(Opacity))
            .first,
      )
      .opacity;
}

class _Harness extends StatelessWidget {
  const _Harness({
    required this.controller,
    this.disableAnimations = false,
    this.height = 360,
    this.showAppBar = true,
  });

  final TimelineController controller;
  final bool disableAnimations;
  final double height;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return localizedMaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 390,
          height: height,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(390, height),
              disableAnimations: disableAnimations,
            ),
            child: Scaffold(
              body: TimelinePage(
                controller: controller,
                showAppBar: showAppBar,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<TimelineController> _buildController({required int pageSize}) async {
  final controller = TimelineController(
    repo: FakeEntryRepo(
      entries: [
        fakeEntry(
          id: 'june-6',
          journalId: 'journal-a',
          entryDtUtc: DateTime.utc(2026, 6, 30, 10),
          localYear: 2026,
          localMonth: 6,
          localDay: 30,
          contentPlain: 'June Six\nSummary',
        ),
        fakeEntry(
          id: 'june-5',
          journalId: 'journal-a',
          entryDtUtc: DateTime.utc(2026, 6, 29, 10),
          localYear: 2026,
          localMonth: 6,
          localDay: 29,
          contentPlain: 'June Five\nSummary',
        ),
        fakeEntry(
          id: 'june-4',
          journalId: 'journal-a',
          entryDtUtc: DateTime.utc(2026, 6, 28, 10),
          localYear: 2026,
          localMonth: 6,
          localDay: 28,
          contentPlain: 'June Four\nSummary',
        ),
        fakeEntry(
          id: 'june-3',
          journalId: 'journal-a',
          entryDtUtc: DateTime.utc(2026, 6, 22, 10),
          localYear: 2026,
          localMonth: 6,
          localDay: 22,
          contentPlain: 'June Three\nSummary',
        ),
        fakeEntry(
          id: 'june-2',
          journalId: 'journal-a',
          entryDtUtc: DateTime.utc(2026, 6, 18, 10),
          localYear: 2026,
          localMonth: 6,
          localDay: 18,
          contentPlain: 'June Two\nSummary',
        ),
        fakeEntry(
          id: 'june-1',
          journalId: 'journal-a',
          entryDtUtc: DateTime.utc(2026, 6, 8, 10),
          localYear: 2026,
          localMonth: 6,
          localDay: 8,
          contentPlain: 'June One\nSummary',
        ),
        fakeEntry(
          id: 'may-2',
          journalId: 'journal-a',
          entryDtUtc: DateTime.utc(2026, 5, 22, 10),
          localYear: 2026,
          localMonth: 5,
          localDay: 22,
          contentPlain: 'May Two\nSummary',
        ),
        fakeEntry(
          id: 'may-4',
          journalId: 'journal-a',
          entryDtUtc: DateTime.utc(2026, 5, 28, 10),
          localYear: 2026,
          localMonth: 5,
          localDay: 28,
          contentPlain: 'May Four\nSummary',
        ),
        fakeEntry(
          id: 'may-3',
          journalId: 'journal-a',
          entryDtUtc: DateTime.utc(2026, 5, 26, 10),
          localYear: 2026,
          localMonth: 5,
          localDay: 26,
          contentPlain: 'May Three\nSummary',
        ),
        fakeEntry(
          id: 'may-1',
          journalId: 'journal-a',
          entryDtUtc: DateTime.utc(2026, 5, 12, 10),
          localYear: 2026,
          localMonth: 5,
          localDay: 12,
          contentPlain: 'May One\nSummary',
        ),
        fakeEntry(
          id: 'april-2',
          journalId: 'journal-a',
          entryDtUtc: DateTime.utc(2026, 4, 24, 10),
          localYear: 2026,
          localMonth: 4,
          localDay: 24,
          contentPlain: 'April Two\nSummary',
        ),
        fakeEntry(
          id: 'april-6',
          journalId: 'journal-a',
          entryDtUtc: DateTime.utc(2026, 4, 28, 10),
          localYear: 2026,
          localMonth: 4,
          localDay: 28,
          contentPlain: 'April Six\nSummary',
        ),
        fakeEntry(
          id: 'april-5',
          journalId: 'journal-a',
          entryDtUtc: DateTime.utc(2026, 4, 27, 10),
          localYear: 2026,
          localMonth: 4,
          localDay: 27,
          contentPlain: 'April Five\nSummary',
        ),
        fakeEntry(
          id: 'april-4',
          journalId: 'journal-a',
          entryDtUtc: DateTime.utc(2026, 4, 26, 10),
          localYear: 2026,
          localMonth: 4,
          localDay: 26,
          contentPlain: 'April Four\nSummary',
        ),
        fakeEntry(
          id: 'april-3',
          journalId: 'journal-a',
          entryDtUtc: DateTime.utc(2026, 4, 25, 10),
          localYear: 2026,
          localMonth: 4,
          localDay: 25,
          contentPlain: 'April Three\nSummary',
        ),
        fakeEntry(
          id: 'april-1',
          journalId: 'journal-a',
          entryDtUtc: DateTime.utc(2026, 4, 4, 10),
          localYear: 2026,
          localMonth: 4,
          localDay: 4,
          contentPlain: 'April One\nSummary',
        ),
      ],
    ),
    pageSize: pageSize,
  );

  await controller.loadInitial('journal-a');
  return controller;
}
