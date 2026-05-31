// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';

import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';
import 'dayz_icons.dart';

/// Settings row with icon, labels, value, chevron, trailing, or switch affordance.
///
/// Author: @Ray
class DayzSetRow extends StatelessWidget {
  const DayzSetRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.showChevron = false,
    this.switchValue,
    this.onSwitchChanged,
    this.onTap,
    this.enabled = true,
  });

  static const Key chevronKey = ValueKey<String>('dayz-set-row-chevron');

  final Widget icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final bool showChevron;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final VoidCallback? onTap;
  final bool enabled;

  bool get _hasSwitch => switchValue != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final l10n = AppLocalizations.of(context);
    final typography = context.dayzText;
    final effectiveOnTap = enabled ? onTap ?? _switchTap : null;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DayzSpacing.s4,
          vertical: DayzSpacing.s3,
        ),
        child: Row(
          children: [
            _IconBadge(icon: icon),
            const SizedBox(width: DayzSpacing.s3),
            Expanded(
              child: _TitleBlock(
                title: title,
                subtitle: subtitle,
                typography: typography,
                colors: colors,
                enabled: enabled,
              ),
            ),
            const SizedBox(width: DayzSpacing.s3),
            _TrailingContent(
              value: value,
              trailing: trailing,
              showChevron: showChevron,
              switchValue: switchValue,
              onSwitchChanged: enabled ? onSwitchChanged : null,
              colors: colors,
              typography: typography,
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: effectiveOnTap != null && !_hasSwitch,
      toggled: _hasSwitch ? switchValue : null,
      value: _hasSwitch
          ? (switchValue! ? l10n.switchOn : l10n.switchOff)
          : null,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: effectiveOnTap, child: row),
      ),
    );
  }

  void _switchTap() {
    final value = switchValue;
    final onChanged = onSwitchChanged;
    if (value == null || onChanged == null) {
      return;
    }
    onChanged(!value);
  }
}

/// Bordered settings list container.
///
/// Author: @Ray
class DayzSetList extends StatelessWidget {
  const DayzSetList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final dividedChildren = <Widget>[];
    for (var index = 0; index < children.length; index += 1) {
      if (index > 0) {
        dividedChildren.add(Divider(height: 1, color: colors.hairline));
      }
      dividedChildren.add(children[index]);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(DayzRadii.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.hairline),
          borderRadius: BorderRadius.circular(DayzRadii.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: dividedChildren,
        ),
      ),
    );
  }
}

/// Labeled settings group.
///
/// Author: @Ray
class DayzSetGroup extends StatelessWidget {
  const DayzSetGroup({super.key, required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final typography = context.dayzText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DayzSpacing.s2,
            0,
            DayzSpacing.s2,
            DayzSpacing.s2,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.overline.copyWith(
              color: colors.ink3,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
        DayzSetList(children: children),
      ],
    );
  }
}

/// Account header card for settings screens.
///
/// Author: @Ray
class DayzSetAccountCard extends StatelessWidget {
  const DayzSetAccountCard({
    super.key,
    required this.title,
    this.subtitle,
    this.avatar,
    this.initials,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? avatar;
  final String? initials;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final typography = context.dayzText;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.hairline),
        borderRadius: BorderRadius.circular(DayzRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DayzSpacing.s4),
        child: Row(
          children: [
            _AccountAvatar(avatar: avatar, initials: initials),
            const SizedBox(width: DayzSpacing.s3),
            Expanded(
              child: _TitleBlock(
                title: title,
                subtitle: subtitle,
                typography: typography,
                colors: colors,
                enabled: true,
                titleSize: 17,
                titleWeight: FontWeight.w600,
                subtitleSize: 13,
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DayzRadii.md),
          child: card,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    return SizedBox.square(
      dimension: 30,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.accentSoft,
          borderRadius: BorderRadius.circular(DayzRadii.sm),
        ),
        child: IconTheme(
          data: IconThemeData(color: colors.accentInk, size: 17),
          child: Center(child: icon),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.title,
    required this.subtitle,
    required this.typography,
    required this.colors,
    required this.enabled,
    this.titleSize = 15,
    this.titleWeight = FontWeight.w500,
    this.subtitleSize = 12,
  });

  final String title;
  final String? subtitle;
  final DayzTextTheme typography;
  final DayzColors colors;
  final bool enabled;
  final double titleSize;
  final FontWeight titleWeight;
  final double subtitleSize;

  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typography.body.copyWith(
            color: enabled ? colors.ink : colors.ink4,
            fontSize: titleSize,
            fontWeight: titleWeight,
            height: 1.3,
            letterSpacing: 0,
          ),
        ),
        if (subtitleText != null)
          Text(
            subtitleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.caption.copyWith(
              color: enabled ? colors.ink3 : colors.ink4,
              fontSize: subtitleSize,
              height: 1.3,
              letterSpacing: 0,
            ),
          ),
      ],
    );
  }
}

class _TrailingContent extends StatelessWidget {
  const _TrailingContent({
    required this.value,
    required this.trailing,
    required this.showChevron,
    required this.switchValue,
    required this.onSwitchChanged,
    required this.colors,
    required this.typography,
  });

  final String? value;
  final Widget? trailing;
  final bool showChevron;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final DayzColors colors;
  final DayzTextTheme typography;

  @override
  Widget build(BuildContext context) {
    final valueText = value;
    final switchState = switchValue;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (valueText != null)
          Text(
            valueText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.caption.copyWith(
              color: colors.ink3,
              fontSize: 13,
              letterSpacing: 0,
            ),
          ),
        if (valueText != null && trailing != null)
          const SizedBox(width: DayzSpacing.s2),
        ?trailing,
        if ((valueText != null || trailing != null) && switchState != null)
          const SizedBox(width: DayzSpacing.s2),
        if (switchState != null)
          SwitchTheme(
            data: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? colors.onAccent
                    : colors.ink4;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? colors.accent
                    : colors.hairline2;
              }),
            ),
            child: Switch(value: switchState, onChanged: onSwitchChanged),
          ),
        if ((valueText != null || trailing != null || switchState != null) &&
            showChevron)
          const SizedBox(width: DayzSpacing.s2),
        if (showChevron)
          SvgPicture.string(
            _chevronSvg,
            key: DayzSetRow.chevronKey,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(colors.ink4, BlendMode.srcIn),
          ),
      ],
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.avatar, required this.initials});

  final Widget? avatar;
  final String? initials;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final typography = context.dayzText;
    final child =
        avatar ??
        Text(
          initials ?? '',
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: typography.h2.copyWith(
            color: colors.accentInk,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        );

    return SizedBox.square(
      dimension: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.accentSoft,
          borderRadius: BorderRadius.circular(DayzRadii.full),
        ),
        child: Center(child: child),
      ),
    );
  }
}

const String _chevronSvg =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" '
    'stroke-width="2" stroke-linecap="round" stroke-linejoin="round" '
    'xmlns="http://www.w3.org/2000/svg"><path d="${DayzIcons.chevronRightPath}"/></svg>';
