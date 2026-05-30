// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';
import '../util/dayz_motion.dart';

/// Token-driven DayZ input field and textarea wrapper.
///
/// Author: @Ray
class DayzTextField extends StatefulWidget {
  const DayzTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.helpText,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxWidth = 340,
    this.autofocus = false,
  });

  const DayzTextField.textarea({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.helpText,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.minLines = 4,
    this.maxLines,
    this.maxWidth = 340,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? helpText;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final int minLines;
  final int? maxLines;
  final double? maxWidth;
  final bool autofocus;

  @override
  State<DayzTextField> createState() => _DayzTextFieldState();
}

class _DayzTextFieldState extends State<DayzTextField> {
  late final FocusNode _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(DayzTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode).removeListener(
        _handleFocusChanged,
      );
      _focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _internalFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final duration = dayzMotionDuration(context);
    final radius = BorderRadius.circular(DayzRadii.sm);
    final isTextarea = widget.maxLines != 1 || widget.minLines > 1;
    final borderColor = !widget.enabled
        ? colors.hairline
        : _focusNode.hasFocus
        ? colors.accent
        : colors.hairline2;

    final field = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      constraints: BoxConstraints(minHeight: isTextarea ? 92 : 44),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: borderColor),
        borderRadius: radius,
        boxShadow: _focusNode.hasFocus
            ? [
                BoxShadow(
                  color: colors.accentRing,
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ]
            : const [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        obscureText: widget.obscureText,
        textAlignVertical: isTextarea
            ? TextAlignVertical.top
            : TextAlignVertical.center,
        minLines: widget.minLines,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        cursorColor: colors.accent,
        style: text.body.copyWith(
          fontSize: 15,
          color: colors.ink,
          height: isTextarea ? 1.6 : 1.2,
        ),
        strutStyle: isTextarea
            ? const StrutStyle(fontSize: 15, height: 1.6)
            : const StrutStyle(fontSize: 15, height: 1.2),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          constraints: BoxConstraints(minHeight: isTextarea ? 92 : 44),
          hintText: widget.hintText,
          hintStyle: text.body.copyWith(
            fontSize: 15,
            color: colors.ink3,
            height: isTextarea ? 1.6 : 1.2,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
        ),
      ),
    );

    final children = <Widget>[
      if (widget.label != null)
        Text(
          widget.label!,
          style: text.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.ink2,
            height: 1.25,
          ),
        ),
      field,
      if (widget.helpText != null)
        Text(
          widget.helpText!,
          style: text.caption.copyWith(fontSize: 12, color: colors.ink3),
        ),
    ];

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 7),
          children[i],
        ],
      ],
    );

    if (widget.maxWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth!),
        child: content,
      );
    }

    return content;
  }
}
