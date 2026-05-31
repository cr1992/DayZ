// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:typed_data';

import '../../l10n/localized_test_app.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/widgets/dayz_button.dart';
import 'package:dayz/ui/widgets/dayz_dialog.dart';
import 'package:dayz/ui/widgets/dayz_entry_card.dart';
import 'package:dayz/ui/widgets/dayz_gallery.dart';
import 'package:dayz/ui/widgets/dayz_mood_chip.dart';
import 'package:dayz/ui/widgets/dayz_option.dart';
import 'package:dayz/ui/widgets/dayz_segmented.dart';
import 'package:dayz/ui/widgets/dayz_switch.dart';
import 'package:dayz/ui/widgets/dayz_tag.dart';
import 'package:dayz/ui/widgets/dayz_text_field.dart';
import 'package:dayz/ui/widgets/dayz_toolbar.dart';
import 'package:dayz/ui/widgets/dayz_weather_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for the ui-kit T2 base component subset.
///
/// Author: @Ray
void main() {
  testWidgets(
    'button variants use token colors and icon button has semantics',
    (tester) async {
      var taps = 0;
      const primaryKey = ValueKey('primary');
      const softKey = ValueKey('soft');
      const ghostKey = ValueKey('ghost');
      const dangerKey = ValueKey('danger');
      const disabledKey = ValueKey('disabled');
      const iconKey = ValueKey('icon');

      await _pumpDayz(
        tester,
        Wrap(
          children: [
            DayzButton(
              key: primaryKey,
              onPressed: () => taps += 1,
              child: const Text('Primary'),
            ),
            DayzButton(
              key: softKey,
              variant: DayzButtonVariant.soft,
              onPressed: () {},
              child: const Text('Soft'),
            ),
            DayzButton(
              key: ghostKey,
              variant: DayzButtonVariant.ghost,
              onPressed: () {},
              child: const Text('Ghost'),
            ),
            DayzButton(
              key: dangerKey,
              variant: DayzButtonVariant.danger,
              onPressed: () {},
              child: const Text('Danger'),
            ),
            const DayzButton(
              key: disabledKey,
              onPressed: null,
              child: Text('Disabled'),
            ),
            DayzButton.icon(
              key: iconKey,
              icon: const Icon(Icons.more_horiz),
              semanticLabel: testL10n.more,
              onPressed: () => taps += 1,
            ),
          ],
        ),
      );

      BoxDecoration decorationFor(Key key) {
        final container = tester.widget<AnimatedContainer>(
          find
              .descendant(
                of: find.byKey(key),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        );
        return container.decoration! as BoxDecoration;
      }

      expect(decorationFor(primaryKey).color, DayzColors.purpleLight.accent);
      expect(decorationFor(softKey).color, DayzColors.purpleLight.accentSoft);
      expect(
        decorationFor(ghostKey).border,
        Border.all(color: DayzColors.purpleLight.hairline2),
      );
      expect(decorationFor(dangerKey).color, Colors.transparent);
      expect(decorationFor(disabledKey).color, DayzColors.purpleLight.bg2);

      expect(find.bySemanticsLabel(testL10n.more), findsOneWidget);
      expect(tester.getSize(find.byKey(iconKey)), const Size.square(44));

      await tester.tap(find.text('Primary'));
      await tester.tap(find.text('Disabled'));
      await tester.tap(find.bySemanticsLabel(testL10n.more));
      await tester.pump();

      expect(taps, 2);
    },
  );

  testWidgets('button press moves the visual down without ripple', (
    tester,
  ) async {
    const buttonKey = ValueKey('pressable');

    await _pumpDayz(
      tester,
      DayzButton(key: buttonKey, onPressed: () {}, child: const Text('Press')),
    );

    AnimatedContainer visual() {
      return tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(buttonKey),
          matching: find.byType(AnimatedContainer),
        ),
      );
    }

    expect(visual().transform?.getTranslation().y, 0);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(buttonKey)),
    );
    await tester.pumpAndSettle();
    expect(visual().transform?.getTranslation().y, 1);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(visual().transform?.getTranslation().y, 0);
  });

  testWidgets('text field renders label/help and edits text', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await _pumpDayz(
      tester,
      DayzTextField(
        controller: controller,
        label: 'Title',
        hintText: 'Untitled',
        helpText: 'Optional',
      ),
    );

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Optional'), findsOneWidget);
    expect(
      tester.getSize(find.byType(TextField)).height,
      greaterThanOrEqualTo(44),
    );

    await tester.enterText(find.byType(TextField), 'A quiet morning');
    expect(controller.text, 'A quiet morning');
  });

  testWidgets('switch, option, and segmented expose interactions', (
    tester,
  ) async {
    bool? switchValue;
    var optionTapped = false;
    var selected = 'timeline';

    await _pumpDayz(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DayzSwitch(
            value: false,
            semanticLabel: 'Sync',
            onChanged: (value) => switchValue = value,
          ),
          DayzOption.checkbox(
            selected: true,
            semanticLabel: 'Notebook',
            onTap: () => optionTapped = true,
            child: const Text('Notebook'),
          ),
          DayzSegmented<String>(
            value: selected,
            onChanged: (value) => selected = value,
            segments: const [
              DayzSegment(value: 'timeline', child: Text('Timeline')),
              DayzSegment(value: 'calendar', child: Text('Calendar')),
            ],
          ),
        ],
      ),
    );

    expect(tester.getSize(find.byType(DayzSwitch)).height, 44);
    expect(
      tester.getSize(find.byType(DayzOption)).height,
      greaterThanOrEqualTo(44),
    );

    await tester.tap(find.bySemanticsLabel('Sync'));
    await tester.tap(find.bySemanticsLabel('Notebook'));
    await tester.tap(find.text('Calendar'));
    await tester.pump();

    expect(switchValue, isTrue);
    expect(optionTapped, isTrue);
    expect(selected, 'calendar');
  });

  testWidgets('chips, toolbar, and dialog render tokenized shells', (
    tester,
  ) async {
    var tagRemoved = false;
    var moodTapped = false;
    var weatherTapped = false;
    var toolbarTapped = false;

    await _pumpDayz(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DayzTag(
            onRemove: () => tagRemoved = true,
            child: const Text('# life'),
          ),
          DayzMoodChip(
            label: 'Happy',
            selected: true,
            onTap: () => moodTapped = true,
          ),
          DayzWeatherChip(
            label: 'Sunny 26C',
            onTap: () => weatherTapped = true,
          ),
          DayzToolbar(
            items: [
              DayzToolbarItem.button(
                semanticLabel: 'Bold',
                label: 'B',
                active: true,
                onPressed: () => toolbarTapped = true,
              ),
              const DayzToolbarItem.divider(),
              const DayzToolbarItem.button(semanticLabel: 'Italic', label: 'I'),
            ],
          ),
          const DayzDialog(
            title: Text('Delete entry'),
            message: Text('This action needs confirmation.'),
          ),
        ],
      ),
    );

    expect(find.bySemanticsLabel(testL10n.remove), findsOneWidget);
    expect(find.bySemanticsLabel('Bold'), findsOneWidget);
    expect(
      tester.getSize(find.bySemanticsLabel('Bold')),
      const Size.square(44),
    );
    expect(find.text('Delete entry'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(testL10n.remove));
    await tester.tap(find.text('Happy'));
    await tester.tap(find.text('Sunny 26C'));
    await tester.tap(find.bySemanticsLabel('Bold'));
    await tester.pump();

    expect(tagRemoved, isTrue);
    expect(moodTapped, isTrue);
    expect(weatherTapped, isTrue);
    expect(toolbarTapped, isTrue);
  });

  testWidgets('gallery derives columns and collapses the ninth tile', (
    tester,
  ) async {
    expect(DayzGallery.columnsForCount(1), 1);
    expect(DayzGallery.columnsForCount(2), 2);
    expect(DayzGallery.columnsForCount(3), 3);
    expect(DayzGallery.columnsForCount(4), 2);
    expect(DayzGallery.columnsForCount(5), 3);

    var moreTapped = false;
    await _pumpDayz(
      tester,
      SizedBox(
        width: 300,
        child: DayzGallery(
          images: _images(10),
          onMoreTap: () => moreTapped = true,
        ),
      ),
    );

    final grid = tester.widget<GridView>(
      find.byKey(const ValueKey('dayz-gallery-grid')),
    );
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

    expect(delegate.crossAxisCount, 3);
    expect(find.byType(Image), findsNWidgets(9));
    expect(find.text('+1'), findsOneWidget);

    await tester.tap(find.text('+1'));
    await tester.pump();

    expect(moreTapped, isTrue);
  });

  testWidgets('entry card exposes title, date, tags, meta, and callbacks', (
    tester,
  ) async {
    var opened = false;
    var favoriteTapped = false;

    await _pumpDayz(
      tester,
      locale: const Locale('en'),
      SizedBox(
        width: 360,
        child: DayzEntryCard(
          title: 'May rain',
          summary: 'Two lines of quiet notes.',
          date: DateTime(2026, 5, 29),
          tags: const ['# life'],
          meta: const [
            DayzEntryMeta(label: 'Shanghai', icon: Icon(Icons.place)),
          ],
          favorite: false,
          onTap: () => opened = true,
          onFavoritePressed: () => favoriteTapped = true,
          cover: _images(1).first,
        ),
      ),
    );

    expect(find.text('May rain'), findsOneWidget);
    expect(find.text('29'), findsOneWidget);
    expect(find.text('MAY'), findsOneWidget);
    expect(find.text('# life'), findsOneWidget);
    expect(find.text('Shanghai'), findsOneWidget);

    await tester.tap(find.text('May rain'));
    await tester.tap(find.bySemanticsLabel(testEnL10n.favorite));
    await tester.pump();

    expect(opened, isTrue);
    expect(favoriteTapped, isTrue);
  });
}

Future<void> _pumpDayz(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('zh'),
}) async {
  await tester.pumpWidget(
    localizedTestApp(
      locale: locale,
      child: Align(
        alignment: Alignment.topLeft,
        child: SingleChildScrollView(child: child),
      ),
    ),
  );
}

List<ImageProvider> _images(int count) {
  return List<ImageProvider>.generate(
    count,
    (_) => MemoryImage(_transparentPng),
  );
}

final Uint8List _transparentPng = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);
