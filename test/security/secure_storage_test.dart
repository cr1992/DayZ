// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/security/secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};
  bool throwOnRead = false;
  bool throwOnWrite = false;
  dynamic exceptionToThrow;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (throwOnWrite) {
      throw exceptionToThrow ?? Exception('Write failed');
    }
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (throwOnRead) {
      throw exceptionToThrow ?? Exception('Read failed');
    }
    return _data[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data.containsKey(key);
  }
}

void main() {
  group('SecureStore Tests', () {
    late FakeFlutterSecureStorage fakeStorage;
    late SecureStore secureStore;

    setUp(() {
      fakeStorage = FakeFlutterSecureStorage();
      secureStore = SecureStore(storage: fakeStorage);
    });

    test('set and get value successfully', () async {
      final key = 'test_key';
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      await secureStore.set(key, bytes);
      final result = await secureStore.get(key);

      expect(result, equals(bytes));
    });

    test('get non-existent key returns null', () async {
      final result = await secureStore.get('non_existent');
      expect(result, isNull);
    });

    test('contains returns correct status', () async {
      final key = 'test_key';
      expect(await secureStore.contains(key), isFalse);

      await secureStore.set(key, Uint8List.fromList([1]));
      expect(await secureStore.contains(key), isTrue);
    });

    test('delete removes key successfully', () async {
      final key = 'test_key';
      await secureStore.set(key, Uint8List.fromList([1]));
      expect(await secureStore.contains(key), isTrue);

      await secureStore.delete(key);
      expect(await secureStore.contains(key), isFalse);
      expect(await secureStore.get(key), isNull);
    });

    test('get throws corrupted error on bad base64 string', () async {
      fakeStorage._data['bad_key'] = 'not-base64-encoded!';

      expect(
        () => secureStore.get('bad_key'),
        throwsA(isA<SecureStoreException>().having(
          (e) => e.code,
          'code',
          SecureStoreError.corrupted,
        )),
      );
    });

    test('wraps PlatformException bad padding to corrupted', () async {
      fakeStorage.throwOnRead = true;
      fakeStorage.exceptionToThrow = PlatformException(
        code: 'badpadding',
        message: 'Decryption failed: bad padding',
      );

      expect(
        () => secureStore.get('any_key'),
        throwsA(isA<SecureStoreException>().having(
          (e) => e.code,
          'code',
          SecureStoreError.corrupted,
        )),
      );
    });

    test('wraps general platform exception to unknown', () async {
      fakeStorage.throwOnRead = true;
      fakeStorage.exceptionToThrow = PlatformException(
        code: 'some_error',
        message: 'Something else failed',
      );

      expect(
        () => secureStore.get('any_key'),
        throwsA(isA<SecureStoreException>().having(
          (e) => e.code,
          'code',
          SecureStoreError.unknown,
        )),
      );
    });
  });
}
