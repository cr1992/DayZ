// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:dayz/media/media_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import 'media_test_utils.dart';

void main() {
  test(
    'reports media codec throughput without environment-dependent assertions',
    () async {
      const totalBytes = int.fromEnvironment(
        'DAYZ_MEDIA_BENCH_BYTES',
        defaultValue: 100 * 1024 * 1024,
      );
      final codec = MediaCodec();
      final key = testKey();
      final tempDir = Directory.systemTemp.createTempSync(
        'dayz_media_throughput',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final encryptedFile = File('${tempDir.path}/throughput.bin');

      final writeWatch = Stopwatch()..start();
      final sink = encryptedFile.openWrite();
      await sink.addStream(
        codec.encrypt(plain: patternStream(totalBytes), key: key),
      );
      await sink.close();
      writeWatch.stop();

      final readWatch = Stopwatch()..start();
      final actual = await checksum(
        codec.decrypt(cipher: encryptedFile.openRead(), key: key),
      );
      readWatch.stop();

      expect(actual.length, totalBytes);
      // ignore: avoid_print
      print(
        'media throughput: write=${_mibPerSecond(totalBytes, writeWatch.elapsed)} MiB/s, '
        'read=${_mibPerSecond(totalBytes, readWatch.elapsed)} MiB/s',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

String _mibPerSecond(int bytes, Duration elapsed) {
  final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  final mib = bytes / (1024 * 1024);
  return (mib / seconds).toStringAsFixed(1);
}
