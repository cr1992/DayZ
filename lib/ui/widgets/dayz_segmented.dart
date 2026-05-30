// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';
import '../util/dayz_motion.dart';

/// A single segment in [DayzSegmented].
///
/// Author: @Ray
class DayzSegment<T> {
  const DayzSegment({
    required this.value,
    required this.child,
    this.semanticLabel,
    this.enabled = true,
  });

  final T value;
  final Widget child;
  final String? semanticLabel;
  final bool enabled;
}

/// Token-driven segmented control.
///
/// Author: @Ray
class DayzSegmented<T> extends StatelessWidget {
  const DayzSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final List<DayzSegment<T>> segments;
  final T value;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg2,
        borderRadius: BorderRadius.circular(DayzRadii.full),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              _DayzSegmentButton<T>(
                segment: segments[i],
                selected: segments[i].value == value,
                enabled: onChanged != null && segments[i].enabled,
                onTap: () => onChanged?.call(segments[i].value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayzSegmentButton<T> extends StatelessWidget {
  const _DayzSegmentButton({
    required this.segment,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final DayzSegment<T> segment;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final duration = dayzMotionDuration(context);
    final radius = BorderRadius.circular(DayzRadii.full);

    final content = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? colors.surface : Colors.transparent,
        borderRadius: radius,
        boxShadow: selected ? colors.shadowSm : const [],
      ),
      child: Center(
        child: DefaultTextStyle.merge(
          style: text.body.copyWith(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? colors.ink : colors.ink2,
            height: 1,
          ),
          child: segment.child,
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: segment.semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? onTap : null,
          child: content,
        ),
      ),
    );
  }
}
