import 'dart:typed_data';

import 'package:argon2id_ffi/argon2id_ffi.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// 真机/模拟器跑一次 v0 参数（64MiB/t3/p1/len32）Argon2id 派生并打点中位耗时——
/// NF1（<1.5s）真机验证 demo。
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<({String keyHex, int medianMs})> _runArgon2() async {
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
    Uint8List out = Uint8List(0);
    for (var i = 0; i < 5; i++) {
      final sw = Stopwatch()..start();
      out = await derive();
      sw.stop();
      times.add(sw.elapsedMilliseconds);
    }
    times.sort();
    return (keyHex: _hex(out), medianMs: times[2]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('argon2id_ffi · Argon2id')),
        body: Center(
          child: FutureBuilder<({String keyHex, int medianMs})>(
            future: _runArgon2(),
            builder: (context, snap) {
              if (!snap.hasData) return const CircularProgressIndicator();
              final r = snap.data!;
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Argon2id v0 (m=64MiB, t=3, p=1, len=32)'),
                    const SizedBox(height: 12),
                    Text('中位耗时: ${r.medianMs} ms  (NF1 目标 < 1500ms)'),
                    const SizedBox(height: 12),
                    SelectableText('key=${r.keyHex}'),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
