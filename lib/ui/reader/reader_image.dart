// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../../thumbnails/thumbnail_handle.dart' as thumbnails;
import '../../thumbnails/thumbnail_image_provider.dart';
import '../theme/dayz_colors.dart';
import '../util/dayz_motion.dart';
import '../widgets/dayz_image_slot.dart';

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

/// Adapter from the composition-root thumbnail pipeline to the reader contract.
///
/// Readiness comes from the thumbnail cache handle ([request] is
/// `ThumbnailCache.request`); once ready, the provider is the decrypting
/// [ThumbnailImageLoader.providerFor] image source (decrypts and decodes
/// asynchronously, no synchronous rebuild path).
///
/// Equal when built from the same requester and loader, so route rebuilds do
/// not make [ReaderImage] re-request.
///
/// Author: @Ray
class ThumbnailCacheReaderAdapter implements ReaderThumbnailCache {
  const ThumbnailCacheReaderAdapter({
    required ThumbnailRequester request,
    required ThumbnailImageLoader images,
  }) // 命名参数保持公开名（request / images），字段私有。
    // ignore: prefer_initializing_formals
    : _request = request,
       // ignore: prefer_initializing_formals
       _images = images;

  final ThumbnailRequester _request;
  final ThumbnailImageLoader _images;

  @override
  ReaderThumbnailHandle request(String mediaId) {
    return _ThumbnailHandleAdapter(
      _request(mediaId),
      _images.providerFor(mediaId),
    );
  }

  @override
  Future<void> warmup(List<String> mediaIds) async {
    _images.warmup(mediaIds);
  }

  @override
  bool operator ==(Object other) {
    return other is ThumbnailCacheReaderAdapter &&
        other._request == _request &&
        identical(other._images, _images);
  }

  @override
  int get hashCode => Object.hash(_request, identityHashCode(_images));
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
          // 解密图源就绪前无帧：DayzImageSlot 保持同色占位，出帧淡入、失败兜底。
          : DayzImageSlot(
              key: ValueKey<String>('reader-image-${widget.mediaId}'),
              image: provider,
              fit: widget.fit,
            ),
    );
  }
}

class _ThumbnailHandleAdapter implements ReaderThumbnailHandle {
  _ThumbnailHandleAdapter(this._handle, this._provider);

  final thumbnails.ThumbnailHandle _handle;
  final ImageProvider _provider;

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
    return _provider;
  }

  @override
  Future<void> get ready => _handle.future.then<void>((_) {}, onError: (_) {});
}
