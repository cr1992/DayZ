// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../strings/app_strings.dart';
import '../theme/dayz_colors.dart';
import '../theme/dayz_tokens.g.dart';
import '../util/dayz_motion.dart';
import '../widgets/dayz_button.dart';

/// Semantic tone for bottom sheet items and actions.
///
/// Author: @Ray
enum DayzSheetTone { defaultTone, accent, danger, favorite }

/// Action model used by [DayzSheet.form].
///
/// Author: @Ray
class DayzSheetAction {
  const DayzSheetAction({
    required this.label,
    this.onPressed,
    this.tone = DayzSheetTone.accent,
    this.keepOpen = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final DayzSheetTone tone;
  final bool keepOpen;
}

/// Item model used by action and picker sheets.
///
/// Author: @Ray
class DayzSheetItem {
  const DayzSheetItem({
    required this.label,
    this.desc,
    this.icon,
    this.swatch,
    this.tone = DayzSheetTone.defaultTone,
    this.selected = false,
    this.keepOpen = false,
    this.onTap,
    this.sep = false,
  });

  const DayzSheetItem.sep()
    : label = '',
      desc = null,
      icon = null,
      swatch = null,
      tone = DayzSheetTone.defaultTone,
      selected = false,
      keepOpen = false,
      onTap = null,
      sep = true;

  final String label;
  final String? desc;
  final IconData? icon;
  final Color? swatch;
  final DayzSheetTone tone;
  final bool selected;
  final bool keepOpen;
  final VoidCallback? onTap;
  final bool sep;
}

/// DayZ bottom sheet entry points.
///
/// Author: @Ray
abstract final class DayzSheet {
  static Future<T?> actions<T>(
    BuildContext context, {
    required List<DayzSheetItem> items,
    String cancelLabel = AppStrings.sheetCancel,
  }) {
    return _show<T>(
      context,
      _DayzSheetItems(
        items: items,
        showSelectedCheck: false,
        cancelLabel: cancelLabel,
      ),
    );
  }

  static Future<T?> picker<T>(
    BuildContext context, {
    required List<DayzSheetItem> items,
  }) {
    return _show<T>(
      context,
      _DayzSheetItems(items: items, showSelectedCheck: true),
    );
  }

  static Future<T?> form<T>(
    BuildContext context, {
    required Widget content,
    required DayzSheetAction primary,
    DayzSheetAction? secondary,
  }) {
    return _show<T>(
      context,
      _DayzSheetForm(content: content, primary: primary, secondary: secondary),
    );
  }

  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    String? desc,
    String primaryLabel = AppStrings.sheetConfirm,
    String cancelLabel = AppStrings.sheetCancel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool keepOpen = false,
  }) {
    return _show<bool>(
      context,
      _DayzSheetConfirm(
        title: title,
        desc: desc,
        primary: DayzSheetAction(
          label: primaryLabel,
          onPressed: onConfirm,
          tone: DayzSheetTone.danger,
          keepOpen: keepOpen,
        ),
        cancel: DayzSheetAction(label: cancelLabel, onPressed: onCancel),
      ),
    );
  }

  static Future<T?> _show<T>(BuildContext context, Widget child) {
    final colors = context.dayz;
    final duration = dayzMotionDuration(context, DayzMotion.dur);

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: false,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: colors.overlay,
      sheetAnimationStyle: duration == Duration.zero
          ? AnimationStyle.noAnimation
          : AnimationStyle(duration: duration, reverseDuration: duration),
      builder: (_) => _DayzSheetFrame(child: child),
    );
  }
}

class _DayzSheetFrame extends StatelessWidget {
  const _DayzSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Material(
      key: const ValueKey('dayz-sheet-frame'),
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DayzRadii.xl),
        ),
        side: BorderSide(color: colors.hairline),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: DayzSpacing.s2),
        child: SizedBox(
          width: double.infinity,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _DayzSheetHandle(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: DayzSpacing.s2),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayzSheetHandle extends StatelessWidget {
  const _DayzSheetHandle();

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;

    return Padding(
      padding: const EdgeInsets.only(
        top: DayzSpacing.s3,
        bottom: DayzSpacing.s2,
      ),
      child: Center(
        child: SizedBox(
          key: const ValueKey('dayz-sheet-handle'),
          width: 36,
          height: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.hairline2,
              borderRadius: BorderRadius.circular(DayzRadii.full),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayzSheetItems extends StatelessWidget {
  const _DayzSheetItems({
    required this.items,
    required this.showSelectedCheck,
    this.cancelLabel,
  });

  final List<DayzSheetItem> items;
  final bool showSelectedCheck;
  final String? cancelLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final hasCancel = cancelLabel != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DayzSpacing.s3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in items)
            item.sep
                ? Divider(
                    height: DayzSpacing.s2,
                    thickness: 1,
                    color: colors.hairline,
                  )
                : _DayzSheetItemTile(
                    item: item,
                    showSelectedCheck: showSelectedCheck,
                  ),
          if (hasCancel) ...[
            const SizedBox(height: DayzSpacing.s2), // margin-top: 8px
            _DayzSheetCancelButton(
              label: cancelLabel!,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayzSheetCancelButton extends StatelessWidget {
  const _DayzSheetCancelButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;

    return Semantics(
      container: true,
      button: true,
      enabled: true,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: colors.bg2, // var(--bg-2)
          borderRadius: BorderRadius.circular(DayzRadii.md), // var(--r-md)
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14), // padding: 14px
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: colors.ink, // var(--ink)
                  fontSize: 15.5, // font-size: 15.5px
                  fontWeight: FontWeight.w600, // font-weight: 600
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayzSheetItemTile extends StatelessWidget {
  const _DayzSheetItemTile({
    required this.item,
    required this.showSelectedCheck,
  });

  final DayzSheetItem item;
  final bool showSelectedCheck;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final itemColor = _toneColor(colors, item.tone);
    final onTap = item.onTap == null ? null : () => _handleTap(context);

    return Semantics(
      container: true,
      button: item.onTap != null,
      enabled: item.onTap != null,
      selected: item.selected,
      label: item.label,
      value: item.selected ? AppStrings.sheetSelected : null,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DayzSpacing.s1),
          child: ConstrainedBox(
            key: ValueKey('dayz-sheet-item-${item.label}'),
            constraints: const BoxConstraints(minHeight: 44),
            child: InkWell(
              borderRadius: BorderRadius.circular(DayzRadii.md),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DayzSpacing.s3,
                  vertical: DayzSpacing.s2,
                ),
                child: Row(
                  children: [
                    _DayzSheetLeading(item: item, color: itemColor),
                    const SizedBox(width: DayzSpacing.s3),
                    Expanded(
                      child: _DayzSheetItemText(item: item, color: itemColor),
                    ),
                    if (showSelectedCheck && item.selected)
                      Icon(
                        Icons.check_rounded,
                        key: ValueKey('dayz-sheet-selected-${item.label}'),
                        color: colors.accent,
                        size: 22,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    item.onTap?.call();

    if (!item.keepOpen) {
      Navigator.of(context).pop();
    }
  }
}

class _DayzSheetLeading extends StatelessWidget {
  const _DayzSheetLeading({required this.item, required this.color});

  final DayzSheetItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (item.swatch != null) {
      return SizedBox.square(
        dimension: 24,
        child: Center(
          child: DecoratedBox(
            key: ValueKey('dayz-sheet-swatch-${item.label}'),
            decoration: BoxDecoration(
              color: item.swatch,
              shape: BoxShape.circle,
              border: Border.all(color: context.dayz.hairline2),
            ),
            child: const SizedBox.square(dimension: 18),
          ),
        ),
      );
    }

    if (item.icon != null) {
      return SizedBox.square(
        dimension: 24,
        child: Icon(item.icon, color: color, size: 22),
      );
    }

    return const SizedBox.square(dimension: 24);
  }
}

class _DayzSheetItemText extends StatelessWidget {
  const _DayzSheetItemText({required this.item, required this.color});

  final DayzSheetItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.label,
          style: textTheme.bodyLarge?.copyWith(
            color: color,
            fontWeight: item.selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        if (item.desc != null) ...[
          const SizedBox(height: DayzSpacing.s1),
          Text(
            item.desc!,
            style: textTheme.bodySmall?.copyWith(color: colors.ink2),
          ),
        ],
      ],
    );
  }
}

class _DayzSheetForm extends StatelessWidget {
  const _DayzSheetForm({
    required this.content,
    required this.primary,
    this.secondary,
  });

  final Widget content;
  final DayzSheetAction primary;
  final DayzSheetAction? secondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DayzSpacing.s4,
        DayzSpacing.s2,
        DayzSpacing.s4,
        DayzSpacing.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          content,
          const SizedBox(height: DayzSpacing.s4),
          _DayzSheetActionButtons(
            primary: primary,
            secondary: secondary,
            primaryKey: const ValueKey('dayz-sheet-form-primary'),
            secondaryKey: const ValueKey('dayz-sheet-form-secondary'),
          ),
        ],
      ),
    );
  }
}

class _DayzSheetConfirm extends StatelessWidget {
  const _DayzSheetConfirm({
    required this.title,
    required this.primary,
    required this.cancel,
    this.desc,
  });

  final String title;
  final String? desc;
  final DayzSheetAction primary;
  final DayzSheetAction cancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DayzSpacing.s4,
        DayzSpacing.s2,
        DayzSpacing.s4,
        DayzSpacing.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (desc != null) ...[
            const SizedBox(height: DayzSpacing.s2),
            Text(
              desc!,
              style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
            ),
          ],
          const SizedBox(height: DayzSpacing.s4),
          _DayzSheetActionButtons(
            primary: primary,
            secondary: cancel,
            primaryResult: true,
            secondaryResult: false,
            primaryKey: const ValueKey('dayz-sheet-confirm-primary'),
            secondaryKey: const ValueKey('dayz-sheet-confirm-cancel'),
          ),
        ],
      ),
    );
  }
}

class _DayzSheetActionButtons extends StatelessWidget {
  const _DayzSheetActionButtons({
    required this.primary,
    required this.primaryKey,
    this.secondary,
    this.primaryResult,
    this.secondaryResult,
    this.secondaryKey,
  });

  final DayzSheetAction primary;
  final DayzSheetAction? secondary;
  final Object? primaryResult;
  final Object? secondaryResult;
  final Key primaryKey;
  final Key? secondaryKey;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (secondary != null)
        Expanded(
          child: _DayzSheetSecondaryButton(
            key: secondaryKey,
            action: secondary!,
            result: secondaryResult,
          ),
        ),
      if (secondary != null) const SizedBox(width: DayzSpacing.s3),
      Expanded(
        child: _DayzSheetPrimaryButton(
          key: primaryKey,
          action: primary,
          result: primaryResult,
        ),
      ),
    ];

    return Row(children: children);
  }
}

class _DayzSheetPrimaryButton extends StatelessWidget {
  const _DayzSheetPrimaryButton({super.key, required this.action, this.result});

  final DayzSheetAction action;
  final Object? result;

  @override
  Widget build(BuildContext context) {
    return DayzButton(
      variant: action.tone == DayzSheetTone.danger
          ? DayzButtonVariant.danger
          : DayzButtonVariant.primary,
      onPressed: () => _handleAction(context, action, result),
      child: Text(action.label),
    );
  }
}

class _DayzSheetSecondaryButton extends StatelessWidget {
  const _DayzSheetSecondaryButton({
    super.key,
    required this.action,
    this.result,
  });

  final DayzSheetAction action;
  final Object? result;

  @override
  Widget build(BuildContext context) {
    return DayzButton(
      variant: action.tone == DayzSheetTone.danger
          ? DayzButtonVariant.danger
          : DayzButtonVariant.ghost,
      onPressed: () => _handleAction(context, action, result),
      child: Text(action.label),
    );
  }
}

void _handleAction(
  BuildContext context,
  DayzSheetAction action,
  Object? result,
) {
  action.onPressed?.call();

  if (!action.keepOpen) {
    Navigator.of(context).pop(result);
  }
}

Color _toneColor(DayzColors colors, DayzSheetTone tone) {
  return switch (tone) {
    DayzSheetTone.defaultTone => colors.ink,
    DayzSheetTone.accent => colors.accent,
    DayzSheetTone.danger => colors.danger,
    DayzSheetTone.favorite => colors.favorite,
  };
}
