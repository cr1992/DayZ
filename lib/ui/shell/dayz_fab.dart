// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/material.dart';

import '../strings/app_strings.dart';
import '../theme/dayz_colors.dart';
import '../theme/dayz_tokens.g.dart';
import '../util/dayz_motion.dart';

/// A DayZ floating action button with long-press speed-dial actions.
///
/// Author: @Ray
class DayzFab extends StatefulWidget {
  const DayzFab({super.key, required this.onTap, required this.actions});

  final VoidCallback onTap;
  final List<DayzFabAction> actions;

  @override
  State<DayzFab> createState() => _DayzFabState();
}

/// Secondary action shown by [DayzFab] after a long press.
///
/// Author: @Ray
class DayzFabAction {
  const DayzFabAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;
}

class _DayzFabState extends State<DayzFab> {
  static const _longPressDelay = Duration(milliseconds: 350);
  static const _mainSize = 58.0;
  static const _actionSize = 46.0;

  Timer? _longPressTimer;
  bool _expanded = false;
  bool _pressing = false;
  bool _longPressTriggered = false;
  bool _pointerStartedExpanded = false;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final duration = dayzMotionDuration(context, DayzMotion.dur);
    final padding = MediaQuery.paddingOf(context);
    final right = DayzSpacing.s5 + padding.right;
    final bottom = DayzSpacing.s5 + padding.bottom;

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildScrim(colors, duration),
          Positioned(
            right: right + (_mainSize - _actionSize) / 2,
            bottom: bottom + _mainSize + DayzSpacing.s3,
            child: _buildActions(colors, duration),
          ),
          Positioned(
            right: right,
            bottom: bottom,
            child: _buildMainButton(colors, duration),
          ),
        ],
      ),
    );
  }

  Widget _buildScrim(DayzColors colors, Duration duration) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_expanded,
        child: AnimatedOpacity(
          key: const ValueKey('dayz-fab-scrim-opacity'),
          opacity: _expanded ? 1 : 0,
          duration: duration,
          curve: Curves.easeOutCubic,
          child: GestureDetector(
            key: const ValueKey('dayz-fab-scrim'),
            behavior: HitTestBehavior.opaque,
            onTap: _collapse,
            child: ColoredBox(color: colors.overlay),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(DayzColors colors, Duration duration) {
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          alwaysIncludeSemantics: true,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
            alignment: Alignment.bottomRight,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.16),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
        );
      },
      child: _expanded
          ? Column(
              key: const ValueKey('dayz-fab-actions-open'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < widget.actions.length; index++)
                  Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 0 : DayzSpacing.s3,
                    ),
                    child: _DayzFabActionButton(
                      action: widget.actions[index],
                      colors: colors,
                      onTap: () => _invokeAction(widget.actions[index]),
                    ),
                  ),
              ],
            )
          : const SizedBox.shrink(key: ValueKey('dayz-fab-actions-closed')),
    );
  }

  Widget _buildMainButton(DayzColors colors, Duration duration) {
    return Semantics(
      button: true,
      label: AppStrings.add,
      onTap: _handleSemanticTap,
      child: ExcludeSemantics(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _handlePointerDown,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          child: AnimatedScale(
            scale: _pressing ? 1.06 : 1,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: SizedBox.square(
              key: const ValueKey('dayz-fab-main'),
              dimension: _mainSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: colors.fabGradient,
                  boxShadow: _fabShadows(colors),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(child: _DayzFabHighlight()),
                    AnimatedRotation(
                      turns: _expanded ? 0.125 : 0,
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      child: Icon(Icons.add, color: colors.onAccent, size: 26),
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

  List<BoxShadow> _fabShadows(DayzColors colors) {
    final ambientColor = colors.shadowLg.firstOrNull?.color ?? colors.ink;
    final contactColor = colors.shadowSm.firstOrNull?.color ?? colors.ink;

    return [
      BoxShadow(
        color: colors.accentRing,
        offset: const Offset(0, 10),
        blurRadius: 22,
        spreadRadius: -6,
      ),
      BoxShadow(
        color: ambientColor,
        offset: const Offset(0, 16),
        blurRadius: 30,
        spreadRadius: -10,
      ),
      BoxShadow(color: contactColor, offset: const Offset(0, 2), blurRadius: 5),
    ];
  }

  void _handlePointerDown(PointerDownEvent event) {
    _longPressTimer?.cancel();
    _pointerStartedExpanded = _expanded;
    _longPressTriggered = false;

    if (_expanded || widget.actions.isEmpty) {
      return;
    }

    setState(() {
      _pressing = true;
    });

    _longPressTimer = Timer(_longPressDelay, () {
      if (!mounted) {
        return;
      }

      setState(() {
        _expanded = true;
        _pressing = false;
        _longPressTriggered = true;
      });
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    _longPressTimer?.cancel();

    if (_pointerStartedExpanded) {
      _collapse();
      return;
    }

    if (_longPressTriggered) {
      return;
    }

    setState(() {
      _pressing = false;
    });
    widget.onTap();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _longPressTimer?.cancel();

    if (!_pressing) {
      return;
    }

    setState(() {
      _pressing = false;
    });
  }

  void _handleSemanticTap() {
    if (_expanded) {
      _collapse();
      return;
    }

    widget.onTap();
  }

  void _invokeAction(DayzFabAction action) {
    _collapse();
    action.onTap();
  }

  void _collapse() {
    _longPressTimer?.cancel();

    if (!_expanded && !_pressing) {
      return;
    }

    setState(() {
      _expanded = false;
      _pressing = false;
      _longPressTriggered = false;
    });
  }
}

class _DayzFabActionButton extends StatelessWidget {
  const _DayzFabActionButton({
    required this.action,
    required this.colors,
    required this.onTap,
  });

  final DayzFabAction action;
  final DayzColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: action.label,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.hairline),
                  borderRadius: BorderRadius.circular(DayzRadii.full),
                  boxShadow: colors.shadowSm,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DayzSpacing.s3,
                    vertical: 6,
                  ),
                  child: Text(
                    action.label,
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox.square(
                key: ValueKey('dayz-fab-action-${action.label}'),
                dimension: _DayzFabState._actionSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.hairline),
                    borderRadius: BorderRadius.circular(DayzRadii.full),
                    boxShadow: colors.shadowSm,
                  ),
                  child: IconTheme(
                    data: IconThemeData(color: colors.accentInk, size: 20),
                    child: Center(child: action.icon),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayzFabHighlight extends StatelessWidget {
  const _DayzFabHighlight();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, 0.46],
        ),
      ),
    );
  }
}
