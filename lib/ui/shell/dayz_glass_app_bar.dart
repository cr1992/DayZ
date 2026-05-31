// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/dayz_colors.dart';
import '../theme/dayz_tokens.g.dart';
import '../util/dayz_motion.dart';

/// Cross-screen pinned glass app bar for scrollable DayZ shells.
///
/// Author: @Ray
class DayzGlassAppBar extends StatefulWidget {
  const DayzGlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions = const <Widget>[],
    this.scrollController,
    this.scrolledUnder,
    this.scrolledUnderOffset = defaultScrolledUnderOffset,
    this.toolbarHeight = kToolbarHeight,
    this.pinned = true,
    this.floating = false,
    this.centerTitle,
    this.automaticallyImplyLeading = false,
    this.blurSigma = defaultBlurSigma,
  });

  static const double defaultBlurSigma = 20;
  static const double defaultScrolledUnderOffset = 8;
  static const Key surfaceKey = ValueKey<String>('dayz-glass-app-bar-surface');

  final Widget? title;
  final Widget? leading;
  final List<Widget> actions;
  final ScrollController? scrollController;

  /// Overrides the controller-derived state when provided.
  final bool? scrolledUnder;
  final double scrolledUnderOffset;
  final double toolbarHeight;
  final bool pinned;
  final bool floating;
  final bool? centerTitle;
  final bool automaticallyImplyLeading;
  final double blurSigma;

  @override
  State<DayzGlassAppBar> createState() => _DayzGlassAppBarState();
}

class _DayzGlassAppBarState extends State<DayzGlassAppBar> {
  bool _controllerScrolledUnder = false;

  bool get _effectiveScrolledUnder =>
      widget.scrolledUnder ?? _controllerScrolledUnder;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_syncScrolledUnderFromController);
    _scheduleControllerSync();
  }

  @override
  void didUpdateWidget(DayzGlassAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(
        _syncScrolledUnderFromController,
      );
      widget.scrollController?.addListener(_syncScrolledUnderFromController);
    }
    _scheduleControllerSync();
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_syncScrolledUnderFromController);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      pinned: widget.pinned,
      floating: widget.floating,
      primary: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      foregroundColor: colors.ink,
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      centerTitle: widget.centerTitle,
      toolbarHeight: widget.toolbarHeight,
      titleSpacing: DayzSpacing.s4,
      leadingWidth: widget.leading != null ? 44.0 + DayzSpacing.s4 : null,
      leading: widget.leading != null
          ? Padding(
              padding: const EdgeInsets.only(left: DayzSpacing.s4),
              child: widget.leading,
            )
          : null,
      title: widget.title,
      actions: widget.actions.isNotEmpty
          ? [
              ...widget.actions,
              const SizedBox(width: DayzSpacing.s4 - 8.0),
            ]
          : widget.actions,
      iconTheme: IconThemeData(color: colors.ink),
      actionsIconTheme: IconThemeData(color: colors.ink),
      titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: colors.ink,
        fontWeight: FontWeight.w600,
      ),
      flexibleSpace: _DayzGlassAppBarSurface(
        scrolledUnder: _effectiveScrolledUnder,
        blurSigma: widget.blurSigma,
      ),
    );
  }

  void _scheduleControllerSync() {
    if (widget.scrolledUnder != null || widget.scrollController == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncScrolledUnderFromController();
      }
    });
  }

  void _syncScrolledUnderFromController() {
    final controller = widget.scrollController;
    if (controller == null || widget.scrolledUnder != null) {
      return;
    }

    final next = controller.positions.any(
      (position) =>
          position.hasPixels && position.pixels > widget.scrolledUnderOffset,
    );
    if (next == _controllerScrolledUnder) {
      return;
    }

    setState(() {
      _controllerScrolledUnder = next;
    });
  }
}

class _DayzGlassAppBarSurface extends StatelessWidget {
  const _DayzGlassAppBarSurface({
    required this.scrolledUnder,
    required this.blurSigma,
  });

  final bool scrolledUnder;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final duration = dayzMotionDuration(context);

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      child: scrolledUnder
          ? ClipRect(
              key: const ValueKey<String>('dayz-glass-app-bar-glass'),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: DecoratedBox(
                  key: DayzGlassAppBar.surfaceKey,
                  decoration: BoxDecoration(
                    color: colors.glassSurface,
                    border: Border(
                      bottom: BorderSide(color: colors.hairline, width: 0.5),
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            )
          : DecoratedBox(
              key: DayzGlassAppBar.surfaceKey,
              decoration: BoxDecoration(color: colors.bg),
              child: const SizedBox.expand(),
            ),
    );
  }
}
