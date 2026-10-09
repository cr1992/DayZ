// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';

import '../theme/dayz_colors.dart';
import 'dayz_icon.dart';
import 'dayz_icons.dart';

/// Favorite star button using the canonical DayZ star path.
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

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final l10n = AppLocalizations.of(context);
    final color = isFavorite ? colors.favorite : colors.ink3;
    final label = isFavorite ? l10n.unfavorite : l10n.favorite;

    return Semantics(
      button: onPressed != null,
      label: label,
      child: SizedBox.square(
        dimension: 44,
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          tooltip: label,
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
      ),
    );
  }
}
