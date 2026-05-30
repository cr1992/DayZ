// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.

import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/gen/assets.gen.dart';

void main() {
  test('Assets gen 强类型引用解析到正确路径', () {
    expect(Assets.editor.demoImage.path, equals('assets/editor/demo_image.png'));
  });
}
