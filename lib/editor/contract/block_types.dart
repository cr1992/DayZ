// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';

/// DayZ editor contract block type inventory.
///
/// The set is intentionally closed and extends the archived
/// `editor-json-contract` inventory through active rich-block specs.
abstract final class EditorBlockTypes {
  static const String paragraph = ParagraphBlockKeys.type;
  static const String heading = HeadingBlockKeys.type;
  static const String bulletedList = BulletedListBlockKeys.type;
  static const String numberedList = NumberedListBlockKeys.type;
  static const String todoList = TodoListBlockKeys.type;
  static const String quote = QuoteBlockKeys.type;
  static const String divider = DividerBlockKeys.type;
  static const String image = ImageBlockKeys.type;

  static const String callout = 'callout';
  static const String location = 'location';
  static const String weather = 'weather';

  static const Set<String> supported = {
    paragraph,
    heading,
    bulletedList,
    numberedList,
    todoList,
    quote,
    divider,
    image,
    callout,
    location,
    weather,
  };
}

/// DayZ image references are persisted as a custom URL scheme in the native
/// AppFlowy image `url` field: `dayz-media://<media.id>`.
abstract final class EditorImageReference {
  static const String scheme = 'dayz-media';
  static const String schemePrefix = 'dayz-media://';

  static String urlForMediaId(String mediaId) => schemePrefix + mediaId;
}

abstract final class LocationBlockDataKeys {
  static const String placeName = 'place_name';
  static const String lat = 'lat';
  static const String lng = 'lng';
}

abstract final class WeatherBlockDataKeys {
  static const String weatherCode = 'weather_code';
  static const String weatherTemp = 'weather_temp';
}
