// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/fab_speed_dial.dart';
import 'package:dayz/ui/strings/app_strings.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';

void main() {
  late GoRouter testRouter;

  setUp(() {
    testRouter = GoRouter(
      initialLocation: '/timeline',
      routes: [
        ShellRoute(
          builder: (context, state, child) =>
              Scaffold(body: child, floatingActionButton: const FabSpeedDial()),
          routes: [
            GoRoute(
              name: Routes.timeline,
              path: '/timeline',
              builder: (context, state) => const SizedBox(height: 100),
            ),
          ],
        ),
        GoRoute(
          name: Routes.editor,
          path: '/editor',
          builder: (context, state) {
            final type = state.uri.queryParameters['type'] ?? 'none';
            return Text('Editor Page Content: $type');
          },
        ),
      ],
    );
  });

  Widget buildTestApp({bool disableAnimations = false}) {
    return MaterialApp.router(
      routerConfig: testRouter,
      theme: DayzThemes.purpleLight,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: child!,
        );
      },
    );
  }

  testWidgets('light tap on FAB navigates to editor directly', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Tap FAB
    final fab = find.bySemanticsLabel(AppStrings.edit);
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Verify it navigated to editor page
    expect(find.text('Editor Page Content: none'), findsOneWidget);
    expect(testRouter.canPop(), true);

    testRouter.pop();
    await tester.pumpAndSettle();
    expect(find.text('Editor Page Content: none'), findsNothing);
  });

  testWidgets('long press threshold of 340ms opens secondary actions', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final fab = find.bySemanticsLabel(AppStrings.edit);

    // Tap down (start press)
    final gesture = await tester.startGesture(tester.getCenter(fab));

    // Wait for 300ms (below 340ms threshold)
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel(AppStrings.close), findsNothing);

    // Wait for another 50ms (crosses 340ms threshold)
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.bySemanticsLabel(AppStrings.close), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();

    // Verify all actions are visible after animation completes
    expect(find.bySemanticsLabel(AppStrings.plainText), findsOneWidget);
    expect(find.bySemanticsLabel(AppStrings.voice), findsOneWidget);
    expect(find.bySemanticsLabel(AppStrings.camera), findsOneWidget);
  });

  testWidgets(
    'clicking scrim closes the secondary actions without navigation',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Long press to open menu
      final fab = find.bySemanticsLabel(AppStrings.edit);
      final gesture = await tester.startGesture(tester.getCenter(fab));
      await tester.pump(const Duration(milliseconds: 350));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(AppStrings.close), findsOneWidget);

      // Tap scrim (which has AppStrings.close semantics label)
      await tester.tap(find.bySemanticsLabel(AppStrings.close));
      await tester.pumpAndSettle();

      // Verify overlay closed
      expect(find.bySemanticsLabel(AppStrings.close), findsNothing);
      expect(find.textContaining('Editor Page'), findsNothing);
    },
  );

  testWidgets(
    'clicking action item closes overlay and navigates with correct type query',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Long press to open menu
      final fab = find.bySemanticsLabel(AppStrings.edit);
      final gesture = await tester.startGesture(tester.getCenter(fab));
      await tester.pump(const Duration(milliseconds: 350));
      await gesture.up();
      await tester.pumpAndSettle();

      // Click Camera action
      final cameraAction = find.bySemanticsLabel(AppStrings.camera);
      expect(cameraAction, findsOneWidget);
      await tester.tap(cameraAction);
      await tester.pumpAndSettle();

      // Verify overlay closed and navigated with camera type parameter
      expect(find.bySemanticsLabel(AppStrings.close), findsNothing);
      expect(find.text('Editor Page Content: camera'), findsOneWidget);
      expect(testRouter.canPop(), true);
    },
  );

  testWidgets('FAB main and secondary buttons have hit areas >= 44px', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final fab = find.bySemanticsLabel(AppStrings.edit);
    final fabSize = tester.getSize(fab);
    expect(fabSize.width, greaterThanOrEqualTo(44.0));
    expect(fabSize.height, greaterThanOrEqualTo(44.0));

    // Long press to open
    final gesture = await tester.startGesture(tester.getCenter(fab));
    await tester.pump(const Duration(milliseconds: 350));
    await gesture.up();
    await tester.pumpAndSettle();

    final textAction = find.bySemanticsLabel(AppStrings.plainText);
    final textSize = tester.getSize(textAction);
    expect(textSize.width, greaterThanOrEqualTo(44.0));
    expect(textSize.height, greaterThanOrEqualTo(44.0));
  });

  testWidgets('under disableAnimations, overlay opens instantly', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp(disableAnimations: true));
    await tester.pumpAndSettle();

    final fab = find.bySemanticsLabel(AppStrings.edit);
    final gesture = await tester.startGesture(tester.getCenter(fab));
    await tester.pump(const Duration(milliseconds: 350));
    await gesture.up();

    // With disableAnimations, it should be in the final open state in just 1 frame (pump)
    await tester.pump();

    expect(find.bySemanticsLabel(AppStrings.close), findsOneWidget);
  });
}
