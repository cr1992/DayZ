// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../gen/assets.gen.dart';
import '../ui/components.dart';
import '../ui/reader/reader_screen.dart';
import '../ui/reader/reader_view_data.dart';
import '../ui/theme/dayz_tokens.g.dart';

/// Debug Home demo for the reader screen.
///
/// Author: @Ray
class ReaderDemo extends StatefulWidget {
  const ReaderDemo({super.key});

  @override
  State<ReaderDemo> createState() => _ReaderDemoState();
}

class _ReaderDemoState extends State<ReaderDemo> {
  _ReaderDemoStateValue _state = _ReaderDemoStateValue.defaultEntry;
  final _repository = _DemoReaderRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(DayzSpacing.s4),
              child: DayzSegmented<_ReaderDemoStateValue>(
                value: _state,
                onChanged: (value) => setState(() => _state = value),
                segments: const [
                  DayzSegment(
                    value: _ReaderDemoStateValue.defaultEntry,
                    child: Text('默认'),
                  ),
                  DayzSegment(
                    value: _ReaderDemoStateValue.textOnly,
                    child: Text('纯文字'),
                  ),
                  DayzSegment(
                    value: _ReaderDemoStateValue.loading,
                    child: Text('加载'),
                  ),
                  DayzSegment(
                    value: _ReaderDemoStateValue.missing,
                    child: Text('找不到'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReaderScreen(
                key: ValueKey(_state),
                entryId: 'demo-entry',
                repository: _repository,
                loadData: (_) => _loadDemoData(),
                imageProviderFor: _demoImageProviderFor,
                onBack: () {},
                onEdit: (_) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<ReaderViewData?> _loadDemoData() {
    return switch (_state) {
      _ReaderDemoStateValue.defaultEntry => Future.value(_defaultData),
      _ReaderDemoStateValue.textOnly => Future.value(_textOnlyData),
      _ReaderDemoStateValue.loading => Future<ReaderViewData?>.delayed(
        const Duration(seconds: 30),
        () => _defaultData,
      ),
      _ReaderDemoStateValue.missing => Future.value(null),
    };
  }
}

enum _ReaderDemoStateValue { defaultEntry, textOnly, loading, missing }

ImageProvider _demoImageProviderFor(ReaderMediaViewData media) {
  return AssetImage(Assets.editor.demoImage.path);
}

class _DemoReaderRepository implements ReaderRepository {
  @override
  Future<ReaderEntryRecord?> byId(String id) async {
    return null;
  }

  @override
  Future<List<ReaderJournalRecord>> listJournals() async {
    return const [
      ReaderJournalRecord(id: 'journal-1', name: '日常', entryCount: 42),
      ReaderJournalRecord(id: 'journal-2', name: '旅行', entryCount: 12),
    ];
  }

  @override
  Future<List<ReaderMediaRecord>> listMedia(String entryId) async {
    return const <ReaderMediaRecord>[];
  }

  @override
  Future<List<ReaderTagRecord>> listTags(String entryId) async {
    return const <ReaderTagRecord>[];
  }

  @override
  Future<void> restore(String id) async {}

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> updateFavorite(String id, bool isFavorite) async {}

  @override
  Future<void> updateJournal(String id, String? journalId) async {}
}

final _defaultData = ReaderViewData(
  id: 'demo-entry',
  dateTimeLocal: DateTime(2026, 5, 31, 21, 18),
  title: '雨后的院子',
  bodyParagraphs: const [
    '雨后的院子',
    '木桌上还留着一圈浅浅的水印，桂花从墙角落下来。',
    '我把这一天收进日记里，像把一盏灯放回窗边。',
  ],
  cover: const ReaderMediaViewData(id: 'cover', relPath: 'demo/cover.bin'),
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
    ReaderMediaViewData(id: 'image-1', relPath: 'demo/1.bin'),
    ReaderMediaViewData(id: 'image-2', relPath: 'demo/2.bin'),
    ReaderMediaViewData(id: 'image-3', relPath: 'demo/3.bin'),
    ReaderMediaViewData(id: 'image-4', relPath: 'demo/4.bin'),
    ReaderMediaViewData(id: 'image-5', relPath: 'demo/5.bin'),
    ReaderMediaViewData(id: 'image-6', relPath: 'demo/6.bin'),
    ReaderMediaViewData(id: 'image-7', relPath: 'demo/7.bin'),
    ReaderMediaViewData(id: 'image-8', relPath: 'demo/8.bin'),
    ReaderMediaViewData(id: 'image-9', relPath: 'demo/9.bin'),
    ReaderMediaViewData(id: 'image-10', relPath: 'demo/10.bin'),
  ],
  journalId: 'journal-1',
  favorite: false,
);

final _textOnlyData = ReaderViewData(
  id: 'demo-entry',
  dateTimeLocal: DateTime(2026, 6, 1, 8, 10),
  title: '只写文字的一天',
  bodyParagraphs: const ['只写文字的一天', '没有拍照，也没有标签，只留下几行安静的段落。'],
  journalId: 'journal-1',
  favorite: false,
);
