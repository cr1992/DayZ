// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cryptography provides AES-256-GCM and HKDF-SHA256', () async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final derived = await hkdf.deriveKey(
      secretKey: SecretKey(List<int>.generate(32, (index) => index)),
      nonce: const [],
      info: utf8.encode('dayz/media/v1'),
    );
    final keyBytes = await derived.extractBytes();
    expect(keyBytes, hasLength(32));

    final aes = AesGcm.with256bits();
    final nonce = aes.newNonce();
    final box = await aes.encrypt(
      utf8.encode('media smoke'),
      secretKey: SecretKey(keyBytes),
      nonce: nonce,
    );
    final plain = await aes.decrypt(box, secretKey: SecretKey(keyBytes));
    expect(utf8.decode(plain), 'media smoke');
  });
}
