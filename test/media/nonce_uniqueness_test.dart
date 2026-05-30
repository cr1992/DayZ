// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dayz/media/media_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import 'media_test_utils.dart';

void main() {
  test('MediaCodec generates a fresh nonce for each encrypted file', () async {
    final codec = MediaCodec();
    final key = testKey();
    final nonces = <String>{};

    for (var i = 0; i < 1000; i++) {
      final encrypted = await collectBytes(
        codec.encrypt(plain: byteStream([i & 0xff]), key: key),
      );
      final nonce = MediaCodec.nonceFromEncryptedBytes(encrypted);
      nonces.add(
        nonce.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
      );
    }

    expect(nonces, hasLength(1000));
  });
}
