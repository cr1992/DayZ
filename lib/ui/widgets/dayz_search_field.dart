// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import 'package:dayz/l10n/gen/app_localizations.dart';
import '../theme/dayz_colors.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';
import 'dayz_icon.dart';
import 'dayz_icons.dart';

/// Search header input skeleton with search, clear, and cancel affordances.
///
/// Author: @Ray
class DayzSearchField extends StatefulWidget {
  const DayzSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onCancel,
    this.autofocus = false,
    this.enabled = true,
  });

  static const Key inputKey = ValueKey<String>('dayz-search-field-input');
  static const Key clearButtonKey = ValueKey<String>('dayz-search-field-clear');
  static const Key cancelButtonKey = ValueKey<String>(
    'dayz-search-field-cancel',
  );

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onCancel;
  final bool autofocus;
  final bool enabled;

  @override
  State<DayzSearchField> createState() => _DayzSearchFieldState();
}

class _DayzSearchFieldState extends State<DayzSearchField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(DayzSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_onTextChanged);
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.dayz;
    final typography = context.dayzText;
    final hasQuery = _controller.text.isNotEmpty;
    final effectiveHintText = widget.hintText ?? l10n.search;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DayzSpacing.s4,
        DayzSpacing.s2,
        DayzSpacing.s4,
        DayzSpacing.s3,
      ),
      child: Row(
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.bg2,
                  borderRadius: BorderRadius.circular(DayzRadii.full),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DayzSpacing.s4,
                  ),
                  child: Row(
                    children: [
                      DayzIcon.path(
                        DayzIcons.searchPath,
                        size: 18,
                        color: colors.ink3,
                      ),
                      const SizedBox(width: DayzSpacing.s2),
                      Expanded(
                        child: TextField(
                          key: DayzSearchField.inputKey,
                          controller: _controller,
                          focusNode: widget.focusNode,
                          autofocus: widget.autofocus,
                          enabled: widget.enabled,
                          onChanged: widget.onChanged,
                          onSubmitted: widget.onSubmitted,
                          textInputAction: TextInputAction.search,
                          cursorColor: colors.accent,
                          style: typography.body.copyWith(
                            color: colors.ink,
                            fontSize: 15,
                            letterSpacing: 0,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: effectiveHintText,
                            hintStyle: typography.body.copyWith(
                              color: colors.ink3,
                              fontSize: 15,
                              letterSpacing: 0,
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (hasQuery)
                        IconButton(
                          key: DayzSearchField.clearButtonKey,
                          onPressed: widget.enabled ? _clear : null,
                          tooltip: l10n.clear,
                          constraints: const BoxConstraints.tightFor(
                            width: 44,
                            height: 44,
                          ),
                          padding: EdgeInsets.zero,
                          icon: DayzIcon.path(
                            DayzIcons.closePath,
                            size: 18,
                            color: colors.ink3,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.onCancel != null) ...[
            const SizedBox(width: DayzSpacing.s2),
            TextButton(
              key: DayzSearchField.cancelButtonKey,
              onPressed: widget.enabled ? widget.onCancel : null,
              style: TextButton.styleFrom(
                foregroundColor: colors.accentInk,
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: DayzSpacing.s2),
                textStyle: typography.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              child: Text(l10n.cancel),
            ),
          ],
        ],
      ),
    );
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }
}
