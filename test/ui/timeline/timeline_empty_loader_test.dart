// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/ui/strings/app_strings.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:dayz/ui/timeline/timeline_controller.dart';
import 'package:dayz/ui/timeline/timeline_month_section.dart';
import 'package:dayz/ui/timeline/timeline_page.dart';
import 'package:dayz/ui/widgets/dayz_empty_state.dart';

import 'fake_entry_repo.dart';

void main() {
  group('TimelinePage empty + loader states', () {
    testWidgets('renders only empty state for an empty journal', (
      tester,
    ) async {
      final controller = TimelineController(
        repo: FakeEntryRepo(entries: const []),
        pageSize: 12,
      );
      await controller.loadInitial('journal-a');

      await tester.pumpWidget(_Harness(controller: controller));

      expect(find.byType(DayzEmptyState), findsOneWidget);
      expect(find.text(AppStrings.timelineEmptyTitle), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('timeline-loader')),
        findsNothing,
      );
      expect(find.byKey(timelineMonthHeaderTestKey(2026, 6)), findsNothing);
    });

    testWidgets('shows loadingEarlier while a page load is in flight', (
      tester,
    ) async {
      final gate = Completer<void>();
      final controller = TimelineController(
        repo: FakeEntryRepo(
          entries: [
            fakeEntry(
              id: 'entry-1',
              journalId: 'journal-a',
              entryDtUtc: DateTime.utc(2026, 6, 1, 10),
            ),
          ],
        )..beforeTimelineResponse = () => gate.future,
        pageSize: 1,
      );

      final initialLoad = controller.loadInitial('journal-a');
      await tester.pumpWidget(_Harness(controller: controller));

      expect(
        find.byKey(const ValueKey<String>('timeline-loader')),
        findsOneWidget,
      );
      expect(find.text(AppStrings.loadingEarlier), findsOneWidget);

      gate.complete();
      await initialLoad;
    });

    testWidgets('shows reachedOldest after the last page is loaded', (
      tester,
    ) async {
      final controller = TimelineController(
        repo: FakeEntryRepo(
          entries: [
            fakeEntry(
              id: 'entry-1',
              journalId: 'journal-a',
              entryDtUtc: DateTime.utc(2026, 6, 1, 10),
            ),
          ],
        ),
        pageSize: 1,
      );
      await controller.loadInitial('journal-a');

      await tester.pumpWidget(_Harness(controller: controller));

      expect(find.text(AppStrings.reachedOldest), findsOneWidget);
    });

    testWidgets('switchJournal fades content and respects disableAnimations', (
      tester,
    ) async {
      final controller = TimelineController(
        repo: FakeEntryRepo(
          entries: [
            fakeEntry(
              id: 'a-1',
              journalId: 'journal-a',
              entryDtUtc: DateTime.utc(2026, 6, 1, 10),
            ),
            fakeEntry(
              id: 'b-1',
              journalId: 'journal-b',
              entryDtUtc: DateTime.utc(2026, 5, 1, 10),
            ),
          ],
        ),
        pageSize: 12,
      );
      await controller.loadInitial('journal-a');

      await tester.pumpWidget(
        _Harness(controller: controller, disableAnimations: false),
      );

      await controller.switchJournal('journal-b');
      await tester.pump();

      final switcherFinder = find.byKey(
        const ValueKey<String>('timeline-content-switcher'),
      );
      expect(switcherFinder, findsOneWidget);
      expect(
        tester.widget<AnimatedSwitcher>(switcherFinder).duration,
        isNot(Duration.zero),
      );

      await tester.pumpWidget(
        _Harness(controller: controller, disableAnimations: true),
      );
      await tester.pump();

      expect(
        tester.widget<AnimatedSwitcher>(switcherFinder).duration,
        Duration.zero,
      );
    });
  });
}

class _Harness extends StatelessWidget {
  const _Harness({required this.controller, this.disableAnimations = false});

  final TimelineController controller;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: DayzThemes.purpleLight,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: TimelinePage(controller: controller)),
      ),
    );
  }
}
