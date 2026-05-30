// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/dayz_colors.dart';
import '../theme/dayz_tokens.g.dart';
import '../util/dayz_motion.dart';

/// Semantic tone for [DayzToast].
///
/// Author: @Ray
enum DayzToastTone { defaultTone, ok, info, danger, fav }

/// Optional action shown by [DayzToast].
///
/// Author: @Ray
class DayzToastAction {
  const DayzToastAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// Global DayZ toast backed by [ScaffoldMessenger].
///
/// Author: @Ray
abstract final class DayzToast {
  static const shortDuration = Duration(milliseconds: 2600);
  static const actionDuration = Duration(milliseconds: 4200);

  static const _maxPendingSnackBars = 3;
  static final _pendingSnackBars =
      Expando<
        List<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>>
      >();

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context,
    String text,
    DayzToastTone tone, [
    DayzToastAction? action,
  ]) {
    final colors = context.dayz;
    final messenger = ScaffoldMessenger.of(context);
    final pending = _pendingSnackBars[messenger] ??= [];

    if (pending.length >= _maxPendingSnackBars) {
      messenger.removeCurrentSnackBar();
      pending.removeAt(0);
    }

    final duration = action == null ? shortDuration : actionDuration;
    final motionDuration = dayzMotionDuration(context, DayzMotion.dur);
    final iconColor = _toneColor(colors, tone);
    final icon = _toneIcon(tone);

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.ink,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(
        DayzSpacing.s4,
        0,
        DayzSpacing.s4,
        DayzSpacing.s4,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: DayzSpacing.s4,
        vertical: DayzSpacing.s3,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DayzRadii.md),
      ),
      duration: duration,
      dismissDirection: DismissDirection.down,
      content: Semantics(
        liveRegion: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: action == null ? messenger.hideCurrentSnackBar : null,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                icon,
                key: const ValueKey('dayz-toast-icon'),
                color: iconColor,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.bg,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      action: action == null
          ? null
          : SnackBarAction(
              label: action.label,
              textColor: colors.accent,
              onPressed: action.onPressed,
            ),
    );

    final controller = messenger.showSnackBar(
      snackBar,
      snackBarAnimationStyle: motionDuration == Duration.zero
          ? AnimationStyle.noAnimation
          : AnimationStyle(
              duration: motionDuration,
              reverseDuration: motionDuration,
            ),
    );

    pending.add(controller);
    unawaited(
      controller.closed.whenComplete(() {
        pending.remove(controller);
      }),
    );

    return controller;
  }

  static Color _toneColor(DayzColors colors, DayzToastTone tone) {
    return switch (tone) {
      DayzToastTone.defaultTone ||
      DayzToastTone.ok ||
      DayzToastTone.info => colors.accent,
      DayzToastTone.danger => colors.danger,
      DayzToastTone.fav => colors.favorite,
    };
  }

  static IconData _toneIcon(DayzToastTone tone) {
    return switch (tone) {
      DayzToastTone.ok => Icons.check_circle_rounded,
      DayzToastTone.danger => Icons.error_rounded,
      DayzToastTone.fav => Icons.star_rounded,
      DayzToastTone.info || DayzToastTone.defaultTone => Icons.info_rounded,
    };
  }
}
