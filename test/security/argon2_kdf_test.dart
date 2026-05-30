// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/security/argon2_kdf.dart';

Uint8List _ascii(String s) => Uint8List.fromList(s.codeUnits);
String _hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('Argon2Kdf', () {
    test('KAT 对 C 参考实现一致', () async {
      final params = KdfParams(
        mCostKiB: 256,
        tCost: 2,
        parallelism: 1,
        outputLen: 32,
        version: 1,
      );
      final out = await Argon2Kdf.deriveKey(
        _ascii('password'),
        _ascii('somesalt12345678'),
        params,
      );
      expect(_hex(out), '8110e1165eb0e1114ee37d5ff017573ba0084b8366b4108db44749954b8d9871');
    });

    test('相同输入输出确定', () async {
      final params = const KdfParams.v1();
      final pwd1 = _ascii('my_secure_password');
      final pwd2 = _ascii('my_secure_password');
      final salt = _ascii('somesalt12345678');
      
      final out1 = await Argon2Kdf.deriveKey(pwd1, salt, params);
      final out2 = await Argon2Kdf.deriveKey(pwd2, salt, params);
      expect(_hex(out1), _hex(out2));
    });

    test('不同 salt 输出不同', () async {
      final params = const KdfParams.v1();
      final pwd1 = _ascii('my_secure_password');
      final pwd2 = _ascii('my_secure_password');
      final salt1 = _ascii('somesalt12345678');
      final salt2 = _ascii('somesalt12345679');
      
      final out1 = await Argon2Kdf.deriveKey(pwd1, salt1, params);
      final out2 = await Argon2Kdf.deriveKey(pwd2, salt2, params);
      expect(_hex(out1), isNot(_hex(out2)));
    });

    test('密码字节区在使用后被清零', () async {
      final params = const KdfParams.v1();
      final pwd = _ascii('my_secure_password');
      expect(pwd.every((b) => b == 0), isFalse);
      
      await Argon2Kdf.deriveKey(pwd, _ascii('somesalt12345678'), params);
      expect(pwd.every((b) => b == 0), isTrue);
    });
  });
}
