// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('Image dependency compile and decode test', () {
    // 构造一个 2x2 的 Image，每个像素设为红色
    final image = img.Image(width: 2, height: 2);
    for (var pixel in image) {
      pixel.r = 255;
      pixel.g = 0;
      pixel.b = 0;
    }

    // 编码为 Jpeg 字节
    final jpegBytes = img.encodeJpg(image);
    expect(jpegBytes, isNotEmpty);

    // 解码回来
    final decodedImage = img.decodeJpg(jpegBytes);
    expect(decodedImage, isNotNull);
    expect(decodedImage!.width, equals(2));
    expect(decodedImage.height, equals(2));
  });
}
