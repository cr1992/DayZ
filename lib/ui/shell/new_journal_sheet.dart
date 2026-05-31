// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/widgets/dayz_icons.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';

/// Predefined colors for new journals (3 theme colors + 3 extension colors).
const List<String> kJournalColorPalette = [
  '#786CAD', // 紫色
  '#5C8A68', // 绿色
  '#C8993E', // 黄色
  '#B05C77', // 玫瑰红/粉红色
  '#4F86A8', // 蓝灰色
  '#9A6A4B', // 棕色/咖啡色
];

/// Displays the bottom sheet form for creating a new journal.
///
/// Author: @Ray
void showNewJournalSheet(
  BuildContext context, {
  required void Function(String name, String color) onSubmit,
}) {
  final disableAnimations = MediaQuery.disableAnimationsOf(context);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    sheetAnimationStyle: disableAnimations ? AnimationStyle.noAnimation : null,
    backgroundColor: context.dayz.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(DayzRadii.lg)),
    ),
    builder: (context) {
      return SafeArea(top: false, child: _NewJournalSheet(onSubmit: onSubmit));
    },
  );
}

class _NewJournalSheet extends StatefulWidget {
  final void Function(String name, String color) onSubmit;

  const _NewJournalSheet({required this.onSubmit});

  @override
  State<_NewJournalSheet> createState() => _NewJournalSheetState();
}

class _NewJournalSheetState extends State<_NewJournalSheet> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _selectedColor = kJournalColorPalette.first;
  bool _canSubmit = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateSubmitState);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _updateSubmitState() {
    final hasName = _nameController.text.trim().isNotEmpty;
    if (_canSubmit != hasName) {
      setState(() {
        _canSubmit = hasName;
      });
    }
  }

  Color _parseColor(String hex) {
    final cleanHex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleanHex', radix: 16));
  }

  String _svg(String path) {
    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg"><path d="$path"/></svg>';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final textTheme = context.dayzText;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: DayzSpacing.s4,
        right: DayzSpacing.s4,
        bottom: MediaQuery.of(context).viewInsets.bottom + DayzSpacing.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Centered Title
          Align(
            alignment: Alignment.center,
            child: Text(
              l10n.newJournal,
              style: textTheme.h3.copyWith(
                color: colors.ink,
                fontSize: 17.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: DayzSpacing.s4),

          // Name Input Field
          Text(
            l10n.journalNameLabel,
            style: textTheme.overline.copyWith(color: colors.ink2),
          ),
          const SizedBox(height: DayzSpacing.s1),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DayzRadii.sm),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: colors.accentRing,
                        spreadRadius: 4.0,
                        blurRadius: 0.0,
                      ),
                    ]
                  : [],
            ),
            child: TextField(
              controller: _nameController,
              focusNode: _focusNode,
              autofocus: true,
              style: textTheme.body.copyWith(color: colors.ink, fontSize: 15.0),
              decoration: InputDecoration(
                hintText: l10n.journalNameInputPlaceholder,
                hintStyle: textTheme.body.copyWith(color: colors.ink3, fontSize: 15.0),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 11.0,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DayzRadii.sm),
                  borderSide: BorderSide(color: colors.hairline2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DayzRadii.sm),
                  borderSide: BorderSide(color: colors.accent, width: 1.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: DayzSpacing.s4),

          // Color Selector Title
          Text(
            l10n.journalColorLabel,
            style: textTheme.overline.copyWith(color: colors.ink2),
          ),
          const SizedBox(height: DayzSpacing.s2),

          // Color Palette Selectors with 12px gap
          Wrap(
            spacing: 12.0,
            runSpacing: 8.0,
            children: kJournalColorPalette.map((colorHex) {
              final color = _parseColor(colorHex);
              final isSelected = _selectedColor == colorHex;

              return Semantics(
                button: true,
                selected: isSelected,
                label: colorHex,
                child: ExcludeSemantics(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = colorHex;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: color, width: 2.0)
                            : Border.all(color: Colors.transparent, width: 2.0),
                      ),
                      padding: const EdgeInsets.all(3.0),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: isSelected
                              ? Border.all(color: colors.surface, width: 2.0)
                              : null,
                        ),
                        child: isSelected
                            ? Center(
                                child: SvgPicture.string(
                                  _svg(DayzIcons.checkPath),
                                  width: 13,
                                  height: 13,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: DayzSpacing.s5),

          // Single Full Width Rounded Primary Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmit
                  ? () {
                      widget.onSubmit(
                        _nameController.text.trim(),
                        _selectedColor,
                      );
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                disabledBackgroundColor: colors.hairline,
                padding: const EdgeInsets.symmetric(
                  vertical: DayzSpacing.s3 + 2.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DayzRadii.full),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.sheetCreate,
                style: textTheme.body.copyWith(
                  color: _canSubmit ? colors.onAccent : colors.ink3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
