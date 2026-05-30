// 端到端验证：Dart 手写 dart:ffi → C-ABI → Rust → 字节。
//
// host 跑法（dylib 由 `cd rust && cargo build --release` 产出）：
//   ARGON2ID_FFI_LIB=$PWD/rust/target/release/libargon2id_ffi.dylib \
//     flutter test test/route_b_ffi_test.dart
// （改名发 pub 后库名变 libargon2id_ffi.*，env 路径相应改。）
//
// 验证：argon2id 对 C 参考实现 KAT 逐字节一致、HKDF RFC5869、错误码抛异常、空口令/None salt 边界。

import 'dart:typed_data';

import 'package:argon2id_ffi/src/ffi/crypto_ffi.dart';
import 'package:argon2id_ffi/src/ffi/errors.dart';
import 'package:flutter_test/flutter_test.dart';

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
Uint8List _ascii(String s) => Uint8List.fromList(s.codeUnits);

void main() {
  group('argon2idDeriveKey（手写 ffi + Isolate）', () {
    test('KAT 对 C 参考实现逐字节一致', () async {
      final out = await argon2idDeriveKey(
        password: _ascii('password'),
        salt: _ascii('somesalt12345678'),
        mCost: 256,
        tCost: 2,
        parallelism: 1,
        outputLen: 32,
      );
      expect(_hex(out),
          '8110e1165eb0e1114ee37d5ff017573ba0084b8366b4108db44749954b8d9871');
    });

    test('空口令 KAT（指针/长度 0 边界）', () async {
      final out = await argon2idDeriveKey(
        password: Uint8List(0),
        salt: _ascii('0000000000000000'),
        mCost: 64,
        tCost: 1,
        parallelism: 1,
        outputLen: 16,
      );
      expect(_hex(out), '96beeae372717ec8abdc8741e3400b33');
    });

    test('非法参数（salt 过短）抛 Argon2idFfiException(BadParam)', () async {
      await expectLater(
        argon2idDeriveKey(
          password: _ascii('pw'),
          salt: _ascii('short'),
          mCost: 256,
          tCost: 2,
          parallelism: 1,
          outputLen: 32,
        ),
        throwsA(isA<Argon2idFfiException>()
            .having((e) => e.code, 'code', kErrBadParam)),
      );
    });

    test('确定性：两次结果相同', () async {
      Future<Uint8List> run() => argon2idDeriveKey(
            password: _ascii('pw'),
            salt: _ascii('saltsalt'),
            mCost: 256,
            tCost: 2,
            parallelism: 1,
            outputLen: 32,
          );
      expect(_hex(await run()), _hex(await run()));
    });
  });

  group('hkdfSha256DeriveKey（手写 ffi + Isolate）', () {
    test('RFC 5869 Case 1', () async {
      final out = await hkdfSha256DeriveKey(
        ikm: Uint8List.fromList(List.filled(22, 0x0b)),
        salt: Uint8List.fromList(List.generate(13, (i) => i)),
        info: Uint8List.fromList(List.generate(10, (i) => 0xf0 + i)),
        outputLen: 42,
      );
      expect(_hex(out),
          '3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865');
    });

    test('RFC 5869 Case 3（salt=null 走全零 salt）', () async {
      final out = await hkdfSha256DeriveKey(
        ikm: Uint8List.fromList(List.filled(22, 0x0b)),
        salt: null,
        info: Uint8List(0),
        outputLen: 42,
      );
      expect(_hex(out),
          '8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d9d201395faa4b61a96c8');
    });
  });
}
