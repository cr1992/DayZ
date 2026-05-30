// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/shell/dayz_toast.dart';
import 'package:dayz/ui/strings/app_strings.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for [DayzToast].
///
/// Author: @Ray
void main() {
  testWidgets('shows a floating neutral SnackBar with tone icon color', (
    tester,
  ) async {
    final context = await _pumpToastHost(tester);

    DayzToast.show(context, AppStrings.toastDefault, DayzToastTone.danger);
    await _pumpToastIn(tester);

    expect(find.text(AppStrings.toastDefault), findsOneWidget);
    expect(find.bySemanticsLabel(AppStrings.toastDefault), findsOneWidget);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.floating);
    expect(snackBar.backgroundColor, DayzColors.purpleLight.ink);
    expect(snackBar.duration, DayzToast.shortDuration);

    final icon = tester.widget<Icon>(
      find.byKey(const ValueKey('dayz-toast-icon')),
    );
    expect(icon.color, DayzColors.purpleLight.danger);
  });

  testWidgets('favorite tone uses favorite icon color', (tester) async {
    final context = await _pumpToastHost(tester);

    DayzToast.show(context, AppStrings.favorite, DayzToastTone.fav);
    await _pumpToastIn(tester);

    final icon = tester.widget<Icon>(
      find.byKey(const ValueKey('dayz-toast-icon')),
    );
    expect(icon.color, DayzColors.purpleLight.favorite);
  });

  testWidgets('action exposes callback and longer duration', (tester) async {
    final context = await _pumpToastHost(tester);
    var taps = 0;

    DayzToast.show(
      context,
      AppStrings.toastDefault,
      DayzToastTone.ok,
      DayzToastAction(label: AppStrings.toastUndo, onPressed: () => taps += 1),
    );
    await _pumpToastIn(tester);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.duration, DayzToast.actionDuration);
    expect(snackBar.action, isNotNull);
    expect(find.text(AppStrings.toastUndo), findsOneWidget);

    await tester.tap(find.text(AppStrings.toastUndo));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('no-action toast closes on content tap', (tester) async {
    final context = await _pumpToastHost(tester);

    DayzToast.show(context, AppStrings.toastDismiss, DayzToastTone.info);
    await _pumpToastIn(tester);

    await tester.tap(find.text(AppStrings.toastDismiss));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.toastDismiss), findsNothing);
  });

  testWidgets('rapid calls keep at most three SnackBars mounted', (
    tester,
  ) async {
    final context = await _pumpToastHost(tester, disableAnimations: true);

    DayzToast.show(context, '${AppStrings.toastDefault} 1', DayzToastTone.info);
    DayzToast.show(context, '${AppStrings.toastDefault} 2', DayzToastTone.info);
    DayzToast.show(context, '${AppStrings.toastDefault} 3', DayzToastTone.info);
    DayzToast.show(context, '${AppStrings.toastDefault} 4', DayzToastTone.info);
    await tester.pump();

    expect(find.byType(SnackBar).evaluate().length, lessThanOrEqualTo(3));
  });
}

Future<BuildContext> _pumpToastHost(
  WidgetTester tester, {
  bool disableAnimations = false,
}) async {
  late BuildContext hostContext;

  await tester.pumpWidget(
    MaterialApp(
      theme: DayzThemes.purpleLight,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Builder(
            builder: (context) {
              hostContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );

  return hostContext;
}

Future<void> _pumpToastIn(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(DayzMotion.dur);
}
