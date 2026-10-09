// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/widgets/dayz_icons.dart';

/// 统一的 DayZ 图标渲染口径：把 [DayzIcons] 里的 lucide 内部标记
/// （`<path>` / `<rect>` / `<circle>`）套上标准 `<svg>` 描边壳，经 [color]
/// 着色（默认 `context.dayz.ink2`）。
///
/// 全仓库只在这一处拼 `<svg>` 壳 + 上 colorFilter——调用方一律走
/// `DayzIcon(DayzIcons.xxx)`，不再各自手写 `SvgPicture.string('<svg …>')`。
///
/// 标记真源：`DayzIcons`（其中编辑器工具栏一套出自
/// `ui-design/current/pages/screens/editor.html`）。
class DayzIcon extends StatelessWidget {
  const DayzIcon(
    this.markup, {
    super.key,
    this.size = 18,
    this.color,
    this.filled = false,
    this.strokeWidth = 2,
  });

  /// 单 `<path>` 便捷构造（把 [path] 包进 `<path d="…"/>`）。供只有路径数据
  /// （如 [DayzIcons] 里的 `*Path` 常量）的旧图标平滑接入。
  // 字符串插值无法 const（这是重定向构造，参数为运行期字符串）。
  // ignore: prefer_const_constructors_in_immutables
  DayzIcon.path(
    String path, {
    Key? key,
    double size = 18,
    Color? color,
    bool filled = false,
    double strokeWidth = 2,
  }) : this(
         '<path d="$path"/>',
         key: key,
         size: size,
         color: color,
         filled: filled,
         strokeWidth: strokeWidth,
       );

  /// 图标内部 SVG 标记（不含外层 `<svg>`），如 `<path d="…"/>`、
  /// `<rect …/><path …/>`。
  final String markup;

  /// 边长（逻辑像素），宽高一致。默认 18（设计稿工具栏块/列表口径）。
  final double size;

  /// 描边/填充色。null → `context.dayz.ink2`。
  final Color? color;

  /// 实心图标（`fill=currentColor`，无描边），否则按描边渲染。
  final bool filled;

  /// 描边宽（仅描边模式生效）。默认 2（设计稿 lucide 口径）；个别插画/勾选
  /// 用 1.8 / 3 等。
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? context.dayz.ink2;
    final shell = filled
        ? '<svg viewBox="0 0 24 24" fill="currentColor" '
              'xmlns="http://www.w3.org/2000/svg">$markup</svg>'
        : '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" '
              'stroke-width="$strokeWidth" stroke-linecap="round" '
              'stroke-linejoin="round" '
              'xmlns="http://www.w3.org/2000/svg">$markup</svg>';
    return SvgPicture.string(
      shell,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(resolved, BlendMode.srcIn),
    );
  }
}
