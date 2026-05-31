// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/strings/app_strings.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:dayz/ui/timeline/timeline_controller.dart';
import 'package:dayz/ui/timeline/timeline_month_section.dart';
import 'package:dayz/ui/timeline/timeline_page.dart';
import 'package:dayz/ui/widgets/dayz_favorite_star.dart';

import 'fake_entry_repo.dart';

void main() {
  group('TimelinePage card + header presentation', () {
    testWidgets('month header adds shadow only after content overlaps', (
      tester,
    ) async {
      final section = MonthSection(
        year: 2026,
        month: 6,
        count: 3,
        entries: <TimelineEntry>[],
      );
      final delegate = TimelineMonthHeaderDelegate(
        section: section,
        headerKey: GlobalKey(),
      );

      await tester.pumpWidget(
        _DelegateHarness(
          child: Builder(
            builder: (context) => delegate.build(context, 0, false),
          ),
        ),
      );

      expect(_allBoxShadows(tester), isEmpty);

      await tester.pumpWidget(
        _DelegateHarness(
          child: Builder(
            builder: (context) => delegate.build(context, 0, true),
          ),
        ),
      );

      expect(_allBoxShadows(tester), isNotEmpty);
    });

    testWidgets(
      'cards format dates, hide non-favorite stars, and navigate with entryId',
      (tester) async {
        await initializeDateFormatting('en');

        final controller = TimelineController(
          repo: FakeEntryRepo(
            entries: [
              fakeEntry(
                id: 'fav-1',
                journalId: 'journal-a',
                entryDtUtc: DateTime.utc(2026, 6, 2, 9),
                contentPlain: 'Favorite entry\nRain stopped',
                isFavorite: true,
              ),
              fakeEntry(
                id: 'plain-1',
                journalId: 'journal-a',
                entryDtUtc: DateTime.utc(2026, 6, 1, 8),
                contentPlain: 'Plain entry\nQuiet morning',
                isFavorite: false,
              ),
            ],
          ),
          pageSize: 12,
        );
        await controller.loadInitial('journal-a');

        await tester.pumpWidget(
          _RouterHarness(controller: controller, locale: const Locale('en')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Jun'), findsOneWidget);
        expect(find.text('2026 · ${AppStrings.entryCount(2)}'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(
          find.text(
            DateFormat.MMM('en').format(DateTime(2026, 6, 2)).toUpperCase(),
          ),
          findsNWidgets(2),
        );
        expect(
          find.text(DateFormat.E('en').format(DateTime(2026, 6, 2))),
          findsOneWidget,
        );

        expect(
          find.descendant(
            of: find.byKey(timelineEntryCardTestKey('fav-1')),
            matching: find.byType(DayzFavoriteStar),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(timelineEntryCardTestKey('plain-1')),
            matching: find.byType(DayzFavoriteStar),
          ),
          findsNothing,
        );

        await tester.tap(find.text('Plain entry'));
        await tester.pumpAndSettle();

        expect(find.text('reader:plain-1'), findsOneWidget);
      },
    );
  });
}

class _RouterHarness extends StatelessWidget {
  const _RouterHarness({required this.controller, this.locale});

  final TimelineController controller;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/timeline',
      routes: [
        GoRoute(
          name: Routes.timeline,
          path: '/timeline',
          builder: (context, state) =>
              Scaffold(body: TimelinePage(controller: controller)),
        ),
        GoRoute(
          name: Routes.reader,
          path: '/reader',
          builder: (context, state) => Scaffold(
            body: Text('reader:${state.extra as String? ?? 'missing'}'),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      theme: DayzThemes.purpleLight,
      locale: locale,
    );
  }
}

class _DelegateHarness extends StatelessWidget {
  const _DelegateHarness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: DayzThemes.purpleLight,
      home: Scaffold(body: child),
    );
  }
}

List<BoxShadow> _allBoxShadows(WidgetTester tester) {
  final decorations = tester.widgetList<DecoratedBox>(
    find.byType(DecoratedBox),
  );

  return [
    for (final box in decorations)
      ...((box.decoration as BoxDecoration).boxShadow ?? const <BoxShadow>[]),
  ];
}
