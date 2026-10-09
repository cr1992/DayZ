// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden 比对加一点容差：基线由云端 Linux 会话生成，macOS 宿主的字体栅格化
/// 有 0.03%–0.05% 的像素差（reader golden 实测 109–126 px），这不是布局偏差。
/// 超过 [_maxDiffRatio] 仍判失败，布局真变了照样拦住。
const double _maxDiffRatio = 0.002; // 0.2%

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final current = goldenFileComparator;
  if (current is LocalFileComparator) {
    goldenFileComparator = _TolerantGoldenComparator(current);
  }
  await testMain();
}

class _TolerantGoldenComparator extends LocalFileComparator {
  // LocalFileComparator 的构造参数是「测试文件 URI」，basedir 取其所在目录；
  // 这里用占位文件名把 inner 的 basedir 原样传下去。
  _TolerantGoldenComparator(LocalFileComparator inner)
    : super(inner.basedir.resolve('_golden_placeholder_test.dart'));

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= _maxDiffRatio) {
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}
