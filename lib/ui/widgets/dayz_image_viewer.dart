// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:ui';

import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/widgets/dayz_icon.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';
import '../util/dayz_motion.dart';
import 'dayz_icons.dart';

/// Full-screen immersive image viewer for DayZ media surfaces.
///
/// Author: @Ray
class DayzImageViewer extends StatefulWidget {
  const DayzImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.captions,
    this.onClose,
  });

  final List<ImageProvider> images;
  final int initialIndex;
  final List<String?>? captions;
  final VoidCallback? onClose;

  static Color mediaBackgroundColor(DayzColors colors) {
    final source = colors.bg.computeLuminance() > 0.5 ? colors.ink : colors.bg2;
    return Color.lerp(source, const Color(0xFF050403), 0.42)!;
  }

  static Color mediaSurfaceColor(DayzColors colors) {
    return Color.alphaBlend(
      colors.surface.withValues(alpha: 0.08),
      mediaBackgroundColor(colors),
    );
  }

  static Color mediaInkColor(DayzColors colors) {
    return colors.bg.computeLuminance() > 0.5 ? colors.onAccent : colors.ink;
  }

  static Color mediaInkSecondaryColor(DayzColors colors) {
    return mediaInkColor(colors).withValues(alpha: 0.72);
  }

  static Color mediaScrimColor(DayzColors colors) {
    return Colors.black.withValues(alpha: 0.46);
  }

  @override
  State<DayzImageViewer> createState() => _DayzImageViewerState();
}

class _DayzImageViewerState extends State<DayzImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  int get _lastIndex => widget.images.length - 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = _clampedInitialIndex();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void didUpdateWidget(DayzImageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.images.length != oldWidget.images.length ||
        widget.initialIndex != oldWidget.initialIndex) {
      final nextIndex = _clampedInitialIndex();
      _currentIndex = nextIndex;
      _pageController.dispose();
      _pageController = PageController(initialPage: nextIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.images.isNotEmpty,
      'DayzImageViewer requires at least one image.',
    );

    if (widget.images.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = context.dayz;
    final l10n = AppLocalizations.of(context);
    final mediaBg = DayzImageViewer.mediaBackgroundColor(colors);
    final mediaInk = DayzImageViewer.mediaInkColor(colors);
    final duration = dayzMotionDuration(context, DayzMotion.dur);

    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: context.dayzText.body.copyWith(
          color: mediaInk,
          decoration: TextDecoration.none,
        ),
        child: Semantics(
          scopesRoute: true,
          explicitChildNodes: true,
          child: ColoredBox(
            key: const ValueKey('dayz-image-viewer-background'),
            color: mediaBg,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(child: _buildBackgroundCloseLayer()),
                Positioned.fill(child: _buildGallery(colors)),
                _buildTopBar(context, colors, l10n, duration),
                _buildCaption(context, colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundCloseLayer() {
    return GestureDetector(
      key: const ValueKey('dayz-image-viewer-close-background'),
      behavior: HitTestBehavior.opaque,
      onTap: widget.onClose,
      child: const SizedBox.expand(),
    );
  }

  Widget _buildGallery(DayzColors colors) {
    return PhotoViewGallery.builder(
      key: const ValueKey('dayz-image-viewer-gallery'),
      itemCount: widget.images.length,
      pageController: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      backgroundDecoration: BoxDecoration(
        color: DayzImageViewer.mediaBackgroundColor(colors),
      ),
      scrollPhysics: const BouncingScrollPhysics(),
      builder: (context, index) {
        return PhotoViewGalleryPageOptions.customChild(
          child: _DayzImageViewerPage(
            key: ValueKey('dayz-image-viewer-page-$index'),
            image: widget.images[index],
          ),
          minScale: PhotoViewComputedScale.contained,
          initialScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 4,
          onTapUp: _handleEmptyAreaTap,
          tightMode: true,
          childSize: MediaQuery.sizeOf(context),
          gestureDetectorBehavior: HitTestBehavior.deferToChild,
        );
      },
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    DayzColors colors,
    AppLocalizations l10n,
    Duration duration,
  ) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final ink = DayzImageViewer.mediaInkColor(colors);
    final surface = DayzImageViewer.mediaSurfaceColor(colors);

    return Positioned(
      top: topPadding + DayzSpacing.s2,
      left: DayzSpacing.s4,
      right: DayzSpacing.s4,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            Semantics(
              button: true,
              label: l10n.close,
              child: SizedBox.square(
                dimension: 44,
                child: IconButton(
                  key: const ValueKey('dayz-image-viewer-close'),
                  tooltip: l10n.close,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: surface,
                    foregroundColor: ink,
                    shape: const CircleBorder(),
                  ),
                  onPressed: widget.onClose,
                  icon: DayzIcon.path(
                    DayzIcons.closePath,
                    size: 20,
                    color: ink,
                  ),
                ),
              ),
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: duration,
              child: widget.images.length > 1
                  ? _DayzImageViewerCounter(
                      key: ValueKey('dayz-image-viewer-count-$_currentIndex'),
                      current: _currentIndex + 1,
                      total: widget.images.length,
                      colors: colors,
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('dayz-image-viewer-count-empty'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaption(BuildContext context, DayzColors colors) {
    final caption = _captionFor(_currentIndex);
    if (caption == null || caption.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final text = context.dayzText;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                DayzImageViewer.mediaScrimColor(colors),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              DayzSpacing.s5,
              DayzSpacing.s12,
              DayzSpacing.s5,
              bottomPadding + DayzSpacing.s5,
            ),
            child: Text(
              caption,
              key: const ValueKey('dayz-image-viewer-caption'),
              style: text.body.copyWith(
                color: DayzImageViewer.mediaInkColor(colors),
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  int _clampedInitialIndex() {
    if (widget.images.isEmpty) {
      return 0;
    }
    return widget.initialIndex.clamp(0, _lastIndex).toInt();
  }

  String? _captionFor(int index) {
    final captions = widget.captions;
    if (captions == null || index < 0 || index >= captions.length) {
      return null;
    }
    return captions[index];
  }

  void _handleEmptyAreaTap(
    BuildContext context,
    TapUpDetails details,
    PhotoViewControllerValue controllerValue,
  ) {
    widget.onClose?.call();
  }
}

class _DayzImageViewerPage extends StatelessWidget {
  const _DayzImageViewerPage({super.key, required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Image(image: image, fit: BoxFit.contain),
      ),
    );
  }
}

class _DayzImageViewerCounter extends StatelessWidget {
  const _DayzImageViewerCounter({
    super.key,
    required this.current,
    required this.total,
    required this.colors,
  });

  final int current;
  final int total;
  final DayzColors colors;

  @override
  Widget build(BuildContext context) {
    final label = '$current / $total';

    return Semantics(
      label: label,
      liveRegion: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DayzRadii.full),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ColoredBox(
            color: DayzImageViewer.mediaSurfaceColor(colors),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DayzSpacing.s3,
                vertical: DayzSpacing.s2,
              ),
              child: Text(
                label,
                style: context.dayzText.caption.copyWith(
                  color: DayzImageViewer.mediaInkSecondaryColor(colors),
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
