// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/reader/reader_image.dart';
import 'package:flutter/widgets.dart';

/// Test double for reader thumbnail loading.
///
/// Author: @Ray
class FakeReaderThumbnailCache implements ReaderThumbnailCache {
  final Map<String, FakeReaderThumbnailHandle> handles = {};
  final List<List<String>> warmupCalls = [];
  var synchronousRebuildCalls = 0;

  @override
  ReaderThumbnailHandle request(String mediaId) {
    return handles.putIfAbsent(
      mediaId,
      () => FakeReaderThumbnailHandle.pending(),
    );
  }

  @override
  Future<void> warmup(List<String> mediaIds) async {
    warmupCalls.add(List<String>.unmodifiable(mediaIds));
  }

  void complete(String mediaId, ImageProvider provider) {
    final handle = request(mediaId) as FakeReaderThumbnailHandle;
    handle.complete(provider);
  }

  void rebuildSynchronously() {
    synchronousRebuildCalls++;
  }
}

class FakeReaderThumbnailHandle implements ReaderThumbnailHandle {
  FakeReaderThumbnailHandle.pending()
    : _state = ReaderThumbnailState.pending,
      _provider = null,
      _ready = Future<void>.value();

  FakeReaderThumbnailHandle.ready(ImageProvider provider)
    : _state = ReaderThumbnailState.ready,
      _provider = provider,
      _ready = Future<void>.value();

  ReaderThumbnailState _state;
  ImageProvider? _provider;
  Future<void> _ready;

  @override
  ReaderThumbnailState get state => _state;

  @override
  ImageProvider? get provider => _provider;

  @override
  Future<void> get ready => _ready;

  void complete(ImageProvider provider) {
    _state = ReaderThumbnailState.ready;
    _provider = provider;
    _ready = Future<void>.value();
  }
}
