// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:typed_data';

import 'package:argon2id_ffi/argon2id_ffi.dart';

typedef HkdfSha256Deriver =
    Future<Uint8List> Function({
      required Uint8List ikm,
      Uint8List? salt,
      required Uint8List info,
      required int outputLen,
    });

class Hkdf {
  static const int sha256HashLen = 32;
  static const int maxOutputLen = 255 * sha256HashLen;

  static Future<Uint8List> deriveSha256({
    required Uint8List ikm,
    Uint8List? salt,
    required Uint8List info,
    required int outputLen,
  }) async {
    if (outputLen < 1 || outputLen > maxOutputLen) {
      throw ArgumentError.value(
        outputLen,
        'outputLen',
        'HKDF-SHA256 outputLen 必须在 1..$maxOutputLen 之间',
      );
    }

    final effectiveSalt = (salt == null || salt.isEmpty) ? null : salt;
    return hkdfSha256DeriveKey(
      ikm: ikm,
      salt: effectiveSalt,
      info: info,
      outputLen: outputLen,
    );
  }
}
