// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';
import 'package:dayz/ui/timeline/timeline_controller.dart';
import 'package:dayz/ui/timeline/timeline_month_section.dart';
import 'package:dayz/ui/timeline/timeline_page.dart';

import 'fake_entry_repo.dart';

void main() {
  group('Timeline calendar panel', () {
    testWidgets('opens from month header and closes via same header or scrim', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      final controller = await _buildController(pageSize: 2);

      await tester.pumpWidget(_Harness(controller: controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(timelineMonthHeaderTestKey(2026, 6)));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('timeline-calendar-panel')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(timelineMonthHeaderTestKey(2026, 6)));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('timeline-calendar-panel')),
        findsNothing,
      );

      await tester.tap(find.byKey(timelineMonthHeaderTestKey(2026, 6)));
      await tester.pumpAndSettle();
      final scrimRect = tester.getRect(
        find.byKey(const ValueKey<String>('timeline-calendar-scrim')),
      );
      await tester.tapAt(Offset(scrimRect.left + 12, scrimRect.bottom - 12));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('timeline-calendar-panel')),
        findsNothing,
      );

      semantics.dispose();
    });

    testWidgets('selecting a far month loads it and exposes dialog semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      final controller = await _buildController(pageSize: 2);

      await tester.pumpWidget(_Harness(controller: controller));
      await tester.pumpAndSettle();

      expect(find.byKey(timelineMonthHeaderTestKey(2026, 5)), findsNothing);

      await tester.tap(find.byKey(timelineMonthHeaderTestKey(2026, 6)));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(testL10n.jumpToDate), findsOneWidget);

      final mayButton = find.byKey(
        const ValueKey<String>('timeline-calendar-month-2026-5'),
      );
      final mayRect = tester.getRect(mayButton);
      expect(mayRect.width, greaterThanOrEqualTo(44));
      expect(mayRect.height, greaterThanOrEqualTo(44));

      await tester.tap(mayButton);
      await tester.pump();
      await tester.pumpAndSettle();

      final mayHeader = find.byKey(timelineMonthHeaderTestKey(2026, 5));
      expect(mayHeader, findsOneWidget);
      final mayHeaderRect = tester.getRect(mayHeader);
      expect(
        mayHeaderRect.top,
        moreOrLessEquals(kToolbarHeight, epsilon: 1),
      );

      semantics.dispose();
    });

    testWidgets(
      'uses zero-duration panel motion when animations are disabled',
      (tester) async {
        final controller = await _buildController(pageSize: 2);

        await tester.pumpWidget(
          _Harness(controller: controller, disableAnimations: true),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(timelineMonthHeaderTestKey(2026, 6)));
        await tester.pump();

        final slide = tester.widget<AnimatedSlide>(
          find.byKey(const ValueKey<String>('timeline-calendar-slide')),
        );
        expect(slide.duration, Duration.zero);
      },
    );
  });
}

class _Harness extends StatelessWidget {
  const _Harness({required this.controller, this.disableAnimations = false});

  final TimelineController controller;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    return localizedMaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 390,
          height: 360,
          child: MediaQuery(
            data: MediaQueryData(
              size: const Size(390, 360),
              disableAnimations: disableAnimations,
            ),
            child: Scaffold(body: TimelinePage(controller: controller)),
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
