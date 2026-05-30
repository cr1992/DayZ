// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dayz/ui/strings/app_strings.dart';
import 'package:dayz/ui/widgets/dayz_icons.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';

/// Predefined colors for new journals (3 theme colors + 3 extension colors).
const List<String> kJournalColorPalette = [
  '#786CAD', // Purple Accent
  '#C67D33', // Amber Accent
  '#5A8E72', // Sage Accent
  '#4A90E2', // Blue
  '#D0021B', // Red
  '#9B9B9B', // Grey
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
  String _selectedColor = kJournalColorPalette.first;
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateSubmitState);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
          // Title
          Text(
            AppStrings.newJournal,
            style: textTheme.h2.copyWith(color: colors.ink),
          ),
          const SizedBox(height: DayzSpacing.s3),

          // Name Input Field
          Text(
            AppStrings.journalNameLabel,
            style: textTheme.overline.copyWith(color: colors.ink2),
          ),
          const SizedBox(height: DayzSpacing.s1),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: textTheme.body.copyWith(color: colors.ink),
            decoration: InputDecoration(
              hintText: AppStrings.journalNameInputPlaceholder,
              hintStyle: textTheme.body.copyWith(color: colors.ink3),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DayzSpacing.s3,
                vertical: DayzSpacing.s2 + 2.0,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DayzRadii.md),
                borderSide: BorderSide(color: colors.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DayzRadii.md),
                borderSide: BorderSide(color: colors.accent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: DayzSpacing.s4),

          // Color Selector Title
          Text(
            AppStrings.journalColorLabel,
            style: textTheme.overline.copyWith(color: colors.ink2),
          ),
          const SizedBox(height: DayzSpacing.s2),

          // Color Palette Selectors
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: colors.accent, width: 2.0)
                            : null,
                      ),
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                        child: isSelected
                            ? Center(
                                child: SvgPicture.string(
                                  _svg(DayzIcons.checkPath),
                                  width: 16,
                                  height: 16,
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

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: DayzSpacing.s3,
                    ),
                    side: BorderSide(color: colors.hairline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DayzRadii.md),
                    ),
                  ),
                  child: Text(
                    AppStrings.sheetCancel,
                    style: textTheme.body.copyWith(
                      color: colors.ink2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DayzSpacing.s3),
              Expanded(
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
                      vertical: DayzSpacing.s3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DayzRadii.md),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppStrings.sheetConfirm,
                    style: textTheme.body.copyWith(
                      color: _canSubmit ? colors.onAccent : colors.ink3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
