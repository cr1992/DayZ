// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/widgets/dayz_icon.dart';
import 'package:dayz/ui/widgets/dayz_icons.dart';

class EditorMetaBar extends StatelessWidget {
  const EditorMetaBar({
    super.key,
    this.mood,
    this.weather,
    this.location,
    this.tags,
    this.onMoodTap,
    this.onWeatherTap,
    this.onLocationTap,
    this.onTagsTap,
  });

  static const Key moodChipKey = ValueKey<String>('editor-meta-mood');
  static const Key weatherChipKey = ValueKey<String>('editor-meta-weather');
  static const Key locationChipKey = ValueKey<String>('editor-meta-location');
  static const Key tagsChipKey = ValueKey<String>('editor-meta-tags');

  final String? mood;
  final String? weather;
  final String? location;
  final List<String>? tags;
  final VoidCallback? onMoodTap;
  final VoidCallback? onWeatherTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onTagsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tagLabel = _tagLabel(l10n);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _MetaChip(
            key: moodChipKey,
            label: mood ?? l10n.editorMetaMood,
            semanticLabel: l10n.editorMetaMood,
            selected: mood != null,
            onTap: onMoodTap ?? () => _showPlaceholderSheet(context),
            iconPath: DayzIcons.moodPath,
          ),
          const SizedBox(width: DayzSpacing.s2),
          _MetaChip(
            key: weatherChipKey,
            label: weather ?? l10n.editorMetaWeather,
            semanticLabel: l10n.editorMetaWeather,
            selected: weather != null,
            onTap: onWeatherTap ?? () => _showPlaceholderSheet(context),
            iconPath: DayzIcons.weatherSunPath,
          ),
          const SizedBox(width: DayzSpacing.s2),
          _MetaChip(
            key: locationChipKey,
            label: location ?? l10n.editorMetaLocation,
            semanticLabel: l10n.editorMetaLocation,
            selected: location != null,
            onTap: onLocationTap ?? () => _showPlaceholderSheet(context),
            iconPath: DayzIcons.locationPinPath,
          ),
          const SizedBox(width: DayzSpacing.s2),
          _MetaChip(
            key: tagsChipKey,
            label: tagLabel,
            semanticLabel: l10n.editorMetaTags,
            selected: tags != null && tags!.isNotEmpty,
            onTap: onTagsTap ?? () => _showPlaceholderSheet(context),
            iconPath: DayzIcons.tagPath,
          ),
        ],
      ),
    );
  }

  String _tagLabel(AppLocalizations l10n) {
    final values = tags;
    if (values == null || values.isEmpty) {
      return l10n.editorMetaTags;
    }
    return values.join(', ');
  }

  void _showPlaceholderSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DayzSpacing.s4),
            child: Text(l10n.editorMetaPlaceholderSheet),
          ),
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
    required this.iconPath,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;
  final String iconPath;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final background = selected ? colors.accentSoft : colors.bg2;
    final foreground = selected ? colors.accentInk : colors.ink2;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DayzRadii.full),
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: DayzSpacing.s3,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(DayzRadii.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DayzIcon.path(
                    iconPath,
                    size: 14,
                    color: foreground,
                  ),
                  const SizedBox(width: DayzSpacing.s1),
                  Text(
                    label,
                    style: text.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: foreground,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
