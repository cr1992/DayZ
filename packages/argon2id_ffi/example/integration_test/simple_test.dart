// 真机 / 模拟器集成测试——NF1（性能）与 R1/R3（真机链接、符号留存）设备侧验证入口。
// 运行：cd example && flutter test integration_test/ -d <device>
// 务必 release/profile 跑（debug 下纯 Rust argon2 慢一个数量级，且不暴露符号剥离）。

import 'dart:typed_data';

import 'package:argon2id_ffi/argon2id_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('Argon2id KAT 真机逐字节一致（验证 native 符号解析 + 算法）', () async {
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

  test('Argon2id v0 真机中位耗时 < 1.5s（NF1）', () async {
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
    await derive(); // 预热
    final times = <int>[];
    for (var i = 0; i < 5; i++) {
      final sw = Stopwatch()..start();
      await derive();
      sw.stop();
      times.add(sw.elapsedMilliseconds);
    }
    times.sort();
    // ignore: avoid_print
    print('Argon2id v0 真机中位耗时: ${times[2]}ms  (NF1 目标 < 1500ms)');
    expect(times[2], lessThan(1500));
  });
}
