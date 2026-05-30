// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:typed_data';

import 'package:dayz/media/exceptions.dart';
import 'package:dayz/media/media_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import 'media_test_utils.dart';

void main() {
  final codec = MediaCodec();
  final key = testKey();

  Future<Uint8List> roundTrip(List<int> plain) async {
    final encrypted = await collectBytes(
      codec.encrypt(plain: byteStream(plain), key: key),
    );
    expect(encrypted.sublist(0, 4), MediaCodec.magic);
    expect(encrypted[4], MediaCodec.version);
    expect(encrypted[5], MediaCodec.algorithmAes256Gcm);
    return collectBytes(codec.decrypt(cipher: byteStream(encrypted), key: key));
  }

  test('round trips 1 KiB payload', () async {
    final plain = Uint8List.fromList(List<int>.generate(1024, (i) => i & 0xff));
    expect(await roundTrip(plain), plain);
  });

  test('round trips 64 KiB boundary payload', () async {
    final plain = Uint8List.fromList(
      List<int>.generate(64 * 1024, (i) => (i * 31) & 0xff),
    );
    expect(await roundTrip(plain), plain);
  });

  test(
    'round trips 100 MiB through file streams',
    () async {
      const totalBytes = 100 * 1024 * 1024;
      final tempDir = Directory.systemTemp.createTempSync(
        'dayz_media_codec_big',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final encryptedFile = File('${tempDir.path}/big.bin');

      final expected = await checksum(patternStream(totalBytes));
      final sink = encryptedFile.openWrite();
      await sink.addStream(
        codec.encrypt(plain: patternStream(totalBytes), key: key),
      );
      await sink.close();

      final actual = await checksum(
        codec.decrypt(cipher: encryptedFile.openRead(), key: key),
      );
      expect(actual, expected);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test('tampered ciphertext throws and yields no bytes', () async {
    final encrypted = await collectBytes(
      codec.encrypt(
        plain: byteStream(List<int>.generate(128, (i) => i)),
        key: key,
      ),
    );
    encrypted[MediaCodec.headerLength] ^= 0x01;

    await _expectCorruptedWithoutBytes(codec, encrypted, key);
  });

  test('tampered tag throws and yields no bytes', () async {
    final encrypted = await collectBytes(
      codec.encrypt(
        plain: byteStream(List<int>.generate(128, (i) => i)),
        key: key,
      ),
    );
    encrypted[encrypted.length - 1] ^= 0x01;

    await _expectCorruptedWithoutBytes(codec, encrypted, key);
  });

  test('wrong key throws and yields no bytes', () async {
    final encrypted = await collectBytes(
      codec.encrypt(
        plain: byteStream(List<int>.generate(128, (i) => i)),
        key: key,
      ),
    );

    await _expectCorruptedWithoutBytes(codec, encrypted, testKey(99));
  });
}

Future<void> _expectCorruptedWithoutBytes(
  MediaCodec codec,
  Uint8List encrypted,
  Uint8List key,
) async {
  final emitted = <List<int>>[];
  await expectLater(() async {
    await for (final chunk in codec.decrypt(
      cipher: byteStream(encrypted),
      key: key,
    )) {
      emitted.add(chunk);
    }
  }(), throwsA(isA<MediaCorruptedException>()));
  expect(emitted, isEmpty);
}
