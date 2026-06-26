// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import 'package:dayz/l10n/gen/app_localizations.dart';
import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';
import 'dayz_icon.dart';
import 'dayz_icons.dart';

/// Visual variants for [DayzTag].
///
/// Author: @Ray
enum DayzTagVariant { filled, outline }

/// Token-driven tag chip with optional remove action.
///
/// Author: @Ray
class DayzTag extends StatelessWidget {
  const DayzTag({
    super.key,
    required this.child,
    this.variant = DayzTagVariant.filled,
    this.onTap,
    this.onRemove,
    this.semanticLabel,
    this.removeSemanticLabel,
  });

  final Widget child;
  final DayzTagVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final String? semanticLabel;
  final String? removeSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final l10n = AppLocalizations.of(context);
    final interactive = onTap != null || onRemove != null;
    final effectiveRemoveSemanticLabel = removeSemanticLabel ?? l10n.remove;
    final border = variant == DayzTagVariant.outline
        ? Border.all(color: colors.hairline2)
        : null;
    final background = variant == DayzTagVariant.filled
        ? colors.accentSoft
        : Colors.transparent;
    final foreground = variant == DayzTagVariant.filled
        ? colors.accentInk
        : colors.ink2;
    final radius = BorderRadius.circular(DayzRadii.full);

    Widget chip = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      constraints: BoxConstraints(
        minWidth: interactive ? 44 : 0,
        minHeight: interactive ? 44 : 30,
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: onRemove == null ? 12 : 2,
        top: 6,
        bottom: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        border: border,
        borderRadius: radius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DefaultTextStyle.merge(
            style: text.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: foreground,
              height: 1,
            ),
            child: child,
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 2),
            Semantics(
              button: true,
              label: effectiveRemoveSemanticLabel,
              child: SizedBox.square(
                dimension: 44,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  tooltip: effectiveRemoveSemanticLabel,
                  onPressed: onRemove,
                  icon: DayzIcon.path(
                    DayzIcons.closePath,
                    size: 14,
                    color: foreground.withValues(alpha: 0.62),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      chip = Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: radius, onTap: onTap, child: chip),
      );
    }

    if (semanticLabel != null) {
      chip = Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: chip,
      );
    }

    return chip;
  }
}
