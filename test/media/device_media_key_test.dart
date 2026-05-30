// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:typed_data';

import 'package:dayz/security/key_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'media_test_utils.dart';

class _FakeKeyProvider extends KeyProvider {
  final Uint8List mediaKey;
  final Uint8List dbKey;

  _FakeKeyProvider({required this.mediaKey, required this.dbKey});

  @override
  Future<Uint8List> getDeviceMediaKey() async => Uint8List.fromList(mediaKey);

  @override
  Future<Uint8List> getAppDbKey() async => Uint8List.fromList(dbKey);
}

void main() {
  test(
    'Media storage consumes KeyProvider.getDeviceMediaKey contract',
    () async {
      final provider = _FakeKeyProvider(
        mediaKey: testKey(7),
        dbKey: testKey(80),
      );

      final mediaKey = await provider.getDeviceMediaKey();
      final dbKey = await provider.getAppDbKey();

      expect(mediaKey, hasLength(32));
      expect(mediaKey, isNot(equals(dbKey)));
    },
  );
}
