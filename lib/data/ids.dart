// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:math';

class Ids {
  static final Random _random = Random.secure();

  static int _lastMs = 0;
  static int _lastSeq = 0;
  static int _lastRandA = 0;
  static int _lastRandB = 0;

  /// Generates a time-ordered UUID v7 string (36 characters).
  /// Guarantees strict monotonic increasing order even within the same millisecond.
  static String next() {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    if (now > _lastMs) {
      _lastMs = now;
      _lastSeq = _random.nextInt(4096);
      _lastRandA = _random.nextInt(0x40000000); // 30 bits
      _lastRandB = _random.nextInt(0x100000000); // 32 bits
    } else {
      // Within the same millisecond or during clock drift/rollback:
      // increment sequence to guarantee strict monotonicity
      _lastSeq++;
      if (_lastSeq >= 4096) {
        _lastMs++;
        _lastSeq = 0;
      }
    }

    return _formatUuidV7(_lastMs, _lastSeq, _lastRandA, _lastRandB);
  }

  static String _formatUuidV7(int ms, int seq, int randA, int randB) {
    // 48-bit millisecond timestamp -> 12 hex chars
    final msHex = ms.toRadixString(16).padLeft(12, '0');

    // 4-bit version (7) + 12-bit sequence -> 4 hex chars
    final verSeqHex = '7${seq.toRadixString(16).padLeft(3, '0')}';

    // 2-bit variant (binary 10) + 30-bit randA -> 8 hex chars (32-bit word)
    final varRandAHex = ((randA & 0x3FFFFFFF) | 0x80000000)
        .toRadixString(16)
        .padLeft(8, '0');

    // 32-bit randB -> 8 hex chars
    final randBHex = randB.toRadixString(16).padLeft(8, '0');

    // UUID format: 8-4-4-4-12
    final part1 = msHex.substring(0, 8);
    final part2 = msHex.substring(8, 12);
    final part3 = verSeqHex;
    final part4 = varRandAHex.substring(0, 4);
    final part5 = varRandAHex.substring(4, 8) + randBHex;

    return '$part1-$part2-$part3-$part4-$part5';
  }
}
