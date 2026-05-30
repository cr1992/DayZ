// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../strings/app_strings.dart';
import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';
import 'dayz_icons.dart';

/// Cross-screen empty state with illustration badge and copy.
///
/// Author: @Ray
class DayzEmptyState extends StatelessWidget {
  const DayzEmptyState({
    super.key,
    this.title = AppStrings.emptyTitle,
    this.description = AppStrings.emptyDescription,
    this.illustration,
    this.action,
  });

  static const Key illustrationKey = ValueKey<String>(
    'dayz-empty-state-illustration',
  );

  final String title;
  final String description;
  final Widget? illustration;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final typography = context.dayzText;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DayzSpacing.s10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.bg2,
                  borderRadius: BorderRadius.circular(DayzRadii.full),
                ),
                child: Center(
                  child: IconTheme(
                    data: IconThemeData(color: colors.ink2, size: 30),
                    child:
                        illustration ??
                        SvgPicture.string(
                          _emptyIllustrationSvg,
                          key: illustrationKey,
                          width: 30,
                          height: 30,
                          colorFilter: ColorFilter.mode(
                            colors.ink2,
                            BlendMode.srcIn,
                          ),
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: DayzSpacing.s4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: typography.h2.copyWith(
                color: colors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: DayzSpacing.s2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: typography.caption.copyWith(
                  color: colors.ink3,
                  fontSize: 13.5,
                  height: 1.7,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: DayzSpacing.s4),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

const String _emptyIllustrationSvg =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" '
    'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" '
    'xmlns="http://www.w3.org/2000/svg"><path d="${DayzIcons.calendarPath}"/>'
    '<path d="M8 14h8M8 17h5"/></svg>';
