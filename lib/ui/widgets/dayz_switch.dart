// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';

import '../theme/dayz_colors.dart';
import '../theme/dayz_tokens.g.dart';
import '../util/dayz_motion.dart';

/// Token-driven DayZ switch with a 44px hit target.
///
/// Author: @Ray
class DayzSwitch extends StatelessWidget {
  const DayzSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final l10n = AppLocalizations.of(context);
    final duration = dayzMotionDuration(context);
    final enabled = onChanged != null;
    final label = semanticLabel ?? (value ? l10n.switchOn : l10n.switchOff);

    final control = SizedBox(
      width: 46,
      height: 44,
      child: Center(
        child: Stack(
          children: [
            AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              width: 46,
              height: 28,
              decoration: BoxDecoration(
                color: value && enabled ? colors.accent : colors.ink4,
                borderRadius: BorderRadius.circular(DayzRadii.full),
              ),
            ),
            AnimatedPositioned(
              duration: duration,
              curve: Curves.easeOutCubic,
              left: value ? 21 : 3,
              top: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DayzRadii.full),
                  boxShadow: colors.shadowSm,
                ),
                child: const SizedBox.square(dimension: 22),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      toggled: value,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: ExcludeSemantics(child: control),
      ),
    );
  }
}
