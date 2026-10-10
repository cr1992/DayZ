// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';

import '../theme/dayz_colors.dart';
import 'dayz_icon.dart';
import 'dayz_icons.dart';

/// Favorite star button using the canonical DayZ star path.
///
/// 可点击（[onPressed] 非空）时读动作：未收藏「收藏」、已收藏「取消收藏」，
/// 标为按钮；只读时读状态：已收藏「已收藏」、未收藏不出语义，不标按钮、
/// 不出 tooltip。
///
/// Author: @Ray
class DayzFavoriteStar extends StatelessWidget {
  const DayzFavoriteStar({
    super.key,
    required this.isFavorite,
    this.onPressed,
    this.size = 20,
  });

  final bool isFavorite;
  final VoidCallback? onPressed;
  final double size;

  /// 收藏星的语义标签规则（独立星与 `DayzEntryCard` 星位共用）。
  ///
  /// [interactive] 为 false（只读）且未收藏时返回 null：不出语义节点。
  static String? semanticsLabelFor(
    AppLocalizations l10n, {
    required bool isFavorite,
    required bool interactive,
  }) {
    if (interactive) {
      return isFavorite ? l10n.unfavorite : l10n.favorite;
    }
    return isFavorite ? l10n.favorited : null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final l10n = AppLocalizations.of(context);
    final color = isFavorite ? colors.favorite : colors.ink3;
    final interactive = onPressed != null;
    final label = semanticsLabelFor(
      l10n,
      isFavorite: isFavorite,
      interactive: interactive,
    );

    final star = SizedBox.square(
      dimension: 44,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        tooltip: interactive ? label : null,
        onPressed: onPressed,
        icon: DayzIcon.path(
          DayzIcons.favoriteStarPath,
          key: ValueKey(
            'dayz-favorite-star-${isFavorite ? 'filled' : 'outline'}',
          ),
          size: size,
          color: color,
          filled: isFavorite,
        ),
      ),
    );

    if (interactive) {
      return Semantics(button: true, label: label, child: star);
    }
    final readOnly = ExcludeSemantics(child: star);
    if (label == null) {
      return readOnly;
    }
    return Semantics(
      container: true,
      button: false,
      label: label,
      child: readOnly,
    );
  }
}
