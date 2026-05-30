// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/security/secure_storage.dart';
import 'package:dayz/security/device_key.dart';
import 'secure_storage_test.dart';

class FakeRandom extends Fake implements Random {
  final List<int> values;
  int _index = 0;

  FakeRandom(this.values);

  @override
  int nextInt(int max) {
    final val = values[_index];
    _index = (_index + 1) % values.length;
    return val;
  }
}

class CorruptedSecureStore extends Fake implements SecureStore {
  @override
  Future<bool> contains(String key) async => true;

  @override
  Future<Uint8List?> get(String key) async => null;
}

void main() {
  group('DeviceKey Tests', () {
    late FakeFlutterSecureStorage fakeStorage;
    late SecureStore secureStore;

    setUp(() {
      fakeStorage = FakeFlutterSecureStorage();
      secureStore = SecureStore(storage: fakeStorage);
    });

    test('exists returns false when key does not exist', () async {
      expect(await DeviceKey.exists(store: secureStore), isFalse);
    });

    test('ensure generates and saves new key when not exists', () async {
      final randomBytes = List<int>.generate(32, (i) => i);
      final fakeRandom = FakeRandom(randomBytes);

      expect(await DeviceKey.exists(store: secureStore), isFalse);

      final key = await DeviceKey.ensure(store: secureStore, random: fakeRandom);

      expect(key, equals(Uint8List.fromList(randomBytes)));
      expect(await DeviceKey.exists(store: secureStore), isTrue);

      final savedKey = await secureStore.get('device_db_key');
      expect(savedKey, equals(key));
    });

    test('ensure reads existing key on subsequent calls', () async {
      final firstRandomBytes = List<int>.generate(32, (i) => i);
      final fakeRandom1 = FakeRandom(firstRandomBytes);

      final key1 = await DeviceKey.ensure(store: secureStore, random: fakeRandom1);

      final secondRandomBytes = List<int>.generate(32, (i) => 31 - i);
      final fakeRandom2 = FakeRandom(secondRandomBytes);

      final key2 = await DeviceKey.ensure(store: secureStore, random: fakeRandom2);

      expect(key2, equals(key1));
      expect(key2, isNot(equals(Uint8List.fromList(secondRandomBytes))));
    });

    test('ensure throws corrupted error when key flag exists but value is null', () async {
      final corruptedStore = CorruptedSecureStore();

      expect(
        () => DeviceKey.ensure(store: corruptedStore),
        throwsA(isA<SecureStoreException>().having(
          (e) => e.code,
          'code',
          SecureStoreError.corrupted,
        )),
      );
    });
  });
}
