// 在真实 DayZ app 内、iOS 模拟器上验证自研 argon2id_ffi：
// 证明 cargokit 在 app 构建链里编出 native 库、符号被 DynamicLibrary.process() 解析、
// Isolate 异步、算法对 C 参考实现逐字节一致。
//
// 跑法：flutter test integration_test/argon2id_ffi_test.dart -d <ios-sim-id>
//
// ⚠️ 模拟器/debug 不做 archive 的符号剥离步骤，故本测试**不覆盖** iOS release/archive
// 符号留存那道闸门——那个要 `flutter build ios --release` + nm 检查或真机 TestFlight。

import 'dart:typed_data';

import 'package:argon2id_ffi/argon2id_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('argon2id_ffi KAT 在 DayZ app 内逐字节一致', (tester) async {
    final out = await argon2idDeriveKey(
      password: Uint8List.fromList('password'.codeUnits),
      salt: Uint8List.fromList('somesalt12345678'.codeUnits),
      mCost: 256,
      tCost: 2,
      parallelism: 1,
      outputLen: 32,
    );
    expect(_hex(out),
        '8110e1165eb0e1114ee37d5ff017573ba0084b8366b4108db44749954b8d9871');
  });

  testWidgets('hkdf RFC5869 Case1 在 app 内一致', (tester) async {
    final out = await hkdfSha256DeriveKey(
      ikm: Uint8List.fromList(List.filled(22, 0x0b)),
      salt: Uint8List.fromList(List.generate(13, (i) => i)),
      info: Uint8List.fromList(List.generate(10, (i) => 0xf0 + i)),
      outputLen: 42,
    );
    expect(_hex(out),
        '3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865');
  });

  testWidgets('argon2id v0 在模拟器上的中位耗时', (tester) async {
    final password = Uint8List.fromList('correct horse battery staple'.codeUnits);
    final salt = Uint8List.fromList(List.filled(16, 0x02));
    Future<Uint8List> derive() => argon2idDeriveKey(
          password: password,
          salt: salt,
          mCost: 65536,
          tCost: 3,
          parallelism: 1,
          outputLen: 32,
        );
    await derive();
    final times = <int>[];
    for (var i = 0; i < 5; i++) {
      final sw = Stopwatch()..start();
      await derive();
      sw.stop();
      times.add(sw.elapsedMilliseconds);
    }
    times.sort();
    // ignore: avoid_print
    print('argon2id v0 模拟器中位耗时: ${times[2]}ms（注：模拟器跑在 Mac CPU 上，非真机口径）');
    expect(times[2], lessThan(2000)); // 宽松上界，仅防退化
  });
}
