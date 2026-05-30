// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';

/// Built-in face drawings for [DayzMoodChip].
///
/// Author: @Ray
enum DayzMoodFace { happy, calm, neutral, sad }

/// Token-driven mood chip with a hand-drawn vector face.
///
/// Author: @Ray
class DayzMoodChip extends StatelessWidget {
  const DayzMoodChip({
    super.key,
    required this.label,
    this.face = DayzMoodFace.happy,
    this.selected = false,
    this.onTap,
    this.semanticLabel,
  });

  final String label;
  final DayzMoodFace face;
  final bool selected;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final foreground = selected ? colors.accentInk : colors.ink2;

    final chip = SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DayzRadii.full),
              border: Border.all(
                color: selected ? colors.accent : colors.hairline,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: colors.accentRing,
                        blurRadius: 0,
                        spreadRadius: 3,
                      ),
                    ]
                  : const [],
            ),
            child: Center(
              child: CustomPaint(
                size: const Size.square(26),
                painter: _DayzMoodFacePainter(color: foreground, face: face),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: text.caption.copyWith(fontSize: 12, color: colors.ink2),
          ),
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticLabel ?? label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: chip,
      ),
    );
  }
}

class _DayzMoodFacePainter extends CustomPainter {
  const _DayzMoodFacePainter({required this.color, required this.face});

  final Color color;
  final DayzMoodFace face;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.38),
      0.75,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.38),
      0.75,
      paint,
    );

    final mouth = Path();
    switch (face) {
      case DayzMoodFace.happy:
        mouth.moveTo(size.width * 0.28, size.height * 0.58);
        mouth.quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.78,
          size.width * 0.72,
          size.height * 0.58,
        );
        break;
      case DayzMoodFace.calm:
        mouth.moveTo(size.width * 0.32, size.height * 0.62);
        mouth.quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.69,
          size.width * 0.68,
          size.height * 0.62,
        );
        break;
      case DayzMoodFace.neutral:
        mouth.moveTo(size.width * 0.33, size.height * 0.64);
        mouth.lineTo(size.width * 0.67, size.height * 0.64);
        break;
      case DayzMoodFace.sad:
        mouth.moveTo(size.width * 0.3, size.height * 0.72);
        mouth.quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.55,
          size.width * 0.7,
          size.height * 0.72,
        );
        break;
    }
    canvas.drawPath(mouth, paint);
  }

  @override
  bool shouldRepaint(_DayzMoodFacePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.face != face;
  }
}
