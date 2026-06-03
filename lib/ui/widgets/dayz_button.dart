// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';
import '../util/dayz_motion.dart';

/// Visual variants for [DayzButton].
///
/// Author: @Ray
enum DayzButtonVariant { primary, soft, ghost, text, danger }

/// Size variants for [DayzButton].
///
/// Author: @Ray
enum DayzButtonSize { small, medium, large }

/// Token-driven DayZ button with text, icon, and icon-only forms.
///
/// Author: @Ray
class DayzButton extends StatefulWidget {
  const DayzButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = DayzButtonVariant.primary,
    this.size = DayzButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.semanticLabel,
    this.autofocus = false,
  }) : isIconOnly = false;

  const DayzButton.icon({
    super.key,
    required Widget icon,
    required this.semanticLabel,
    this.onPressed,
    this.variant = DayzButtonVariant.soft,
    this.size = DayzButtonSize.medium,
    this.autofocus = false,
  }) : child = icon,
       leadingIcon = null,
       trailingIcon = null,
       isIconOnly = true;

  final Widget child;
  final VoidCallback? onPressed;
  final DayzButtonVariant variant;
  final DayzButtonSize size;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final String? semanticLabel;
  final bool autofocus;
  final bool isIconOnly;

  @override
  State<DayzButton> createState() => _DayzButtonState();
}

class _DayzButtonState extends State<DayzButton> {
  bool _pressed = false;

  @override
  void didUpdateWidget(DayzButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onPressed == null && _pressed) {
      _pressed = false;
    }
  }

  void _setPressed(bool value) {
    if (_pressed == value || widget.onPressed == null) {
      return;
    }
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final style = _DayzButtonStyle.resolve(
      colors,
      widget.variant,
      widget.onPressed == null,
    );
    final metrics = _DayzButtonMetrics.resolve(
      widget.size,
      widget.isIconOnly,
      widget.variant,
    );
    final radius = BorderRadius.circular(DayzRadii.full);
    final duration = dayzMotionDuration(context);

    final content = IconTheme.merge(
      data: IconThemeData(size: metrics.iconSize, color: style.foreground),
      child: DefaultTextStyle.merge(
        style: context.dayzText.body.copyWith(
          color: style.foreground,
          fontSize: metrics.fontSize,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
        child: _buildContent(metrics),
      ),
    );

    Widget button = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: widget.isIconOnly ? metrics.iconOnlyVisualSize : 44,
        minHeight: metrics.minHeight,
      ),
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _pressed ? 1 : 0, 0),
        decoration: BoxDecoration(
          color: style.background,
          border: Border.all(color: style.border),
          borderRadius: radius,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            autofocus: widget.autofocus,
            borderRadius: radius,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            onTap: widget.onPressed,
            onTapDown: widget.onPressed == null
                ? null
                : (_) => _setPressed(true),
            onTapCancel: widget.onPressed == null
                ? null
                : () => _setPressed(false),
            onTapUp: widget.onPressed == null
                ? null
                : (_) => _setPressed(false),
            child: Padding(padding: metrics.padding, child: content),
          ),
        ),
      ),
    );

    if (widget.isIconOnly) {
      button = Semantics(
        button: true,
        enabled: widget.onPressed != null,
        label: widget.semanticLabel,
        child: ExcludeSemantics(child: button),
      );
    } else if (widget.semanticLabel != null) {
      button = Semantics(
        button: true,
        enabled: widget.onPressed != null,
        label: widget.semanticLabel,
        child: button,
      );
    }

    return button;
  }

  Widget _buildContent(_DayzButtonMetrics metrics) {
    if (widget.isIconOnly) {
      return SizedBox.square(
        dimension: metrics.iconOnlyVisualSize,
        child: Center(child: widget.child),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leadingIcon != null) ...[
          ExcludeSemantics(child: widget.leadingIcon!),
          SizedBox(width: metrics.gap),
        ],
        Flexible(child: widget.child),
        if (widget.trailingIcon != null) ...[
          SizedBox(width: metrics.gap),
          ExcludeSemantics(child: widget.trailingIcon!),
        ],
      ],
    );
  }
}

class _DayzButtonMetrics {
  const _DayzButtonMetrics({
    required this.padding,
    required this.fontSize,
    required this.iconSize,
    required this.gap,
    required this.iconOnlyVisualSize,
    required this.minHeight,
  });

  final EdgeInsetsGeometry padding;
  final double fontSize;
  final double iconSize;
  final double gap;
  final double iconOnlyVisualSize;
  final double minHeight;

  static _DayzButtonMetrics resolve(
    DayzButtonSize size,
    bool iconOnly,
    DayzButtonVariant variant,
  ) {
    if (iconOnly) {
      return const _DayzButtonMetrics(
        padding: EdgeInsets.zero,
        fontSize: 15,
        iconSize: 20,
        gap: DayzSpacing.s2,
        iconOnlyVisualSize: 40,
        minHeight: 40,
      );
    }

    final textHorizontal = variant == DayzButtonVariant.text ? 8.0 : null;
    switch (size) {
      case DayzButtonSize.small:
        return _DayzButtonMetrics(
          padding: EdgeInsets.symmetric(
            horizontal: textHorizontal ?? 14,
            vertical: 8,
          ),
          fontSize: 13,
          iconSize: 17,
          gap: DayzSpacing.s2,
          iconOnlyVisualSize: 40,
          minHeight: 30,
        );
      case DayzButtonSize.medium:
        return _DayzButtonMetrics(
          padding: EdgeInsets.symmetric(
            horizontal: textHorizontal ?? 20,
            vertical: 11,
          ),
          fontSize: 15,
          iconSize: 18,
          gap: DayzSpacing.s2,
          iconOnlyVisualSize: 40,
          minHeight: 38,
        );
      case DayzButtonSize.large:
        return _DayzButtonMetrics(
          padding: EdgeInsets.symmetric(
            horizontal: textHorizontal ?? 26,
            vertical: 14,
          ),
          fontSize: 16,
          iconSize: 20,
          gap: DayzSpacing.s2,
          iconOnlyVisualSize: 40,
          minHeight: 44,
        );
    }
  }
}

class _DayzButtonStyle {
  const _DayzButtonStyle({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;

  static _DayzButtonStyle resolve(
    DayzColors colors,
    DayzButtonVariant variant,
    bool disabled,
  ) {
    if (disabled) {
      return _DayzButtonStyle(
        background: colors.bg2,
        foreground: colors.ink4,
        border: Colors.transparent,
      );
    }

    switch (variant) {
      case DayzButtonVariant.primary:
        return _DayzButtonStyle(
          background: colors.accent,
          foreground: colors.onAccent,
          border: Colors.transparent,
        );
      case DayzButtonVariant.soft:
        return _DayzButtonStyle(
          background: colors.accentSoft,
          foreground: colors.accentInk,
          border: Colors.transparent,
        );
      case DayzButtonVariant.ghost:
        return _DayzButtonStyle(
          background: Colors.transparent,
          foreground: colors.accentInk,
          border: colors.hairline2,
        );
      case DayzButtonVariant.text:
        return _DayzButtonStyle(
          background: Colors.transparent,
          foreground: colors.accentInk,
          border: Colors.transparent,
        );
      case DayzButtonVariant.danger:
        return _DayzButtonStyle(
          background: Colors.transparent,
          foreground: colors.danger,
          border: colors.danger.withValues(alpha: 0.4),
        );
    }
  }
}
