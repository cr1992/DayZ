// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/shell/dayz_sheet.dart';
import '../../l10n/localized_test_app.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/widgets/dayz_button.dart';
import 'package:dayz/ui/widgets/dayz_icon.dart';
import 'package:dayz/ui/widgets/dayz_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for [DayzSheet].
///
/// Author: @Ray
void main() {
  testWidgets('actions sheet renders items, cancel row, and closes on tap', (
    tester,
  ) async {
    var taps = 0;

    await _pumpSheetHost(
      tester,
      onOpen: (context) {
        DayzSheet.actions<void>(
          context,
          items: [
            DayzSheetItem(
              label: testL10n.edit,
              desc: testL10n.toastDefault,
              icon: Icons.edit_outlined,
              onTap: () => taps += 1,
            ),
          ],
        );
      },
    );

    await _openSheet(tester);

    expect(find.byKey(const ValueKey('dayz-sheet-frame')), findsOneWidget);
    expect(find.byKey(const ValueKey('dayz-sheet-handle')), findsOneWidget);
    expect(find.text(testL10n.edit), findsOneWidget);
    expect(find.text(testL10n.sheetCancel), findsOneWidget);
    expect(find.bySemanticsLabel(testL10n.edit), findsOneWidget);

    final itemSize = tester.getSize(
      find.byKey(ValueKey('dayz-sheet-item-${testL10n.edit}')),
    );
    expect(itemSize.height, greaterThanOrEqualTo(44));

    await tester.tap(find.bySemanticsLabel(testL10n.edit));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(find.text(testL10n.edit), findsNothing);
  });

  testWidgets('actions sheet title renders as a .sheet-head header', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pumpSheetHost(
      tester,
      onOpen: (context) {
        DayzSheet.actions<void>(
          context,
          title: testL10n.more,
          items: [DayzSheetItem(label: testL10n.edit, onTap: () {})],
        );
      },
    );

    await _openSheet(tester);

    final title = tester.widget<Text>(find.byKey(DayzSheet.titleKey));
    expect(title.data, testL10n.more);
    expect(title.textAlign, TextAlign.center);
    expect(title.style?.fontSize, 17);
    expect(title.style?.fontWeight, FontWeight.w600);
    expect(title.style?.color, DayzColors.purpleLight.ink);
    final node = tester.getSemantics(find.byKey(DayzSheet.titleKey));
    expect(node.flagsCollection.isHeader, isTrue);
    handle.dispose();
  });

  testWidgets('actions sheet without title renders no title node', (
    tester,
  ) async {
    await _pumpSheetHost(
      tester,
      onOpen: (context) {
        DayzSheet.actions<void>(
          context,
          items: [DayzSheetItem(label: testL10n.edit, onTap: () {})],
        );
      },
    );

    await _openSheet(tester);

    expect(find.text(testL10n.edit), findsOneWidget);
    expect(find.byKey(DayzSheet.titleKey), findsNothing);
  });

  testWidgets('sheet items accept DayzIcons path / markup and keep IconData', (
    tester,
  ) async {
    await _pumpSheetHost(
      tester,
      onOpen: (context) {
        DayzSheet.actions<void>(
          context,
          items: [
            DayzSheetItem(
              label: testL10n.delete,
              iconPath: DayzIcons.trashPath,
              tone: DayzSheetTone.danger,
              onTap: () {},
            ),
            DayzSheetItem(
              label: testL10n.more,
              iconMarkup: DayzIcons.checklist,
              onTap: () {},
            ),
            DayzSheetItem(
              label: testL10n.edit,
              icon: Icons.edit_outlined,
              onTap: () {},
            ),
          ],
        );
      },
    );

    await _openSheet(tester);

    DayzIcon iconOf(String label) => tester.widget<DayzIcon>(
      find.descendant(
        of: find.byKey(ValueKey('dayz-sheet-item-$label')),
        matching: find.byType(DayzIcon),
      ),
    );

    final pathIcon = iconOf(testL10n.delete);
    expect(pathIcon.markup, '<path d="${DayzIcons.trashPath}"/>');
    expect(pathIcon.color, DayzColors.purpleLight.danger);
    expect(pathIcon.size, 21);

    final markupIcon = iconOf(testL10n.more);
    expect(markupIcon.markup, DayzIcons.checklist);
    expect(markupIcon.color, DayzColors.purpleLight.ink);

    final legacy = find.descendant(
      of: find.byKey(ValueKey('dayz-sheet-item-${testL10n.edit}')),
      matching: find.byType(Icon),
    );
    expect(tester.widget<Icon>(legacy).icon, Icons.edit_outlined);
    expect(
      find.descendant(
        of: find.byKey(ValueKey('dayz-sheet-item-${testL10n.edit}')),
        matching: find.byType(DayzIcon),
      ),
      findsNothing,
    );
  });

  testWidgets('keepOpen item stays visible and scrim dismisses sheet', (
    tester,
  ) async {
    var taps = 0;

    await _pumpSheetHost(
      tester,
      onOpen: (context) {
        DayzSheet.actions<void>(
          context,
          items: [
            DayzSheetItem(
              label: testL10n.more,
              keepOpen: true,
              onTap: () => taps += 1,
            ),
          ],
        );
      },
    );

    await _openSheet(tester);
    await tester.tap(find.bySemanticsLabel(testL10n.more));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(find.text(testL10n.more), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.text(testL10n.more), findsNothing);
  });

  testWidgets('picker sheet shows selected check and swatch', (tester) async {
    await _pumpSheetHost(
      tester,
      onOpen: (context) {
        DayzSheet.picker<void>(
          context,
          items: [
            DayzSheetItem(
              label: testL10n.camera,
              swatch: DayzColors.purpleLight.favorite,
              selected: true,
              keepOpen: true,
              onTap: () {},
            ),
            DayzSheetItem(
              label: testL10n.voice,
              icon: Icons.mic_none_outlined,
              onTap: () {},
            ),
          ],
        );
      },
    );

    await _openSheet(tester);

    expect(
      find.byKey(ValueKey('dayz-sheet-selected-${testL10n.camera}')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(testL10n.camera), findsOneWidget);

    final swatch = tester.widget<DecoratedBox>(
      find.byKey(ValueKey('dayz-sheet-swatch-${testL10n.camera}')),
    );
    final decoration = swatch.decoration as BoxDecoration;
    expect(decoration.color, DayzColors.purpleLight.favorite);
  });

  testWidgets('form sheet renders content and primary secondary actions', (
    tester,
  ) async {
    var primaryTaps = 0;
    var secondaryTaps = 0;

    await _pumpSheetHost(
      tester,
      onOpen: (context) {
        DayzSheet.form<void>(
          context,
          content: Text(testL10n.plainText),
          primary: DayzSheetAction(
            label: testL10n.sheetConfirm,
            onPressed: () => primaryTaps += 1,
          ),
          secondary: DayzSheetAction(
            label: testL10n.sheetCancel,
            onPressed: () => secondaryTaps += 1,
          ),
        );
      },
    );

    await _openSheet(tester);

    expect(find.text(testL10n.plainText), findsOneWidget);
    expect(find.text(testL10n.sheetConfirm), findsOneWidget);
    expect(find.text(testL10n.sheetCancel), findsOneWidget);

    await tester.tap(find.text(testL10n.sheetConfirm));
    await tester.pumpAndSettle();

    expect(primaryTaps, 1);
    expect(secondaryTaps, 0);
    expect(find.text(testL10n.plainText), findsNothing);
  });

  testWidgets('confirm sheet uses danger primary action and returns true', (
    tester,
  ) async {
    var confirmTaps = 0;
    late Future<bool?> sheetResult;

    await _pumpSheetHost(
      tester,
      onOpen: (context) {
        sheetResult = DayzSheet.confirm(
          context,
          title: testL10n.toastDefault,
          desc: testL10n.emptyDescription,
          primaryLabel: testL10n.sheetDelete,
          onConfirm: () => confirmTaps += 1,
        );
      },
    );

    await _openSheet(tester);

    final primaryButton = tester.widget<DayzButton>(
      find.descendant(
        of: find.byKey(const ValueKey('dayz-sheet-confirm-primary')),
        matching: find.byType(DayzButton),
      ),
    );
    expect(primaryButton.variant, DayzButtonVariant.danger);

    final cancelButton = tester.widget<DayzButton>(
      find.descendant(
        of: find.byKey(const ValueKey('dayz-sheet-confirm-cancel')),
        matching: find.byType(DayzButton),
      ),
    );
    expect(cancelButton.variant, DayzButtonVariant.ghost);
    expect(find.text(testL10n.sheetCancel), findsOneWidget);

    await tester.tap(find.text(testL10n.sheetDelete));
    await tester.pumpAndSettle();

    expect(confirmTaps, 1);
    expect(await sheetResult, true);
  });

  testWidgets('disableAnimations configures bottom sheet with no animation', (
    tester,
  ) async {
    await _pumpSheetHost(
      tester,
      disableAnimations: true,
      onOpen: (context) {
        DayzSheet.actions<void>(
          context,
          items: [DayzSheetItem(label: testL10n.camera, onTap: () {})],
        );
      },
    );

    await tester.tap(find.byKey(const ValueKey('open-dayz-sheet')));
    await tester.pump();

    final bottomSheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(bottomSheet.animationController?.duration, Duration.zero);
    expect(find.text(testL10n.camera), findsOneWidget);
  });

  testWidgets('sheet scrim is attached to root navigator', (tester) async {
    await tester.pumpWidget(
      localizedMaterialApp(
        home: Column(
          children: [
            const SizedBox(height: 80, child: Text('Status area')),
            Expanded(
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    body: Builder(
                      builder: (context) {
                        return IconButton(
                          key: const ValueKey('open-dayz-sheet'),
                          onPressed: () {
                            DayzSheet.actions<void>(
                              context,
                              items: [
                                DayzSheetItem(
                                  label: testL10n.edit,
                                  onTap: () {},
                                ),
                              ],
                            );
                          },
                          icon: const Icon(Icons.more_horiz),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    await _openSheet(tester);

    final barrierSizes = [
      for (final element
          in find
              .byWidgetPredicate(
                (widget) =>
                    widget is ModalBarrier || widget is AnimatedModalBarrier,
              )
              .evaluate())
        (element.renderObject! as RenderBox).size,
    ];

    expect(
      barrierSizes,
      contains(tester.view.physicalSize / tester.view.devicePixelRatio),
    );
  });
}

Future<void> _pumpSheetHost(
  WidgetTester tester, {
  required ValueChanged<BuildContext> onOpen,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    localizedMaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return IconButton(
                key: const ValueKey('open-dayz-sheet'),
                onPressed: () => onOpen(context),
                icon: const Icon(Icons.more_horiz),
              );
            },
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('open-dayz-sheet')));
  await tester.pumpAndSettle();
}
