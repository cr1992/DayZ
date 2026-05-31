// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/app_shell.dart';
import 'package:dayz/ui/widgets/dayz_search_field.dart';
import '../../l10n/localized_test_app.dart';

void main() {
  late GoRouter testRouter;

  setUp(() {
    testRouter = GoRouter(
      initialLocation: '/timeline',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(
            body: child,
            onSelectJournal: (_) {},
            onNavigate: (route) => context.pushNamed(route),
            onNewJournal: () {},
          ),
          routes: [
            GoRoute(
              name: Routes.timeline,
              path: '/timeline',
              builder: (context, state) => const SizedBox(
                key: ValueKey('timeline-content'),
                height: 100,
              ),
            ),
          ],
        ),
        GoRoute(
          name: Routes.search,
          path: '/search',
          builder: (context, state) => const Text('Search Page Content'),
        ),
      ],
    );
  });

  Widget buildTestApp() {
    return localizedRouterTestApp(routerConfig: testRouter);
  }

  testWidgets('AppShell renders body and can open drawer via menu button', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Body should be rendered
    expect(find.byKey(const ValueKey('timeline-content')), findsOneWidget);

    // Drawer is closed initially
    expect(find.text(testL10n.allJournals), findsNothing);

    // Tap menu button
    final menuButton = find.bySemanticsLabel(testL10n.menu);
    expect(menuButton, findsOneWidget);
    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    // Drawer should open and display stub text
    expect(find.text(testL10n.allJournals), findsOneWidget);
  });

  testWidgets(
    'AppShell navigation buttons have hit areas >= 44px and semantics labels',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final menuButtonFinder = find.bySemanticsLabel(testL10n.menu);
      final searchButtonFinder = find.bySemanticsLabel(testL10n.search);

      expect(menuButtonFinder, findsOneWidget);
      expect(searchButtonFinder, findsOneWidget);

      final menuSize = tester.getSize(menuButtonFinder);
      final searchSize = tester.getSize(searchButtonFinder);

      expect(menuSize.width, greaterThanOrEqualTo(44.0));
      expect(menuSize.height, greaterThanOrEqualTo(44.0));
      expect(searchSize.width, greaterThanOrEqualTo(44.0));
      expect(searchSize.height, greaterThanOrEqualTo(44.0));
    },
  );

  testWidgets('clicking search button opens search field and navigates on submit', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Click search button
    final searchButton = find.bySemanticsLabel(testL10n.search);
    await tester.tap(searchButton);
    await tester.pumpAndSettle();

    // DayzSearchField should be revealed and shown
    expect(find.byType(DayzSearchField), findsOneWidget);
    // Should not have navigated yet
    expect(find.text('Search Page Content'), findsNothing);

    // Enter text and submit to trigger navigation
    await tester.enterText(find.byType(TextField), 'Test query');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // Page should navigate and show search content (which is outside AppShell in this test configuration)
    expect(find.text('Search Page Content'), findsOneWidget);
    expect(testRouter.canPop(), true);

    testRouter.pop();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('timeline-content')), findsOneWidget);
  });
}
