// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';

/// Token-driven DayZ dialog surface.
///
/// Author: @Ray
class DayzDialog extends StatelessWidget {
  const DayzDialog({
    super.key,
    required this.title,
    required this.message,
    this.actions = const [],
    this.semanticLabel,
  });

  final Widget title;
  final Widget message;
  final List<Widget> actions;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;

    return Semantics(
      container: true,
      label: semanticLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 360),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.hairline),
            borderRadius: BorderRadius.circular(DayzRadii.lg),
            boxShadow: colors.shadowLg,
          ),
          child: Padding(
            padding: const EdgeInsets.all(DayzSpacing.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle.merge(
                  style: text.h2.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: colors.ink,
                  ),
                  child: title,
                ),
                const SizedBox(height: DayzSpacing.s2),
                DefaultTextStyle.merge(
                  style: text.body.copyWith(
                    fontSize: 14,
                    height: 1.6,
                    color: colors.ink2,
                  ),
                  child: message,
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: DayzSpacing.s5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 76,
                            minHeight: 44,
                          ),
                          child: actions[i],
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
