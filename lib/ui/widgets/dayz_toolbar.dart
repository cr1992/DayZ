// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';

/// Toolbar entry model used by [DayzToolbar].
///
/// Author: @Ray
class DayzToolbarItem {
  const DayzToolbarItem.button({
    required this.semanticLabel,
    this.icon,
    this.label,
    this.active = false,
    this.onPressed,
  }) : isDivider = false;

  const DayzToolbarItem.divider()
    : isDivider = true,
      icon = null,
      label = null,
      semanticLabel = null,
      active = false,
      onPressed = null;

  final bool isDivider;
  final Widget? icon;
  final String? label;
  final String? semanticLabel;
  final bool active;
  final VoidCallback? onPressed;
}

/// Token-driven editor toolbar shell.
///
/// Author: @Ray
class DayzToolbar extends StatelessWidget {
  const DayzToolbar({super.key, required this.items, this.docked = false});

  final List<DayzToolbarItem> items;
  final bool docked;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final padding = docked
        ? const EdgeInsets.fromLTRB(10, 8, 10, 22)
        : const EdgeInsets.all(5);
    final radius = BorderRadius.circular(docked ? 0 : DayzRadii.md);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: docked ? colors.surface.withValues(alpha: 0.92) : colors.surface,
        border: Border.all(color: colors.hairline),
        borderRadius: radius,
        boxShadow: docked
            ? [
                BoxShadow(
                  color: colors.hairline,
                  offset: const Offset(0, -1),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: colors.shadowMd.first.color,
                  offset: const Offset(0, -10),
                  blurRadius: 26,
                  spreadRadius: -14,
                ),
              ]
            : colors.shadowSm,
      ),
      child: Padding(
        padding: padding,
        child: Wrap(
          spacing: docked ? 3 : 2,
          runSpacing: docked ? 3 : 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final item in items)
              item.isDivider
                  ? _DayzToolbarDivider(colors: colors)
                  : _DayzToolbarButton(item: item),
          ],
        ),
      ),
    );
  }
}

class _DayzToolbarButton extends StatelessWidget {
  const _DayzToolbarButton({required this.item});

  final DayzToolbarItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final foreground = item.active ? colors.accentInk : colors.ink2;
    final radius = BorderRadius.circular(DayzRadii.sm);

    Widget visual = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: item.active ? colors.accentSoft : Colors.transparent,
        borderRadius: radius,
      ),
      child: Center(
        child: IconTheme.merge(
          data: IconThemeData(color: foreground, size: 18),
          child: DefaultTextStyle.merge(
            style: text.body.copyWith(
              fontFamily: text.h2.fontFamily,
              fontFamilyFallback: text.h2.fontFamilyFallback,
              fontSize: 16,
              color: foreground,
              height: 1,
            ),
            child: item.icon != null
                ? ExcludeSemantics(child: item.icon!)
                : Text(item.label ?? ''),
          ),
        ),
      ),
    );

    visual = Center(child: visual);

    return Semantics(
      container: true,
      button: true,
      selected: item.active,
      enabled: item.onPressed != null,
      label: item.semanticLabel,
      child: SizedBox.square(
        dimension: 44,
        child: ExcludeSemantics(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(DayzRadii.sm),
              onTap: item.onPressed,
              child: visual,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayzToolbarDivider extends StatelessWidget {
  const _DayzToolbarDivider({required this.colors});

  final DayzColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 1,
        height: 22,
        child: DecoratedBox(decoration: BoxDecoration(color: colors.hairline2)),
      ),
    );
  }
}
