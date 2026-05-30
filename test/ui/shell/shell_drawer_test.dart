// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/shell_drawer.dart';
import 'package:dayz/ui/strings/app_strings.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';

void main() {
  final mockJournals = [
    const JournalSummary(
      id: 'j1',
      name: 'Work Journal',
      color: '#786CAD',
      count: 12,
    ),
    const JournalSummary(
      id: 'j2',
      name: 'Life Snippets',
      color: '#C67D33',
      count: 5,
    ),
  ];

  Widget buildDrawerHost({
    List<JournalSummary> journals = const [],
    String? currentJournalId,
    int? allJournalCount,
    int? favoriteCount,
    required ValueChanged<String?> onSelectJournal,
    required ValueChanged<String> onNavigate,
    required VoidCallback onNewJournal,
  }) {
    return MaterialApp(
      theme: DayzThemes.purpleLight,
      home: Scaffold(
        drawer: ShellDrawer(
          journals: journals,
          currentJournalId: currentJournalId,
          allJournalCount: allJournalCount,
          favoriteCount: favoriteCount,
          onSelectJournal: onSelectJournal,
          onNavigate: onNavigate,
          onNewJournal: onNewJournal,
        ),
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets('renders all journals, active color dots, and entries count', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildDrawerHost(
        journals: mockJournals,
        onSelectJournal: (_) {},
        onNavigate: (_) {},
        onNewJournal: () {},
      ),
    );

    // Open drawer
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify all journals are rendered
    expect(find.text(AppStrings.drawerProfileName), findsOneWidget);
    expect(find.text(AppStrings.drawerProfileStatus), findsOneWidget);
    expect(find.text(AppStrings.browseSectionHeader), findsOneWidget);
    expect(find.text('Work Journal'), findsOneWidget);
    expect(find.text('Life Snippets'), findsOneWidget);
    expect(find.text(AppStrings.allJournals), findsOneWidget);

    // Verify entry counts are rendered
    expect(find.text(AppStrings.entryCount(17)), findsOneWidget);
    expect(find.text(AppStrings.entryCount(12)), findsOneWidget);
    expect(find.text(AppStrings.entryCount(5)), findsOneWidget);
  });

  testWidgets('renders injected all journals and favorite counts', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildDrawerHost(
        journals: mockJournals,
        allJournalCount: 218,
        favoriteCount: 19,
        onSelectJournal: (_) {},
        onNavigate: (_) {},
        onNewJournal: () {},
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.entryCount(218)), findsOneWidget);
    expect(find.text(AppStrings.entryCount(19)), findsOneWidget);
  });

  testWidgets('clicking new journal icon calls onNewJournal callback', (
    tester,
  ) async {
    var newJournalCalled = false;
    await tester.pumpWidget(
      buildDrawerHost(
        journals: mockJournals,
        onSelectJournal: (_) {},
        onNavigate: (_) {},
        onNewJournal: () => newJournalCalled = true,
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final newJournalBtn = find.bySemanticsLabel(AppStrings.newJournal);
    expect(newJournalBtn, findsOneWidget);

    await tester.tap(newJournalBtn);
    await tester.pumpAndSettle();

    expect(newJournalCalled, true);
  });

  testWidgets('clicking browse items calls onNavigate with correct route', (
    tester,
  ) async {
    String? navigatedRoute;
    await tester.pumpWidget(
      buildDrawerHost(
        journals: mockJournals,
        onSelectJournal: (_) {},
        onNavigate: (route) => navigatedRoute = route,
        onNewJournal: () {},
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Tap Favorites
    await tester.tap(find.bySemanticsLabel(AppStrings.favorites));
    await tester.pumpAndSettle();
    expect(navigatedRoute, Routes.favorites);

    // Reopen drawer because drawer items automatically pop the drawer
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Tap Trash
    await tester.tap(find.bySemanticsLabel(AppStrings.trash));
    await tester.pumpAndSettle();
    expect(navigatedRoute, Routes.trash);
  });

  testWidgets(
    'clicking journal select calls onSelectJournal and marks selected',
    (tester) async {
      String? selectedJournalId;
      var onSelectCalled = false;

      await tester.pumpWidget(
        buildDrawerHost(
          journals: mockJournals,
          currentJournalId: 'j2',
          onSelectJournal: (id) {
            selectedJournalId = id;
            onSelectCalled = true;
          },
          onNavigate: (_) {},
          onNewJournal: () {},
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify "Life Snippets" is marked as selected in semantics
      final lifeSnippetsSemantics = tester.getSemantics(
        find.bySemanticsLabel('Life Snippets'),
      );
      expect(lifeSnippetsSemantics.flagsCollection.isSelected, Tristate.isTrue);

      // Verify "Work Journal" is not marked as selected
      final workJournalSemantics = tester.getSemantics(
        find.bySemanticsLabel('Work Journal'),
      );
      expect(
        workJournalSemantics.flagsCollection.isSelected,
        isNot(Tristate.isTrue),
      );

      // Tap "Work Journal"
      await tester.tap(find.bySemanticsLabel('Work Journal'));
      await tester.pumpAndSettle();

      expect(onSelectCalled, true);
      expect(selectedJournalId, 'j1');
    },
  );

  testWidgets('drawer items hit area >= 44px', (tester) async {
    await tester.pumpWidget(
      buildDrawerHost(
        journals: mockJournals,
        onSelectJournal: (_) {},
        onNavigate: (_) {},
        onNewJournal: () {},
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final itemFinder = find.bySemanticsLabel('Work Journal');
    final itemSize = tester.getSize(itemFinder);

    expect(itemSize.width, greaterThanOrEqualTo(44.0));
    expect(itemSize.height, greaterThanOrEqualTo(44.0));
  });

  testWidgets('new journal action hit area >= 44px', (tester) async {
    await tester.pumpWidget(
      buildDrawerHost(
        journals: mockJournals,
        onSelectJournal: (_) {},
        onNavigate: (_) {},
        onNewJournal: () {},
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final actionSize = tester.getSize(
      find.bySemanticsLabel(AppStrings.newJournal),
    );

    expect(actionSize.width, greaterThanOrEqualTo(44.0));
    expect(actionSize.height, greaterThanOrEqualTo(44.0));
  });

  testWidgets('drawer does not contain search entry', (tester) async {
    await tester.pumpWidget(
      buildDrawerHost(
        journals: mockJournals,
        onSelectJournal: (_) {},
        onNavigate: (_) {},
        onNewJournal: () {},
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(AppStrings.search), findsNothing);
  });
}
