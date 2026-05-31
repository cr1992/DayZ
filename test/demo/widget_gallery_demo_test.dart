// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/demo/demo_entry.dart';
import 'package:dayz/demo/widget_gallery_demo.dart';
import 'package:dayz/ui/components.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../l10n/localized_test_app.dart';

/// Widget tests for [WidgetGalleryDemo].
///
/// Author: @Ray
void main() {
  test('demos list exposes widget gallery entry', () {
    final entry = demos.singleWhere((entry) => entry.title == 'UI Kit 组件画廊');

    expect(entry.title, 'UI Kit 组件画廊');
    expect(entry.subtitle, '原生画廊：组件 × 状态 × 六套主题');
    expect(entry.builder, isNotNull);
  });

  testWidgets('Debug Home can navigate to widget gallery', (tester) async {
    await tester.pumpWidget(localizedTestApp(child: const DebugHome()));

    expect(find.text('UI Kit 组件画廊'), findsOneWidget);

    await tester.tap(find.text('UI Kit 组件画廊'));
    await tester.pumpAndSettle();

    expect(find.byType(WidgetGalleryDemo), findsOneWidget);
    expect(find.text('基础控件'), findsWidgets);
    expect(find.text('按钮'), findsOneWidget);
    expect(find.text('主题'), findsOneWidget);
    expect(find.textContaining('真源：docs/DESIGN-REF.md:117'), findsOneWidget);
    expect(
      find.textContaining('design-system/assets/spec.css:252'),
      findsOneWidget,
    );
  });

  testWidgets('widget gallery shows design source labels for each section', (
    tester,
  ) async {
    await tester.pumpWidget(localizedTestApp(child: const WidgetGalleryDemo()));

    expect(find.textContaining('真源：docs/DESIGN-REF.md:117'), findsOneWidget);

    await tester.tap(find.text('内容组件'));
    await tester.pumpAndSettle();
    expect(find.textContaining('docs/DESIGN-REF.md:230'), findsOneWidget);

    await tester.tap(find.text('页面复用件'));
    await tester.pumpAndSettle();
    expect(find.textContaining('docs/DESIGN-REF.md:247/259'), findsOneWidget);

    await tester.tap(find.text('跨屏外壳'));
    await tester.pumpAndSettle();
    expect(find.textContaining('docs/DESIGN-REF.md:278'), findsOneWidget);
  });

  testWidgets('widget gallery choice controls update in place', (tester) async {
    await tester.pumpWidget(localizedTestApp(child: const WidgetGalleryDemo()));

    Future<void> tapVisible(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    expect(tester.widget<DayzSwitch>(find.byType(DayzSwitch)).value, isTrue);
    await tapVisible(find.bySemanticsLabel('本地备份'));
    expect(tester.widget<DayzSwitch>(find.byType(DayzSwitch)).value, isFalse);

    var options = tester.widgetList<DayzOption>(find.byType(DayzOption));
    expect(options.first.selected, isTrue);
    expect(options.last.selected, isFalse);

    await tapVisible(find.bySemanticsLabel('同步到本地备份'));
    options = tester.widgetList<DayzOption>(find.byType(DayzOption));
    expect(options.first.selected, isFalse);

    await tapVisible(find.bySemanticsLabel('跟随系统外观'));
    options = tester.widgetList<DayzOption>(find.byType(DayzOption));
    expect(options.last.selected, isTrue);

    DayzSegmented<String> segmented() {
      return tester.widget<DayzSegmented<String>>(
        find.byWidgetPredicate((widget) => widget is DayzSegmented<String>),
      );
    }

    expect(segmented().value, 'timeline');
    await tapVisible(find.text('日历'));
    expect(segmented().value, 'calendar');
  });

  testWidgets('dialog cancel action uses outlined button variant', (
    tester,
  ) async {
    await tester.pumpWidget(localizedTestApp(child: const WidgetGalleryDemo()));

    await tester.scrollUntilVisible(
      find.text('弹窗'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final cancelButton = tester.widget<DayzButton>(
      find.ancestor(
        of: find.text(testL10n.cancel),
        matching: find.byType(DayzButton),
      ),
    );

    expect(cancelButton.variant, DayzButtonVariant.ghost);
  });

  testWidgets('a gallery use case renders with selected DayZ theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        theme: DayzThemes.amberLight,
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: DayzButton(
                  onPressed: () {},
                  child: Text('${context.dayz.accent.toARGB32()}'),
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(
      find.text('${DayzColors.amberLight.accent.toARGB32()}'),
      findsOneWidget,
    );
  });
}
