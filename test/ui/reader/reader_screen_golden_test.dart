// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/reader/reader_screen.dart';
import 'package:dayz/ui/reader/reader_view_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';
import 'fakes/fake_repos.dart';

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.single;
    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.single;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('default reader state golden', (tester) async {
    await tester.pumpWidget(_goldenApp(_defaultData()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ReaderScreen),
      matchesGoldenFile('golden/reader_default.png'),
    );
  });

  testWidgets('text-only reader state golden', (tester) async {
    await tester.pumpWidget(_goldenApp(_textOnlyData()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ReaderScreen),
      matchesGoldenFile('golden/reader_text.png'),
    );
  });
}

Widget _goldenApp(ReaderViewData data) {
  return localizedMaterialApp(
    home: ReaderScreen(
      entryId: data.id,
      repository: FakeReaderRepository(),
      loadData: (_) async => data,
    ),
  );
}

ReaderViewData _defaultData() {
  return ReaderViewData(
    id: 'entry-1',
    dateTimeLocal: DateTime(2026, 5, 31, 21),
    title: '雨后的院子',
    bodyParagraphs: const [
      '雨后的院子',
      '木桌上还留着一圈浅浅的水印，桂花从墙角落下来。',
      '我把这一天收进日记里，像把一盏灯放回窗边。',
    ],
    cover: const ReaderMediaViewData(id: 'cover', relPath: 'cover.bin'),
    weather: const ReaderWeatherViewData(
      code: 'cloudy',
      label: '多云 23°C',
      temperatureCelsius: 23,
    ),
    place: '杭州',
    mood: '平静',
    tags: const [
      ReaderTagViewData(id: 'tag-1', name: '生活'),
      ReaderTagViewData(id: 'tag-2', name: '五月'),
    ],
    galleryImages: const [
      ReaderMediaViewData(id: 'image-1', relPath: 'image-1.bin'),
      ReaderMediaViewData(id: 'image-2', relPath: 'image-2.bin'),
      ReaderMediaViewData(id: 'image-3', relPath: 'image-3.bin'),
      ReaderMediaViewData(id: 'image-4', relPath: 'image-4.bin'),
    ],
    journalId: 'journal-1',
    favorite: false,
  );
}

ReaderViewData _textOnlyData() {
  return ReaderViewData(
    id: 'entry-2',
    dateTimeLocal: DateTime(2026, 6, 1, 8, 10),
    title: '只写文字的一天',
    bodyParagraphs: const [
      '只写文字的一天',
      '没有拍照，也没有标签，只留下几行安静的段落。',
      '这些段落会保留 reader 的正文节奏。',
    ],
    journalId: 'journal-1',
    favorite: false,
  );
}
