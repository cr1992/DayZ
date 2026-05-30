// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:typed_data';

import 'package:argon2id_ffi/argon2id_ffi.dart';
import 'package:flutter/material.dart';

/// 在真实 DayZ app 内调用自研 `argon2id_ffi`（手写 dart:ffi），验证：
/// cargokit 在 app 构建链里编出 native 库、符号被解析、Isolate 异步、算法正确。
class Argon2idFfiDemo extends StatefulWidget {
  const Argon2idFfiDemo({super.key});

  @override
  State<Argon2idFfiDemo> createState() => _Argon2idFfiDemoState();
}

class _Argon2idFfiDemoState extends State<Argon2idFfiDemo> {
  String _status = '点击运行 Argon2id (v0: 64MiB/t3/p1/len32)';
  bool _running = false;

  static String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

  Future<void> _run() async {
    setState(() {
      _running = true;
      _status = '计算中…';
    });
    try {
      // 先用 KAT 参数验正确性（对 C 参考实现逐字节）。
      final kat = await argon2idDeriveKey(
        password: Uint8List.fromList('password'.codeUnits),
        salt: Uint8List.fromList('somesalt12345678'.codeUnits),
        mCost: 256,
        tCost: 2,
        parallelism: 1,
        outputLen: 32,
      );
      final katOk = _hex(kat) ==
          '8110e1165eb0e1114ee37d5ff017573ba0084b8366b4108db44749954b8d9871';

      // 再用 v0 生产参数测耗时。
      final password =
          Uint8List.fromList('correct horse battery staple'.codeUnits);
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
      Uint8List out = Uint8List(0);
      for (var i = 0; i < 5; i++) {
        final sw = Stopwatch()..start();
        out = await derive();
        sw.stop();
        times.add(sw.elapsedMilliseconds);
      }
      times.sort();
      setState(() {
        _status = 'KAT: ${katOk ? "✅ 逐字节一致" : "❌ 不一致"}\n'
            'v0 中位耗时: ${times[2]} ms\n'
            'key=${_hex(out)}';
      });
    } catch (e) {
      setState(() => _status = '❌ 失败: $e');
    } finally {
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('argon2id_ffi demo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(_status, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _running ? null : _run,
              child: const Text('运行 Argon2id'),
            ),
          ],
        ),
      ),
    );
  }
}
