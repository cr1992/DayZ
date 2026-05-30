// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../strings/app_strings.dart';
import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';
import 'dayz_favorite_star.dart';
import 'dayz_gallery.dart';

/// Entry card metadata item.
///
/// Author: @Ray
class DayzEntryMeta {
  const DayzEntryMeta({required this.label, this.icon, this.semanticLabel});

  final String label;
  final Widget? icon;
  final String? semanticLabel;
}

/// Timeline entry card with date rail, summary, tags, meta, and media.
///
/// Author: @Ray
class DayzEntryCard extends StatelessWidget {
  const DayzEntryCard({
    super.key,
    required this.title,
    required this.summary,
    required this.date,
    this.tags = const [],
    this.meta = const [],
    this.favorite = false,
    this.onFavoritePressed,
    this.cover,
    this.gallery = const [],
    this.onTap,
    this.onImageTap,
    this.onGalleryMoreTap,
  });

  final String title;
  final String summary;
  final DateTime date;
  final List<String> tags;
  final List<DayzEntryMeta> meta;
  final bool favorite;
  final VoidCallback? onFavoritePressed;
  final ImageProvider? cover;
  final List<ImageProvider> gallery;
  final VoidCallback? onTap;
  final ValueChanged<int>? onImageTap;
  final VoidCallback? onGalleryMoreTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 52, child: _DateRail(date: date)),
        const SizedBox(width: DayzSpacing.s3),
        Expanded(
          child: _EntrySurface(
            colors: colors,
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (gallery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DayzSpacing.s3,
                      DayzSpacing.s3,
                      DayzSpacing.s3,
                      0,
                    ),
                    child: DayzGallery(
                      images: gallery,
                      onImageTap: onImageTap,
                      onMoreTap: onGalleryMoreTap,
                    ),
                  )
                else if (cover != null)
                  SizedBox(
                    height: 116,
                    child: ColoredBox(
                      color: colors.accentSoft2,
                      child: Image(image: cover!, fit: BoxFit.cover),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DayzSpacing.s4,
                    DayzSpacing.s3,
                    DayzSpacing.s4,
                    DayzSpacing.s4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.h2.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                                color: colors.ink,
                              ),
                            ),
                          ),
                          Semantics(
                            container: true,
                            button: onFavoritePressed != null,
                            label: favorite
                                ? AppStrings.unfavorite
                                : AppStrings.favorite,
                            child: ExcludeSemantics(
                              child: DayzFavoriteStar(
                                isFavorite: favorite,
                                onPressed: onFavoritePressed,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.diary.copyWith(
                            fontSize: 14,
                            height: 1.7,
                            color: colors.ink2,
                          ),
                        ),
                      ],
                      if (tags.isNotEmpty || meta.isNotEmpty) ...[
                        const SizedBox(height: DayzSpacing.s3),
                        Wrap(
                          spacing: DayzSpacing.s2,
                          runSpacing: DayzSpacing.s2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (final tag in tags)
                              _EntryTag(label: tag, colors: colors, text: text),
                            for (final item in meta)
                              _EntryMeta(
                                item: item,
                                colors: colors,
                                text: text,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EntrySurface extends StatelessWidget {
  const _EntrySurface({required this.colors, required this.child, this.onTap});

  final DayzColors colors;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(DayzRadii.md);
    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.hairline),
        borderRadius: radius,
        boxShadow: colors.shadowSm,
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );

    if (onTap != null) {
      surface = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          excludeFromSemantics: true,
          onTap: onTap,
          child: surface,
        ),
      );
    }

    return surface;
  }
}

class _DateRail extends StatelessWidget {
  const _DateRail({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final month = DateFormat.MMM(locale).format(date).toUpperCase();
    final weekday = DateFormat.E(locale).format(date);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          Text(
            date.day.toString(),
            style: text.h2.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              height: 1,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            month,
            style: text.caption.copyWith(
              fontSize: 11,
              color: colors.ink3,
              letterSpacing: 0,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            weekday,
            style: text.caption.copyWith(
              fontSize: 11,
              color: colors.accentInk,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTag extends StatelessWidget {
  const _EntryTag({
    required this.label,
    required this.colors,
    required this.text,
  });

  final String label;
  final DayzColors colors;
  final DayzTextTheme text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(DayzRadii.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        child: Text(
          label,
          style: text.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colors.accentInk,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _EntryMeta extends StatelessWidget {
  const _EntryMeta({
    required this.item,
    required this.colors,
    required this.text,
  });

  final DayzEntryMeta item;
  final DayzColors colors;
  final DayzTextTheme text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: item.semanticLabel ?? item.label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.icon != null) ...[
            IconTheme.merge(
              data: IconThemeData(size: 12, color: colors.ink3),
              child: ExcludeSemantics(child: item.icon!),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            item.label,
            style: text.caption.copyWith(
              fontSize: 11,
              color: colors.ink3,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
