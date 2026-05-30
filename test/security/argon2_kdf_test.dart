// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:typed_data';

import 'package:dayz/security/argon2_kdf.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _ascii(String s) => Uint8List.fromList(s.codeUnits);
String _hex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

class _KatCase {
  final Uint8List password;
  final Uint8List salt;
  final KdfParams params;
  final String expectedHex;

  const _KatCase({
    required this.password,
    required this.salt,
    required this.params,
    required this.expectedHex,
  });
}

void main() {
  group('Argon2Kdf', () {
    test('KAT 对权威参考实现逐字节一致', () async {
      final cases = <_KatCase>[
        _KatCase(
          password: _ascii('password'),
          salt: _ascii('somesalt12345678'),
          params: const KdfParams(
            mCostKiB: 256,
            tCost: 2,
            parallelism: 1,
            outputLen: 32,
            version: 1,
          ),
          expectedHex:
              '8110e1165eb0e1114ee37d5ff017573ba0084b8366b4108db44749954b8d9871',
        ),
        _KatCase(
          password: _ascii('password'),
          salt: _ascii('somesalt12345678'),
          params: const KdfParams(
            mCostKiB: 512,
            tCost: 3,
            parallelism: 2,
            outputLen: 32,
            version: 1,
          ),
          expectedHex:
              '2bc785154e5a2d1dda9fb07d4589b77ce64c022df6c63e373b31c9f3bc0b30f8',
        ),
        _KatCase(
          password: _ascii(''),
          salt: _ascii('0000000000000000'),
          params: const KdfParams(
            mCostKiB: 64,
            tCost: 1,
            parallelism: 1,
            outputLen: 16,
            version: 1,
          ),
          expectedHex: '96beeae372717ec8abdc8741e3400b33',
        ),
        _KatCase(
          password: _ascii('correct horse'),
          salt: _ascii('NaCl-with-8b'),
          params: const KdfParams(
            mCostKiB: 1024,
            tCost: 3,
            parallelism: 1,
            outputLen: 64,
            version: 1,
          ),
          expectedHex:
              '95750f2e33061e857673731eab5453a587fefeb398ff8d6373a84bcaf0e0d63000840c72a6a0a3004c59dc1ff7e0d98579938954405cb7ac73c3a7bf38f2236f',
        ),
      ];

      for (final testCase in cases) {
        final output = await Argon2Kdf.deriveKey(
          testCase.password,
          testCase.salt,
          testCase.params,
        );
        expect(_hex(output), testCase.expectedHex);
      }
    });

    test('相同输入输出确定', () async {
      final params = const KdfParams.v1();
      final out1 = await Argon2Kdf.deriveKey(
        _ascii('my_secure_password'),
        _ascii('somesalt12345678'),
        params,
      );
      final out2 = await Argon2Kdf.deriveKey(
        _ascii('my_secure_password'),
        _ascii('somesalt12345678'),
        params,
      );

      expect(_hex(out1), _hex(out2));
    });

    test('不同 salt 输出不同', () async {
      final params = const KdfParams.v1();
      final out1 = await Argon2Kdf.deriveKey(
        _ascii('my_secure_password'),
        _ascii('somesalt12345678'),
        params,
      );
      final out2 = await Argon2Kdf.deriveKey(
        _ascii('my_secure_password'),
        _ascii('somesalt12345679'),
        params,
      );

      expect(_hex(out1), isNot(_hex(out2)));
    });

    test('密码字节区在使用后被清零', () async {
      final password = _ascii('my_secure_password');
      expect(password.every((byte) => byte == 0), isFalse);

      await Argon2Kdf.deriveKey(
        password,
        _ascii('somesalt12345678'),
        const KdfParams.v1(),
      );

      expect(password.every((byte) => byte == 0), isTrue);
    });
  });
}
