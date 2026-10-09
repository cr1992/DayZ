// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import 'package:dayz/l10n/gen/app_localizations.dart';
import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';
import 'dayz_icon.dart';
import 'dayz_icons.dart';

/// Cross-screen empty state with illustration badge and copy.
///
/// Author: @Ray
class DayzEmptyState extends StatelessWidget {
  const DayzEmptyState({
    super.key,
    this.title,
    this.description,
    this.illustration,
    this.action,
  });

  static const Key illustrationKey = ValueKey<String>(
    'dayz-empty-state-illustration',
  );

  final String? title;
  final String? description;
  final Widget? illustration;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.dayz;
    final typography = context.dayzText;
    final effectiveTitle = title ?? l10n.emptyTitle;
    final effectiveDescription = description ?? l10n.emptyDescription;

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
                        DayzIcon(
                          '<path d="${DayzIcons.calendarPath}"/>'
                          '<path d="M8 14h8M8 17h5"/>',
                          key: illustrationKey,
                          size: 30,
                          color: colors.ink2,
                          strokeWidth: 1.8,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: DayzSpacing.s4),
            Text(
              effectiveTitle,
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
                effectiveDescription,
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
