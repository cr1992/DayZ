// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_fonts.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';

/// Builds the AppFlowy [EditorStyle] from DayZ design tokens.
///
/// Author: @Ray
EditorStyle dayzEditorStyle(BuildContext context) {
  final colors = context.dayz;
  final text = context.dayzText;
  final diary = text.diary.copyWith(color: colors.ink);

  return EditorStyle.mobile(
    padding: EdgeInsets.zero,
    cursorColor: colors.accent,
    dragHandleColor: colors.accent,
    selectionColor: colors.accentSoft2,
    textStyleConfiguration: TextStyleConfiguration(
      text: diary,
      bold: const TextStyle(fontWeight: FontWeight.w700),
      italic: const TextStyle(fontStyle: FontStyle.italic),
      underline: const TextStyle(decoration: TextDecoration.underline),
      strikethrough: const TextStyle(decoration: TextDecoration.lineThrough),
      href: TextStyle(
        color: colors.accent,
        decoration: TextDecoration.underline,
      ),
      code: text.body.copyWith(
        fontFamily: DayzFonts.mono,
        fontFamilyFallback: DayzFonts.monoFallback,
        color: colors.ink,
        backgroundColor: colors.accentSoft,
      ),
      autoComplete: diary.copyWith(color: colors.ink4),
      lineHeight: diary.height ?? 1.85,
      leadingDistribution:
          diary.leadingDistribution ?? TextLeadingDistribution.even,
    ),
  );
}
