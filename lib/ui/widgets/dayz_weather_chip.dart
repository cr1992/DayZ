// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';

/// Built-in weather glyphs for [DayzWeatherChip].
///
/// Author: @Ray
enum DayzWeatherGlyph { sun, cloud, rain, snow, wind }

/// Token-driven weather chip.
///
/// Author: @Ray
class DayzWeatherChip extends StatelessWidget {
  const DayzWeatherChip({
    super.key,
    required this.label,
    this.glyph = DayzWeatherGlyph.sun,
    this.onTap,
    this.semanticLabel,
  });

  final String label;
  final DayzWeatherGlyph glyph;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final interactive = onTap != null;
    final radius = BorderRadius.circular(DayzRadii.full);

    Widget chip = ConstrainedBox(
      constraints: BoxConstraints(minHeight: interactive ? 44 : 34),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface2,
          border: Border.all(color: colors.hairline),
          borderRadius: radius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: CustomPaint(
                  size: const Size.square(17),
                  painter: _DayzWeatherPainter(
                    color: colors.accent,
                    glyph: glyph,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.caption.copyWith(
                    fontSize: 13,
                    color: colors.ink2,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (interactive) {
      chip = Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: radius, onTap: onTap, child: chip),
      );
    }

    return Semantics(
      button: interactive,
      label: semanticLabel ?? label,
      child: chip,
    );
  }
}

class _DayzWeatherPainter extends CustomPainter {
  const _DayzWeatherPainter({required this.color, required this.glyph});

  final Color color;
  final DayzWeatherGlyph glyph;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;

    switch (glyph) {
      case DayzWeatherGlyph.sun:
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.22, paint);
        for (final line in <(Offset, Offset)>[
          (Offset(w * 0.5, h * 0.04), Offset(w * 0.5, h * 0.18)),
          (Offset(w * 0.5, h * 0.82), Offset(w * 0.5, h * 0.96)),
          (Offset(w * 0.04, h * 0.5), Offset(w * 0.18, h * 0.5)),
          (Offset(w * 0.82, h * 0.5), Offset(w * 0.96, h * 0.5)),
          (Offset(w * 0.18, h * 0.18), Offset(w * 0.28, h * 0.28)),
          (Offset(w * 0.72, h * 0.72), Offset(w * 0.82, h * 0.82)),
          (Offset(w * 0.82, h * 0.18), Offset(w * 0.72, h * 0.28)),
          (Offset(w * 0.28, h * 0.72), Offset(w * 0.18, h * 0.82)),
        ]) {
          canvas.drawLine(line.$1, line.$2, paint);
        }
        break;
      case DayzWeatherGlyph.cloud:
        _drawCloud(canvas, size, paint);
        break;
      case DayzWeatherGlyph.rain:
        _drawCloud(canvas, size, paint);
        canvas.drawLine(
          Offset(w * 0.36, h * 0.72),
          Offset(w * 0.29, h * 0.92),
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.58, h * 0.72),
          Offset(w * 0.51, h * 0.92),
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.78, h * 0.72),
          Offset(w * 0.71, h * 0.92),
          paint,
        );
        break;
      case DayzWeatherGlyph.snow:
        canvas.drawLine(
          Offset(w * 0.5, h * 0.2),
          Offset(w * 0.5, h * 0.8),
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.24, h * 0.35),
          Offset(w * 0.76, h * 0.65),
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.76, h * 0.35),
          Offset(w * 0.24, h * 0.65),
          paint,
        );
        break;
      case DayzWeatherGlyph.wind:
        final p1 = Path()
          ..moveTo(w * 0.1, h * 0.34)
          ..lineTo(w * 0.64, h * 0.34)
          ..quadraticBezierTo(w * 0.9, h * 0.34, w * 0.78, h * 0.18);
        final p2 = Path()
          ..moveTo(w * 0.16, h * 0.56)
          ..lineTo(w * 0.9, h * 0.56);
        final p3 = Path()
          ..moveTo(w * 0.28, h * 0.76)
          ..lineTo(w * 0.64, h * 0.76)
          ..quadraticBezierTo(w * 0.86, h * 0.76, w * 0.76, h * 0.9);
        canvas.drawPath(p1, paint);
        canvas.drawPath(p2, paint);
        canvas.drawPath(p3, paint);
        break;
    }
  }

  void _drawCloud(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.22, h * 0.68)
      ..quadraticBezierTo(w * 0.1, h * 0.56, w * 0.24, h * 0.46)
      ..quadraticBezierTo(w * 0.32, h * 0.26, w * 0.52, h * 0.37)
      ..quadraticBezierTo(w * 0.72, h * 0.24, w * 0.8, h * 0.48)
      ..quadraticBezierTo(w * 0.96, h * 0.54, w * 0.84, h * 0.68)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DayzWeatherPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.glyph != glyph;
  }
}
