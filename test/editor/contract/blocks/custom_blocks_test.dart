// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/blocks/location_block.dart';
import 'package:dayz/editor/contract/blocks/weather_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  await AppFlowyEditorLocalizations.load(
    const Locale.fromSubtags(languageCode: 'en'),
  );

  group('custom blocks', () {
    test('location and weather nodes round-trip through json', () {
      final location = locationNode(
        placeName: '上海',
        lat: 31.2304,
        lng: 121.4737,
      );
      final weather = weatherNode(weatherCode: '晴', weatherTemp: 18);

      final locationRoundTrip = Node.fromJson(location.toJson());
      final weatherRoundTrip = Node.fromJson(weather.toJson());

      expect(locationRoundTrip.toJson(), equals(location.toJson()));
      expect(weatherRoundTrip.toJson(), equals(weather.toJson()));
    });

    testWidgets('custom blocks render in the editor without throwing', (
      tester,
    ) async {
      final document = Document(
        root: pageNode(
          children: [
            locationNode(placeName: '上海', lat: 31.2304, lng: 121.4737),
            weatherNode(weatherCode: '晴', weatherTemp: 18),
          ],
        ),
      );
      final editorState = EditorState(document: document);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFlowyEditor(
              editorState: editorState,
              blockComponentBuilders: {
                ...standardBlockComponentBuilderMap,
                'location': LocationBlockComponentBuilder(),
                'weather': WeatherBlockComponentBuilder(),
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('上海'), findsOneWidget);
      expect(find.text('31.2304, 121.4737'), findsOneWidget);
      expect(find.text('18°C'), findsOneWidget);
      expect(find.text('晴'), findsOneWidget);
    });
  });
}
