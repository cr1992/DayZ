// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';

/// Tail loader of the timeline (`.tl-loader` in timeline.css).
///
/// Author: @Ray
class TimelineLoader extends StatelessWidget {
  const TimelineLoader({
    super.key,
    required this.isLoading,
    required this.reachedEnd,
  });

  static const Key loaderKey = ValueKey<String>('timeline-loader');
  static const Key textKey = ValueKey<String>('timeline-loader-text');

  /// `.tl-loader { font-size: 12.5px }`.
  static const double fontSize = 12.5;

  /// `.tl-loader .spin { width/height: 15px; border: 2px }`.
  static const double spinnerSize = 15;
  static const double spinnerStroke = 2;

  final bool isLoading;
  final bool reachedEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.dayz;
    final typography = context.dayzText;
    final text = reachedEnd ? l10n.reachedOldest : l10n.loadingEarlier;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DayzSpacing.s4,
        DayzSpacing.s5,
        DayzSpacing.s4,
        DayzSpacing.s10,
      ),
      child: Row(
        key: loaderKey,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading && !reachedEnd) ...[
            SizedBox(
              width: spinnerSize,
              height: spinnerSize,
              child: CircularProgressIndicator(
                strokeWidth: spinnerStroke,
                color: colors.accent,
                backgroundColor: colors.hairline2,
              ),
            ),
            const SizedBox(width: 9),
          ],
          Text(
            text,
            key: textKey,
            style: typography.caption.copyWith(
              fontSize: fontSize,
              height: 1.4,
              color: reachedEnd ? colors.ink4 : colors.ink3,
            ),
          ),
        ],
      ),
    );
  }
}
