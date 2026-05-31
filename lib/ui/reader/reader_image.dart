// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../thumbnails/thumbnail_cache.dart' as thumbnails;
import '../../thumbnails/thumbnail_handle.dart' as thumbnails;
import '../theme/dayz_colors.dart';
import '../util/dayz_motion.dart';

/// Reader-facing thumbnail state.
///
/// Author: @Ray
enum ReaderThumbnailState { pending, ready, failed, cancelled }

/// Reader-facing thumbnail handle with an optional image provider.
///
/// Author: @Ray
abstract interface class ReaderThumbnailHandle {
  ReaderThumbnailState get state;
  ImageProvider? get provider;
  Future<void> get ready;
}

/// Thumbnail cache contract used by reader UI.
///
/// Author: @Ray
abstract interface class ReaderThumbnailCache {
  ReaderThumbnailHandle request(String mediaId);
  Future<void> warmup(List<String> mediaIds);
}

/// Adapter from the current thumbnail cache API to the reader contract.
///
/// The current lower-level handle exposes readiness but not a provider. Until
/// that API grows one, ready thumbnails resolve to a stable in-memory provider.
///
/// Author: @Ray
class ThumbnailCacheReaderAdapter implements ReaderThumbnailCache {
  const ThumbnailCacheReaderAdapter(this._cache);

  final thumbnails.ThumbnailCache _cache;

  @override
  ReaderThumbnailHandle request(String mediaId) {
    return _ThumbnailHandleAdapter(_cache.request(mediaId));
  }

  @override
  Future<void> warmup(List<String> mediaIds) async {
    _cache.warmup(mediaIds);
  }
}

/// Async thumbnail image for reader cover and gallery tiles.
///
/// Author: @Ray
class ReaderImage extends StatefulWidget {
  const ReaderImage({
    super.key,
    required this.mediaId,
    required this.thumbnailCache,
    this.fit = BoxFit.cover,
  });

  final String mediaId;
  final ReaderThumbnailCache thumbnailCache;
  final BoxFit fit;

  @override
  State<ReaderImage> createState() => _ReaderImageState();
}

class _ReaderImageState extends State<ReaderImage> {
  late ReaderThumbnailHandle _handle;

  @override
  void initState() {
    super.initState();
    _request();
  }

  @override
  void didUpdateWidget(covariant ReaderImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId ||
        oldWidget.thumbnailCache != widget.thumbnailCache) {
      _request();
    }
  }

  void _request() {
    _handle = widget.thumbnailCache.request(widget.mediaId);
    if (_handle.state != ReaderThumbnailState.ready) {
      widget.thumbnailCache.warmup([widget.mediaId]);
      _handle.ready.catchError((_) {}).whenComplete(() {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = _handle.state == ReaderThumbnailState.ready
        ? _handle.provider
        : null;

    return AnimatedSwitcher(
      key: const ValueKey('reader-image-switcher'),
      duration: dayzMotionDuration(context),
      child: provider == null
          ? ColoredBox(
              key: const ValueKey('reader-image-placeholder'),
              color: context.dayz.accentSoft2,
            )
          : Image(
              key: ValueKey<String>('reader-image-${widget.mediaId}'),
              image: provider,
              fit: widget.fit,
            ),
    );
  }
}

class _ThumbnailHandleAdapter implements ReaderThumbnailHandle {
  _ThumbnailHandleAdapter(this._handle);

  final thumbnails.ThumbnailHandle _handle;

  @override
  ReaderThumbnailState get state {
    return switch (_handle.state) {
      thumbnails.ThumbnailState.pending => ReaderThumbnailState.pending,
      thumbnails.ThumbnailState.ready => ReaderThumbnailState.ready,
      thumbnails.ThumbnailState.failed => ReaderThumbnailState.failed,
      thumbnails.ThumbnailState.cancelled => ReaderThumbnailState.cancelled,
    };
  }

  @override
  ImageProvider? get provider {
    if (state != ReaderThumbnailState.ready) {
      return null;
    }
    return _readyPlaceholderProvider;
  }

  @override
  Future<void> get ready => _handle.future.then<void>((_) {}, onError: (_) {});
}

final ImageProvider _readyPlaceholderProvider = MemoryImage(
  Uint8List.fromList(_transparentPixelPng),
);

const _transparentPixelPng = <int>[
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
];
