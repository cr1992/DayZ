// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/widgets.dart';

import '../theme/dayz_colors.dart';
import '../util/dayz_motion.dart';

/// 卡片封面 / 相册格子的图位：`accentSoft2` 底色常驻作占位，图源出第一帧后
/// 经 [dayzMotionDuration] 淡入（减少动态时瞬时），加载失败保持占位、不把异常
/// 抛到 build。
///
/// 配合异步图源（如解密缩略图）使用：就绪前 `Image` 无帧，底色即占位。
///
/// Author: @Ray
class DayzImageSlot extends StatelessWidget {
  const DayzImageSlot({super.key, required this.image, this.fit = BoxFit.cover});

  /// 图源加载失败时渲染的占位。
  static const Key placeholderKey = ValueKey<String>('dayz-image-slot-error');

  final ImageProvider image;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final duration = dayzMotionDuration(context);

    return ColoredBox(
      color: colors.accentSoft2,
      child: Image(
        image: image,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            return child;
          }
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: duration,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          key: placeholderKey,
          color: colors.accentSoft2,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
