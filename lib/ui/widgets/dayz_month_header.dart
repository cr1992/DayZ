// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../strings/app_strings.dart';
import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';
import '../util/dayz_motion.dart';
import 'dayz_icons.dart';

/// Sticky timeline month trigger shape.
///
/// Author: @Ray
class DayzMonthHeader extends StatelessWidget {
  const DayzMonthHeader({
    super.key,
    required this.month,
    required this.entryCount,
    this.expanded = false,
    this.onTap,
    this.locale,
  });

  static const Key calendarIconKey = ValueKey<String>(
    'dayz-month-header-calendar',
  );

  final DateTime month;
  final int entryCount;
  final bool expanded;
  final VoidCallback? onTap;
  final String? locale;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final typography = context.dayzText;
    final localeTag = locale ?? _localeTagOf(context);
    final normalizedMonth = DateTime(month.year, month.month);
    final monthLabel = DateFormat.MMM(localeTag).format(normalizedMonth);
    final metaLabel = [
      DateFormat.y(localeTag).format(normalizedMonth),
      _entryCountLabel(entryCount, localeTag),
    ].join(' · ');

    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DayzSpacing.s4,
          DayzSpacing.s3,
          DayzSpacing.s4,
          DayzSpacing.s2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                monthLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.h2.copyWith(
                  color: colors.ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: DayzSpacing.s2),
            Flexible(
              child: Text(
                metaLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography.caption.copyWith(
                  color: colors.ink3,
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: DayzSpacing.s2),
            AnimatedScale(
              key: calendarIconKey,
              scale: expanded ? 0.92 : 1,
              duration: dayzMotionDuration(context),
              curve: Curves.easeOutCubic,
              child: SvgPicture.string(
                _calendarSvg,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  expanded ? colors.accentInk : colors.ink3,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final body = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DayzRadii.md),
        child: content,
      ),
    );

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(color: colors.bg.withValues(alpha: 0.86)),
          child: Semantics(button: onTap != null, child: body),
        ),
      ),
    );
  }
}

String _entryCountLabel(int count, String localeTag) {
  final raw = AppStrings.entryCount(count);
  final formatted = NumberFormat.decimalPattern(localeTag).format(count);
  return raw.replaceFirst(count.toString(), formatted);
}

String _localeTagOf(BuildContext context) {
  return Localizations.maybeLocaleOf(context)?.toLanguageTag() ??
      Intl.getCurrentLocale();
}

const String _calendarSvg =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" '
    'stroke-width="2" stroke-linecap="round" stroke-linejoin="round" '
    'xmlns="http://www.w3.org/2000/svg"><path d="${DayzIcons.calendarPath}"/></svg>';
