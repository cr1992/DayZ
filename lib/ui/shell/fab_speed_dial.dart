// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/shell/app_router.dart';
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
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Semantics(
        button: true,
        label: l10n.edit,
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
    final l10n = AppLocalizations.of(context);

    // We align secondary buttons exactly above the original FAB offset
    final double fabTopY = widget.fabOffset.dy;
    final double fabLeftX = widget.fabOffset.dx;
    final double fabWidth = widget.fabSize.width;

    final actions = [
      _ActionItem(
        label: l10n.plainText,
        iconPath: DayzIcons.plusPath,
        type: 'text',
      ),
      _ActionItem(
        label: l10n.voice,
        iconPath: DayzIcons.micPath,
        type: 'voice',
      ),
      _ActionItem(
        label: l10n.camera,
        iconPath: DayzIcons.imagePath,
        type: 'camera',
      ),
    ];

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // 1. Scrim barrier with blur and paper tint
          GestureDetector(
            onTap: _handleClose,
            child: Semantics(
              label: l10n.close,
              button: true,
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, _) {
                  return ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 2.0 * _fadeAnimation.value,
                        sigmaY: 2.0 * _fadeAnimation.value,
                      ),
                      child: Container(
                        color: colors.bg.withValues(
                          alpha: 0.55 * _fadeAnimation.value,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. Action buttons list (aligned right, matching FAB center line)
          Positioned(
            bottom: MediaQuery.sizeOf(context).height - fabTopY + DayzSpacing.s3,
            right: MediaQuery.sizeOf(context).width - fabLeftX - fabWidth + 5.0,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: actions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final action = entry.value;

                    // Stagger animation: camera (index 2, bottom) starts first, text (index 0, top) last
                    final double start = ((2 - idx) * 40) / 220.0;
                    final double end = (start + 0.6).clamp(0.0, 1.0);

                    final itemFadeValue = Tween<double>(begin: 0.0, end: 1.0).transform(
                      CurvedAnimation(
                        parent: _animController,
                        curve: Interval(start, end, curve: Curves.easeOut),
                      ).value,
                    );

                    final itemSlideValue = Tween<double>(begin: 10.0, end: 0.0).transform(
                      CurvedAnimation(
                        parent: _animController,
                        curve: Interval(start, end, curve: Curves.easeOut),
                      ).value,
                    );

                    return Opacity(
                      opacity: itemFadeValue,
                      child: Transform.translate(
                        offset: Offset(0, itemSlideValue),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0), // gap: 12px
                          child: Semantics(
                            button: true,
                            label: action.label,
                            child: ExcludeSemantics(
                              child: GestureDetector(
                                onTap: () => widget.onAction(action.type),
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Text label bubble
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.surface,
                                        borderRadius: BorderRadius.circular(
                                          DayzRadii.full,
                                        ),
                                        border: Border.all(
                                          color: colors.hairline,
                                          width: 1.0,
                                        ),
                                        boxShadow: colors.shadowSm,
                                      ),
                                      child: Text(
                                        action.label,
                                        style: textTheme.body.copyWith(
                                          color: colors.ink,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10), // gap: 10px
                                    // Rounded icon button (46x46)
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colors.surface,
                                        boxShadow: colors.shadowSm,
                                        border: Border.all(
                                          color: colors.hairline,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Center(
                                        child: SvgPicture.string(
                                          _svg(action.iconPath),
                                          width: 20,
                                          height: 20,
                                          colorFilter: ColorFilter.mode(
                                            colors.accentInk,
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
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // 3. Mirror the original FAB on top of the overlay (rotate and change color gradient)
          Positioned(
            left: widget.fabOffset.dx,
            top: widget.fabOffset.dy,
            width: widget.fabSize.width,
            height: widget.fabSize.height,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  // Interpolated gradient to shift color darker when open
                  final Color colorStart = Color.lerp(
                    Color.lerp(colors.accent, const Color(0xFFFFFFFF), 0.08)!,
                    Color.lerp(colors.accentStrong, const Color(0xFFFFFFFF), 0.18)!,
                    _fadeAnimation.value,
                  )!;
                  final Color colorMid = Color.lerp(colors.accent, colors.accentStrong, _fadeAnimation.value)!;
                  final Color colorEnd = colors.accentStrong;

                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colorStart, colorMid, colorEnd],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      boxShadow: colors.shadowMd,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Transform.rotate(
                        angle: _fadeAnimation.value * (3.141592653589793 / 4), // 45 degrees
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
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
