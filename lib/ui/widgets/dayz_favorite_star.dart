// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';

import '../theme/dayz_colors.dart';
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
          icon: SvgPicture.string(
            _starSvg(filled: isFavorite),
            key: ValueKey(
              'dayz-favorite-star-${isFavorite ? 'filled' : 'outline'}',
            ),
            width: size,
            height: size,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  static String _starSvg({required bool filled}) {
    if (filled) {
      return '<svg viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg"><path d="${DayzIcons.favoriteStarPath}"/></svg>';
    }

    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg"><path d="${DayzIcons.favoriteStarPath}"/></svg>';
  }
}
