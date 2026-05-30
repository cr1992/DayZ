// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../strings/app_strings.dart';
import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';

/// Year divider used by year-based timeline screens.
///
/// Author: @Ray
class DayzYearSeparator extends StatelessWidget {
  const DayzYearSeparator({
    super.key,
    required this.year,
    this.referenceDate,
    this.locale,
  });

  final int year;
  final DateTime? referenceDate;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final typography = context.dayzText;
    final localeTag = locale ?? _localeTagOf(context);
    final yearsAgo = math.max(0, (referenceDate ?? DateTime.now()).year - year);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DayzSpacing.s4,
        DayzSpacing.s5,
        DayzSpacing.s4,
        DayzSpacing.s2,
      ),
      child: Row(
        children: [
          Text(
            DateFormat.y(localeTag).format(DateTime(year)),
            maxLines: 1,
            style: typography.h2.copyWith(
              color: colors.accentInk,
              fontSize: 21,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: DayzSpacing.s3),
          Text(
            _yearsAgoLabel(yearsAgo, localeTag),
            maxLines: 1,
            style: typography.caption.copyWith(
              color: colors.ink3,
              fontSize: 12,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: DayzSpacing.s3),
          Expanded(
            child: DecoratedBox(
              key: const ValueKey<String>('dayz-year-separator-line'),
              decoration: BoxDecoration(color: colors.hairline),
              child: const SizedBox(height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

String _yearsAgoLabel(int years, String localeTag) {
  final raw = AppStrings.yearsAgo(years);
  final formatted = NumberFormat.decimalPattern(localeTag).format(years);
  return raw.replaceFirst(years.toString(), formatted);
}

String _localeTagOf(BuildContext context) {
  return Localizations.maybeLocaleOf(context)?.toLanguageTag() ??
      Intl.getCurrentLocale();
}
