// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/ui/reader/reader_view_data.dart';

import 'fakes/fake_repos.dart';

void main() {
  group('buildReaderViewData', () {
    test(
      'maps full entry media and tags into a read-only view model',
      () async {
        final repo = FakeReaderRepository(
          entries: <String, ReaderEntryRecord>{
            'entry-1': fakeReaderEntryRecord(
              contentPlain: '雨后的院子\n桂花落在石阶上。',
              placeName: '杭州西湖',
              weatherCode: 'rain',
              weatherTemp: 19.2,
              isFavorite: true,
            ),
          },
          media: <String, List<ReaderMediaRecord>>{
            'entry-1': <ReaderMediaRecord>[
              fakeReaderMediaRecord(id: 'cover', relPath: 'media/cover.bin'),
              fakeReaderMediaRecord(id: 'gallery-1', relPath: 'media/one.bin'),
              fakeReaderMediaRecord(id: 'gallery-2', relPath: 'media/two.bin'),
            ],
          },
          tags: <String, List<ReaderTagRecord>>{
            'entry-1': <ReaderTagRecord>[
              fakeReaderTagRecord(id: 'tag-b', name: '生活'),
              fakeReaderTagRecord(id: 'tag-a', name: '五月'),
            ],
          },
        );

        final data = await buildReaderViewData('entry-1', repo);

        expect(data, isNotNull);
        expect(data!.id, 'entry-1');
        expect(data.title, '雨后的院子');
        expect(data.bodyParagraphs, <String>['雨后的院子', '桂花落在石阶上。']);
        expect(data.cover?.id, 'cover');
        expect(data.galleryImages.map((image) => image.id), <String>[
          'gallery-1',
          'gallery-2',
        ]);
        expect(data.weather, isNotNull);
        expect(data.weather!.code, 'rain');
        expect(data.weather!.temperatureCelsius, 19.2);
        expect(data.place, '杭州西湖');
        expect(data.mood, isNull);
        expect(data.tags.map((tag) => tag.name), <String>['五月', '生活']);
        expect(data.journalId, 'journal-1');
        expect(data.favorite, isTrue);
        expect(data.dateTimeLocal.toUtc(), DateTime.utc(2026, 5, 27, 8, 30));
        expect(repo.byIdCalls, <String>['entry-1']);
        expect(repo.listMediaCalls, <String>['entry-1']);
        expect(repo.listTagsCalls, <String>['entry-1']);
      },
    );

    test(
      'keeps optional fields null and collections empty for text entries',
      () async {
        final repo = FakeReaderRepository(
          entries: <String, ReaderEntryRecord>{
            'text-entry': fakeReaderEntryRecord(
              id: 'text-entry',
              journalId: null,
              contentPlain: '只写几行文字\n没有图片。',
              placeName: null,
              weatherCode: null,
              weatherTemp: null,
              isFavorite: false,
            ),
          },
        );

        final data = await buildReaderViewData('text-entry', repo);

        expect(data, isNotNull);
        expect(data!.cover, isNull);
        expect(data.weather, isNull);
        expect(data.place, isNull);
        expect(data.mood, isNull);
        expect(data.tags, isEmpty);
        expect(data.galleryImages, isEmpty);
        expect(data.journalId, isNull);
        expect(data.favorite, isFalse);
      },
    );

    test(
      'returns null for a missing entry without querying media or tags',
      () async {
        final repo = FakeReaderRepository();

        final data = await buildReaderViewData('missing', repo);

        expect(data, isNull);
        expect(repo.byIdCalls, <String>['missing']);
        expect(repo.listMediaCalls, isEmpty);
        expect(repo.listTagsCalls, isEmpty);
      },
    );
  });
}
