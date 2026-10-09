// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';
import 'package:dayz/ui/shell/dayz_glass_app_bar.dart';
import 'package:dayz/ui/timeline/timeline_controller.dart';
import 'package:dayz/ui/timeline/timeline_month_section.dart';
import 'package:dayz/ui/timeline/timeline_page.dart';

import 'fake_entry_repo.dart';

void main() {
  group('TimelinePage skeleton', () {
    testWidgets('renders app bar, month sections, and loader in sliver order', (
      tester,
    ) async {
      final controller = await _buildController(pageSize: 12);

      await tester.pumpWidget(_TimelineHarness(controller: controller));

      final scrollView = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView),
      );
      expect(scrollView.slivers, hasLength(5));
      expect(scrollView.slivers.first, isA<DayzGlassAppBar>());
      expect(scrollView.slivers.last, isA<SliverToBoxAdapter>());
      expect(scrollView.slivers[1], isA<SliverMainAxisGroup>());
      expect(scrollView.slivers[2], isA<SliverMainAxisGroup>());
      expect(scrollView.slivers[3], isA<SliverMainAxisGroup>());

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -320));
      await tester.pumpAndSettle();

      final titleRect = tester.getRect(
        find.byKey(const ValueKey<String>('timeline-page-title')),
      );
      expect(titleRect.top, lessThan(80));
    });

    testWidgets('keeps cards between their month header and the next header', (
      tester,
    ) async {
      final controller = await _buildController(pageSize: 12);

      await tester.pumpWidget(_TimelineHarness(controller: controller));

      final juneHeader = tester.getRect(
        find.byKey(timelineMonthHeaderTestKey(2026, 6)),
      );
      final juneCard = tester.getRect(
        find.byKey(timelineEntryCardTestKey('june-2')),
      );
      final mayHeader = tester.getRect(
        find.byKey(timelineMonthHeaderTestKey(2026, 5)),
      );

      expect(juneHeader.top, lessThan(juneCard.top));
      expect(juneCard.top, lessThan(mayHeader.top));
    });

    testWidgets('pins at most one month header directly under the app bar', (
      tester,
    ) async {
      final controller = await _buildController(pageSize: 12);

      await tester.pumpWidget(_TimelineHarness(controller: controller));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
      await tester.pumpAndSettle();

      final visibleHeaderRects = [
        find.byKey(timelineMonthHeaderTestKey(2026, 6)),
        find.byKey(timelineMonthHeaderTestKey(2026, 5)),
        find.byKey(timelineMonthHeaderTestKey(2026, 4)),
      ]
          .where((finder) => finder.evaluate().isNotEmpty)
          .map(tester.getRect)
          .where((rect) => rect.bottom > 0)
          .toList(growable: false);

      final minVisibleTop = visibleHeaderRects
          .map((rect) => rect.top)
          .reduce(math.min);
      final topmostCount = visibleHeaderRects
          .where((rect) => (rect.top - minVisibleTop).abs() <= 1)
          .length;

      expect(minVisibleTop, lessThan(90));
      expect(topmostCount, 1);
    });
  });
}

class _TimelineHarness extends StatelessWidget {
  const _TimelineHarness({required this.controller});

  final TimelineController controller;

  @override
  Widget build(BuildContext context) {
    return localizedTestApp(child: TimelinePage(controller: controller));
  }
}

Future<TimelineController> _buildController({required int pageSize}) async {
  final controller = TimelineController(
    repo: FakeEntryRepo(
      entries: [
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
