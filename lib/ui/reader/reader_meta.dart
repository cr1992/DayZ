// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/components.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:dayz/ui/reader/reader_view_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

/// Reader metadata block for date, optional meta chips, and tags.
///
/// Author: @Ray
class ReaderMeta extends StatelessWidget {
  const ReaderMeta({super.key, required this.data, this.locale});

  static const kickerKey = ValueKey<String>('reader-kicker');
  static const metaWrapKey = ValueKey<String>('reader-meta-wrap');
  static const tagsWrapKey = ValueKey<String>('reader-tags-wrap');

  final ReaderViewData data;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final localeName =
        locale ?? Localizations.localeOf(context).toLanguageTag();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ReaderKicker(data: data, locale: localeName),
        if (ReaderMetaDetails.hasContent(data)) ...[
          const SizedBox(height: DayzSpacing.s3),
          ReaderMetaDetails(data: data),
        ],
        if (data.tags.isNotEmpty) ...[
          const SizedBox(height: DayzSpacing.s3),
          ReaderTags(data: data),
        ],
      ],
    );
  }
}

class ReaderKicker extends StatelessWidget {
  const ReaderKicker({super.key, required this.data, this.locale});

  final ReaderViewData data;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final localeName =
        locale ?? Localizations.localeOf(context).toLanguageTag();
    final formattedDate = DateFormat.yMMMMd(
      localeName,
    ).format(data.dateTimeLocal);

    return _ReaderKicker(dateText: formattedDate);
  }
}

class ReaderMetaDetails extends StatelessWidget {
  const ReaderMetaDetails({super.key, required this.data});

  final ReaderViewData data;

  static bool hasContent(ReaderViewData data) {
    return _weatherText(data.weather) != null ||
        _optionalText(data.place) != null ||
        _optionalText(data.mood) != null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final weather = _weatherText(data.weather);
    final place = _optionalText(data.place);
    final mood = _optionalText(data.mood);

    if (weather == null && place == null && mood == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      key: ReaderMeta.metaWrapKey,
      spacing: DayzSpacing.s2,
      runSpacing: DayzSpacing.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (weather != null)
          _ReaderMetaLabeledChild(
            label: l10n.readerMetaWeather,
            child: DayzWeatherChip(
              label: weather,
              semanticLabel: l10n.readerWeatherSemantic(weather),
            ),
          ),
        if (place != null)
          _ReaderMetaPill(
            label: l10n.readerMetaPlace,
            value: place,
            semanticLabel: l10n.readerPlaceSemantic(place),
          ),
        if (mood != null)
          _ReaderMetaPill(
            label: l10n.readerMetaMood,
            value: mood,
            semanticLabel: l10n.readerMoodSemantic(mood),
          ),
      ],
    );
  }
}

class ReaderTags extends StatelessWidget {
  const ReaderTags({super.key, required this.data});

  final ReaderViewData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tags = _tagNames(data.tags);
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      key: ReaderMeta.tagsWrapKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.readerMetaTags,
          style: context.dayzText.overline.copyWith(color: context.dayz.ink3),
        ),
        const SizedBox(height: DayzSpacing.s2),
        Wrap(
          spacing: DayzSpacing.s2,
          runSpacing: DayzSpacing.s2,
          children: [
            for (final tag in tags)
              DayzTag(
                semanticLabel: l10n.readerTagSemantic(tag),
                child: Text(tag),
              ),
          ],
        ),
      ],
    );
  }
}

String? _weatherText(ReaderWeatherViewData? weather) {
  if (weather == null) {
    return null;
  }
  return _optionalText(weather.displayLabel);
}

String? _optionalText(String? value) {
  if (value == null) {
    return null;
  }
  final text = value.trim();
  return text.isEmpty ? null : text;
}

List<String> _tagNames(List<ReaderTagViewData> tags) {
  return [
    for (final tag in tags)
      if (tag.name.trim().isNotEmpty) tag.name.trim(),
  ];
}

class _ReaderKicker extends StatelessWidget {
  const _ReaderKicker({required this.dateText});

  final String dateText;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      key: ReaderMeta.kickerKey,
      label: l10n.readerDateSemantic(dateText),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.string(
              _svg(DayzIcons.calendarPath),
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(colors.ink3, BlendMode.srcIn),
            ),
            const SizedBox(width: DayzSpacing.s2),
            Text(
              l10n.readerMetaDate,
              style: text.overline.copyWith(color: colors.ink3),
            ),
            const SizedBox(width: DayzSpacing.s2),
            Text(
              dateText,
              style: text.caption.copyWith(
                color: colors.ink2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _svg(String path) {
  return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" '
      'stroke-width="2" stroke-linecap="round" stroke-linejoin="round" '
      'xmlns="http://www.w3.org/2000/svg"><path d="$path"/></svg>';
}

class _ReaderMetaPill extends StatelessWidget {
  const _ReaderMetaPill({
    required this.label,
    required this.value,
    required this.semanticLabel,
  });

  final String label;
  final String value;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface2,
            border: Border.all(color: colors.hairline),
            borderRadius: BorderRadius.circular(DayzRadii.full),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: text.overline.copyWith(
                    color: colors.ink3,
                    fontSize: 11,
                    height: 1,
                  ),
                ),
                const SizedBox(width: DayzSpacing.s1),
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.caption.copyWith(
                      color: colors.ink2,
                      fontSize: 13,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReaderMetaLabeledChild extends StatelessWidget {
  const _ReaderMetaLabeledChild({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.dayzText.overline.copyWith(
            color: context.dayz.ink3,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: DayzSpacing.s1),
        child,
      ],
    );
  }
}
