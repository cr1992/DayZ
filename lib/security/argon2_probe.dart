// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:typed_data';
import 'package:dargon2_flutter/dargon2_flutter.dart';

class Argon2Probe {
  static Future<void> runProbe() async {
    DArgon2Flutter.init();
    final password = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
    final saltBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);
    final salt = Salt(saltBytes);

    const mCost = 65536; // 64 MiB in KiB
    const tCost = 3;
    const parallelism = 1;
    const outputLen = 32;

    // Print header
    print('=== Argon2 Probe Starting ===');
    print('Parameters: m_cost=64MiB (${mCost}KiB), t_cost=${tCost}, parallelism=${parallelism}, outputLen=${outputLen}');
    
    final times = <int>[];
    
    // Warm up run to initialize FFI and warm up caches
    try {
      await argon2.hashPasswordBytes(
        password,
        salt: salt,
        iterations: tCost,
        memory: mCost,
        parallelism: parallelism,
        length: outputLen,
        type: Argon2Type.id,
      );
    } catch (e) {
      print('Argon2 Probe warm up failed: $e');
      return;
    }

    // Run 5 times
    for (int i = 0; i < 5; i++) {
      final stopwatch = Stopwatch()..start();
      await argon2.hashPasswordBytes(
        password,
        salt: salt,
        iterations: tCost,
        memory: mCost,
        parallelism: parallelism,
        length: outputLen,
        type: Argon2Type.id,
      );
      stopwatch.stop();
      times.add(stopwatch.elapsedMilliseconds);
      print('Run ${i + 1}: ${stopwatch.elapsedMilliseconds} ms');
    }

    times.sort();
    final median = times[2];
    print('=== Argon2 Probe Finished ===');
    print('Median Time: $median ms');
  }
}
