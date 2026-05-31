// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';

import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';
import '../util/dayz_motion.dart';

/// DayZ option indicator types.
///
/// Author: @Ray
enum DayzOptionType { checkbox, radio }

/// Token-driven checkbox/radio option row.
///
/// Author: @Ray
class DayzOption extends StatelessWidget {
  const DayzOption({
    super.key,
    required this.child,
    required this.selected,
    this.onTap,
    this.type = DayzOptionType.checkbox,
    this.semanticLabel,
  });

  const DayzOption.checkbox({
    super.key,
    required this.child,
    required this.selected,
    this.onTap,
    this.semanticLabel,
  }) : type = DayzOptionType.checkbox;

  const DayzOption.radio({
    super.key,
    required this.child,
    required this.selected,
    this.onTap,
    this.semanticLabel,
  }) : type = DayzOptionType.radio;

  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  final DayzOptionType type;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final l10n = AppLocalizations.of(context);
    final text = context.dayzText;
    final duration = dayzMotionDuration(context);
    final label = semanticLabel ?? (selected ? l10n.selected : l10n.unselected);

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DayzOptionIndicator(
            selected: selected,
            type: type,
            colors: colors,
            duration: duration,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: DefaultTextStyle.merge(
              style: text.body.copyWith(fontSize: 15, color: colors.ink),
              child: child,
            ),
          ),
        ],
      ),
    );

    Widget option = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DayzRadii.sm),
        onTap: onTap,
        child: row,
      ),
    );

    if (semanticLabel != null) {
      option = ExcludeSemantics(child: option);
    }

    return Semantics(
      container: true,
      button: true,
      checked: selected,
      enabled: onTap != null,
      label: label,
      child: option,
    );
  }
}

class _DayzOptionIndicator extends StatelessWidget {
  const _DayzOptionIndicator({
    required this.selected,
    required this.type,
    required this.colors,
    required this.duration,
  });

  final bool selected;
  final DayzOptionType type;
  final DayzColors colors;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final isCheckbox = type == DayzOptionType.checkbox;

    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      width: 21,
      height: 21,
      decoration: BoxDecoration(
        color: selected && isCheckbox ? colors.accent : Colors.transparent,
        border: Border.all(
          color: selected ? colors.accent : colors.hairline2,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(
          isCheckbox ? DayzRadii.xs : DayzRadii.full,
        ),
      ),
      child: selected
          ? Center(
              child: isCheckbox
                  ? CustomPaint(
                      size: const Size(9, 12),
                      painter: _DayzCheckPainter(color: Colors.white),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: BorderRadius.circular(DayzRadii.full),
                      ),
                      child: const SizedBox.square(dimension: 11),
                    ),
            )
          : null,
    );
  }
}

class _DayzCheckPainter extends CustomPainter {
  const _DayzCheckPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.82)
      ..lineTo(size.width * 0.9, size.height * 0.18);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DayzCheckPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
