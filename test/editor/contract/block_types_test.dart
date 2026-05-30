// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/block_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EditorBlockTypes', () {
    test('supported inventory matches MVP contract exactly', () {
      expect(
        EditorBlockTypes.supported,
        equals({
          'paragraph',
          'heading',
          'bulleted_list',
          'numbered_list',
          'todo_list',
          'quote',
          'divider',
          'image',
          'location',
          'weather',
        }),
      );
    });

    test('standard block constants match upstream AppFlowy keys', () {
      expect(EditorBlockTypes.paragraph, ParagraphBlockKeys.type);
      expect(EditorBlockTypes.heading, HeadingBlockKeys.type);
      expect(EditorBlockTypes.bulletedList, BulletedListBlockKeys.type);
      expect(EditorBlockTypes.numberedList, NumberedListBlockKeys.type);
      expect(EditorBlockTypes.todoList, TodoListBlockKeys.type);
      expect(EditorBlockTypes.quote, QuoteBlockKeys.type);
      expect(EditorBlockTypes.divider, DividerBlockKeys.type);
      expect(EditorBlockTypes.image, ImageBlockKeys.type);
    });

    test('custom block and data key constants are fixed', () {
      expect(EditorBlockTypes.location, 'location');
      expect(EditorBlockTypes.weather, 'weather');

      expect(LocationBlockDataKeys.placeName, 'place_name');
      expect(LocationBlockDataKeys.lat, 'lat');
      expect(LocationBlockDataKeys.lng, 'lng');

      expect(WeatherBlockDataKeys.weatherCode, 'weather_code');
      expect(WeatherBlockDataKeys.weatherTemp, 'weather_temp');
    });

    test('media references use the dedicated dayz-media url scheme', () {
      expect(EditorImageReference.scheme, 'dayz-media');
      expect(EditorImageReference.schemePrefix, 'dayz-media://');
      expect(
        EditorImageReference.urlForMediaId('media-123'),
        'dayz-media://media-123',
      );
    });
  });
}
