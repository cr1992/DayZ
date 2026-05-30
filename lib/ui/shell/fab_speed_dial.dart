// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/strings/app_strings.dart';
import 'package:dayz/ui/widgets/dayz_icons.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';

/// Custom Floating Action Button with tap-to-write and long-press-to-expand.
///
/// Author: @Ray
class FabSpeedDial extends StatefulWidget {
  const FabSpeedDial({super.key});

  @override
  State<FabSpeedDial> createState() => _FabSpeedDialState();
}

class _FabSpeedDialState extends State<FabSpeedDial> {
  Timer? _longPressTimer;
  bool _isLongPressed = false;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _closeMenu();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _isLongPressed = false;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(milliseconds: 340), () {
      _isLongPressed = true;
      _openMenu();
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isLongPressed) {
      _longPressTimer?.cancel();
      _longPressTimer = null;
      // Light tap -> Navigate directly to editor
      context.pushNamed(Routes.editor);
    }
  }

  void _handleTapCancel() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  void _openMenu() {
    if (_overlayEntry != null) return;

    final overlayState = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => _FabMenuOverlay(
        fabSize: size,
        fabOffset: offset,
        onClose: _closeMenu,
        onAction: (actionType) {
          _closeMenu();
          context.pushNamed(
            Routes.editor,
            queryParameters: {'type': actionType},
          );
        },
      ),
    );

    overlayState.insert(_overlayEntry!);
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Semantics(
        button: true,
        label: AppStrings.edit,
        child: SizedBox.square(
          dimension: 56,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: colors.fabGradient,
              boxShadow: colors.shadowMd,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Center(
              child: SvgPicture.string(
                _svg(DayzIcons.plusPath),
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(colors.onAccent, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _svg(String path) {
    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg"><path d="$path"/></svg>';
  }
}

class _FabMenuOverlay extends StatefulWidget {
  final Size fabSize;
  final Offset fabOffset;
  final VoidCallback onClose;
  final ValueChanged<String> onAction;

  const _FabMenuOverlay({
    required this.fabSize,
    required this.fabOffset,
    required this.onClose,
    required this.onAction,
  });

  @override
  State<_FabMenuOverlay> createState() => _FabMenuOverlayState();
}

class _FabMenuOverlayState extends State<_FabMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: DayzMotion.dur,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _slideAnimation = Tween<double>(
      begin: 10.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    _animController.duration = disableAnimations
        ? Duration.zero
        : DayzMotion.dur;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleClose() async {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      widget.onClose();
    } else {
      await _animController.reverse();
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final textTheme = context.dayzText;

    // We align secondary buttons exactly above the original FAB offset
    final double fabTopY = widget.fabOffset.dy;

    final actions = [
      _ActionItem(
        label: AppStrings.plainText,
        iconPath: DayzIcons.plusPath,
        type: 'text',
      ),
      _ActionItem(
        label: AppStrings.voice,
        iconPath: DayzIcons.micPath,
        type: 'voice',
      ),
      _ActionItem(
        label: AppStrings.camera,
        iconPath: DayzIcons.imagePath,
        type: 'camera',
      ),
    ];

    return Stack(
      children: [
        // 1. Scrim barrier
        GestureDetector(
          onTap: _handleClose,
          child: Semantics(
            label: AppStrings.close,
            button: true,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, _) {
                return Container(
                  color: colors.overlay.withValues(
                    alpha: colors.overlay.a * _fadeAnimation.value,
                  ),
                );
              },
            ),
          ),
        ),

        // 2. Action buttons list
        Positioned(
          bottom: MediaQuery.of(context).size.height - fabTopY + DayzSpacing.s3,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: Opacity(opacity: _fadeAnimation.value, child: child),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: actions.asMap().entries.map((entry) {
                final action = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: DayzSpacing.s2),
                  child: Semantics(
                    button: true,
                    label: action.label,
                    child: ExcludeSemantics(
                      child: GestureDetector(
                        onTap: () => widget.onAction(action.type),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Text label bubble
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DayzSpacing.s3,
                                vertical: DayzSpacing.s1 + 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(
                                  DayzRadii.md,
                                ),
                                boxShadow: colors.shadowSm,
                              ),
                              child: Text(
                                action.label,
                                style: textTheme.body.copyWith(
                                  color: colors.ink,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: DayzSpacing.s2),
                            // Rounded icon button
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.surface,
                                boxShadow: colors.shadowSm,
                                border: Border.all(
                                  color: colors.hairline,
                                  width: 0.5,
                                ),
                              ),
                              child: Center(
                                child: SvgPicture.string(
                                  _svg(action.iconPath),
                                  width: 20,
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                    colors.accent,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // 3. Mirror the original FAB on top of the overlay (without triggering overlay actions)
        Positioned(
          left: widget.fabOffset.dx,
          top: widget.fabOffset.dy,
          width: widget.fabSize.width,
          height: widget.fabSize.height,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity:
                      1.0 -
                      _fadeAnimation.value *
                          0.3, // Dim the original FAB slightly
                  child: child,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: colors.fabGradient,
                  boxShadow: colors.shadowMd,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: SvgPicture.string(
                    _svg(DayzIcons.plusPath),
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      colors.onAccent,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _svg(String path) {
    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg"><path d="$path"/></svg>';
  }
}

class _ActionItem {
  final String label;
  final String iconPath;
  final String type;

  _ActionItem({
    required this.label,
    required this.iconPath,
    required this.type,
  });
}
