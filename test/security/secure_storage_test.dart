// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/security/secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('SecureStore', () {
    late FakeFlutterSecureStorage fakeStorage;
    late SecureStore secureStore;

    setUp(() {
      fakeStorage = FakeFlutterSecureStorage();
      secureStore = SecureStore(storage: fakeStorage);
    });

    test('set / get 正常往返', () async {
      const key = 'test_key';
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      await secureStore.set(key, bytes);
      final result = await secureStore.get(key);

      expect(result, equals(bytes));
    });

    test('读取不存在 key 返回 null', () async {
      expect(await secureStore.get('non_existent'), isNull);
    });

    test('contains 返回正确状态', () async {
      const key = 'test_key';
      expect(await secureStore.contains(key), isFalse);

      await secureStore.set(key, Uint8List.fromList([1]));
      expect(await secureStore.contains(key), isTrue);
    });

    test('delete 成功移除 key', () async {
      const key = 'test_key';
      await secureStore.set(key, Uint8List.fromList([1]));
      expect(await secureStore.contains(key), isTrue);

      await secureStore.delete(key);
      expect(await secureStore.contains(key), isFalse);
      expect(await secureStore.get(key), isNull);
    });

    test('bad base64 走 corrupted', () async {
      fakeStorage._data['bad_key'] = 'not-base64-encoded!';

      expect(
        () => secureStore.get('bad_key'),
        throwsA(
          isA<SecureStoreException>().having(
            (error) => error.code,
            'code',
            SecureStoreError.corrupted,
          ),
        ),
      );
    });

    test('BadPadding 平台异常映射为 corrupted', () async {
      fakeStorage.throwOnRead = true;
      fakeStorage.exceptionToThrow = PlatformException(
        code: 'badpadding',
        message: 'Decryption failed: bad padding',
      );

      expect(
        () => secureStore.get('any_key'),
        throwsA(
          isA<SecureStoreException>().having(
            (error) => error.code,
            'code',
            SecureStoreError.corrupted,
          ),
        ),
      );
    });

    test('unavailable 平台异常映射为 unavailable', () async {
      fakeStorage.throwOnRead = true;
      fakeStorage.exceptionToThrow = PlatformException(
        code: 'unavailable',
        message: 'KeyStore unavailable on this device',
      );

      expect(
        () => secureStore.get('any_key'),
        throwsA(
          isA<SecureStoreException>().having(
            (error) => error.code,
            'code',
            SecureStoreError.unavailable,
          ),
        ),
      );
    });

    test('通用平台异常映射为 unknown', () async {
      fakeStorage.throwOnRead = true;
      fakeStorage.exceptionToThrow = PlatformException(
        code: 'some_error',
        message: 'Something else failed',
      );

      expect(
        () => secureStore.get('any_key'),
        throwsA(
          isA<SecureStoreException>().having(
            (error) => error.code,
            'code',
            SecureStoreError.unknown,
          ),
        ),
      );
    });
  });
}
