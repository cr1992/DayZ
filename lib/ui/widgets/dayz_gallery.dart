// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';

import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';

/// Token-driven image gallery grid for entry cards and reader pages.
///
/// Author: @Ray
class DayzGallery extends StatelessWidget {
  const DayzGallery({
    super.key,
    required this.images,
    this.onImageTap,
    this.onMoreTap,
    this.spacing = DayzSpacing.s1,
    this.expanded = false,
  });

  final List<ImageProvider> images;
  final ValueChanged<int>? onImageTap;
  final VoidCallback? onMoreTap;
  final double spacing;
  final bool expanded;

  static int columnsForCount(int count) {
    if (count <= 1) {
      return 1;
    }
    if (count == 2 || count == 4) {
      return 2;
    }
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = context.dayz;
    final l10n = AppLocalizations.of(context);
    final text = context.dayzText;
    final total = images.length;
    final showCollapsedOverlay = total >= 10 && !expanded;
    final visibleCount = showCollapsedOverlay ? 9 : total;
    final visibleImages = images.take(visibleCount).toList(growable: false);
    final columns = columnsForCount(total);
    final aspectRatio = total == 1 ? 4 / 3 : 1.0;

    return GridView.count(
      key: const ValueKey('dayz-gallery-grid'),
      crossAxisCount: columns,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: aspectRatio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < visibleImages.length; i++)
          _DayzGalleryTile(
            image: visibleImages[i],
            index: i,
            onTap: i == 8 && showCollapsedOverlay
                ? onMoreTap ?? () => onImageTap?.call(i)
                : onImageTap == null
                ? null
                : () => onImageTap!(i),
            moreLabel: i == 8 && showCollapsedOverlay
                ? l10n.galleryMoreCount(total - 9)
                : null,
            colors: colors,
            text: text,
          ),
      ],
    );
  }
}

class _DayzGalleryTile extends StatelessWidget {
  const _DayzGalleryTile({
    required this.image,
    required this.index,
    required this.colors,
    required this.text,
    this.onTap,
    this.moreLabel,
  });

  final ImageProvider image;
  final int index;
  final VoidCallback? onTap;
  final String? moreLabel;
  final DayzColors colors;
  final DayzTextTheme text;

  @override
  Widget build(BuildContext context) {
    Widget tile = ClipRRect(
      borderRadius: BorderRadius.circular(DayzRadii.xs),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: colors.accentSoft2,
            child: Image(image: image, fit: BoxFit.cover),
          ),
          if (moreLabel != null)
            ColoredBox(
              color: const Color(0x7514100A),
              child: Center(
                child: Text(
                  moreLabel!,
                  style: text.body.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap != null) {
      tile = Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: tile),
      );
    }

    return Semantics(
      button: onTap != null,
      image: true,
      label: moreLabel,
      child: tile,
    );
  }
}
