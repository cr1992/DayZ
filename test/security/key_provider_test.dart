// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dayz/security/argon2_kdf.dart';
import 'package:dayz/security/hkdf.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/security/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_test.dart';

Uint8List _ascii(String value) => Uint8List.fromList(value.codeUnits);
Uint8List _hexBytes(String hex) {
  final normalized = hex.replaceAll(RegExp(r'\s+'), '');
  return Uint8List.fromList([
    for (var i = 0; i < normalized.length; i += 2)
      int.parse(normalized.substring(i, i + 2), radix: 16),
  ]);
}

String _hex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

class _SequenceRandom extends Fake implements Random {
  final List<int> values;
  int _index = 0;

  _SequenceRandom(this.values);

  @override
  int nextInt(int max) {
    final value = values[_index % values.length];
    _index += 1;
    return value % max;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KeyProvider', () {
    late FakeFlutterSecureStorage fakeStorage;
    late SecureStore secureStore;
    late SharedPreferences prefs;

    KeyProvider buildProvider({Random? random}) {
      return KeyProvider(
        store: secureStore,
        preferencesFactory: () async => prefs,
        random: random,
      );
    }

    Future<void> seedDeviceKey([Uint8List? bytes]) async {
      await secureStore.set(
        'device_db_key',
        bytes ??
            Uint8List.fromList(List<int>.generate(32, (index) => index + 1)),
      );
    }

    Future<void> seedPasswordMode({
      required Uint8List salt,
      KdfParams params = const KdfParams.v1(),
    }) async {
      await prefs.setString(KeyProvider.modePrefKey, 'password');
      await prefs.setString(
        KeyProvider.passwordKdfParamsPrefKey,
        jsonEncode(params.toJson()),
      );
      await secureStore.set(KeyProvider.passwordSaltStorageKey, salt);
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      fakeStorage = FakeFlutterSecureStorage();
      secureStore = SecureStore(storage: fakeStorage);
    });

    test('mode=none 时 getAppDbKey 返回 DeviceKey', () async {
      final provider = buildProvider();
      final deviceKey = Uint8List.fromList(
        List<int>.generate(32, (index) => index),
      );
      await seedDeviceKey(deviceKey);

      expect(await provider.currentMode(), AppPasswordMode.none);
      expect(await provider.getAppDbKey(), equals(deviceKey));
    });

    test('mode=password 且未 unlock 时 getAppDbKey 抛 KeyProviderLocked', () async {
      final provider = buildProvider();
      await seedDeviceKey();
      await seedPasswordMode(salt: _ascii('unlock-salt-1234'));

      expect(provider.getAppDbKey, throwsA(isA<KeyProviderLocked>()));
    });

    test('unlockWithPassword + getAppDbKey 返回派生密钥', () async {
      final provider = buildProvider();
      final password = _ascii('unlock-me');
      final salt = _ascii('unlock-salt-1234');
      await seedDeviceKey();
      await seedPasswordMode(salt: salt);

      final expected = await Argon2Kdf.deriveKey(
        _ascii('unlock-me'),
        Uint8List.fromList(salt),
        const KdfParams.v1(),
      );

      await provider.unlockWithPassword(password);
      expect(await provider.getAppDbKey(), equals(expected));
    });

    test('deriveBackupKey 与 Argon2Kdf.deriveKey 输出一致', () async {
      final provider = buildProvider();
      final salt = _ascii('backup-salt-1234');

      final derived = await provider.deriveBackupKey(
        _ascii('backup-password'),
        Uint8List.fromList(salt),
      );
      final expected = await Argon2Kdf.deriveKey(
        _ascii('backup-password'),
        Uint8List.fromList(salt),
        const KdfParams.v1(),
      );

      expect(derived, equals(expected));
    });

    test('deriveBackupKey 相同输入一致、不同 salt 不同、空输入抛错', () async {
      final provider = buildProvider();
      final saltA = _ascii('backup-salt-1234');
      final saltB = _ascii('backup-salt-1235');

      final out1 = await provider.deriveBackupKey(
        _ascii('backup-password'),
        Uint8List.fromList(saltA),
      );
      final out2 = await provider.deriveBackupKey(
        _ascii('backup-password'),
        Uint8List.fromList(saltA),
      );
      final out3 = await provider.deriveBackupKey(
        _ascii('backup-password'),
        Uint8List.fromList(saltB),
      );

      expect(out1, equals(out2));
      expect(out1, isNot(equals(out3)));
      expect(
        () => provider.deriveBackupKey(Uint8List(0), Uint8List.fromList(saltA)),
        throwsArgumentError,
      );
      expect(
        () => provider.deriveBackupKey(_ascii('backup-password'), Uint8List(0)),
        throwsArgumentError,
      );
    });

    test('generateBackupSalt 返回 16 字节且连续调用结果不同', () {
      final provider = buildProvider(
        random: _SequenceRandom(List<int>.generate(32, (index) => index)),
      );

      final salt1 = provider.generateBackupSalt();
      final salt2 = provider.generateBackupSalt();

      expect(salt1.length, KeyProvider.backupSaltLength);
      expect(salt2.length, KeyProvider.backupSaltLength);
      expect(salt1, isNot(equals(salt2)));
      expect(
        salt1,
        equals(Uint8List.fromList(List<int>.generate(16, (index) => index))),
      );
      expect(
        salt2,
        equals(
          Uint8List.fromList(List<int>.generate(16, (index) => index + 16)),
        ),
      );
    });

    test('HKDF-SHA256 封装通过 RFC 5869 case 1/2/3', () async {
      final okm1 = await Hkdf.deriveSha256(
        ikm: _hexBytes('0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b'),
        salt: _hexBytes('000102030405060708090a0b0c'),
        info: _hexBytes('f0f1f2f3f4f5f6f7f8f9'),
        outputLen: 42,
      );
      expect(
        _hex(okm1),
        '3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865',
      );

      final okm2 = await Hkdf.deriveSha256(
        ikm: _hexBytes(
          '000102030405060708090a0b0c0d0e0f'
          '101112131415161718191a1b1c1d1e1f'
          '202122232425262728292a2b2c2d2e2f'
          '303132333435363738393a3b3c3d3e3f'
          '404142434445464748494a4b4c4d4e4f',
        ),
        salt: _hexBytes(
          '606162636465666768696a6b6c6d6e6f'
          '707172737475767778797a7b7c7d7e7f'
          '808182838485868788898a8b8c8d8e8f'
          '909192939495969798999a9b9c9d9e9f'
          'a0a1a2a3a4a5a6a7a8a9aaabacadaeaf',
        ),
        info: _hexBytes(
          'b0b1b2b3b4b5b6b7b8b9babbbcbdbebf'
          'c0c1c2c3c4c5c6c7c8c9cacbcccdcecf'
          'd0d1d2d3d4d5d6d7d8d9dadbdcdddedf'
          'e0e1e2e3e4e5e6e7e8e9eaebecedeeef'
          'f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff',
        ),
        outputLen: 82,
      );
      expect(
        _hex(okm2),
        'b11e398dc80327a1c8e7f78c596a49344f012eda2d4efad8a050cc4c19afa97c59045a99cac7827271cb41c65e590e09da3275600c2f09b8367793a9aca3db71cc30c58179ec3e87c14c01d5c1f3434f1d87',
      );

      final okm3 = await Hkdf.deriveSha256(
        ikm: _hexBytes('0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b'),
        salt: null,
        info: Uint8List(0),
        outputLen: 42,
      );
      expect(
        _hex(okm3),
        '8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d9d201395faa4b61a96c8',
      );
    });

    test('getDeviceMediaKey 输出等于独立 HKDF 重算且长度 32', () async {
      final provider = buildProvider();
      final deviceKey = Uint8List.fromList(
        List<int>.generate(32, (index) => index + 1),
      );
      await seedDeviceKey(deviceKey);

      final derived = await provider.getDeviceMediaKey();
      final expected = await Hkdf.deriveSha256(
        ikm: Uint8List.fromList(deviceKey),
        salt: null,
        info: _ascii(KeyProvider.deviceMediaInfo),
        outputLen: KeyProvider.deviceMediaKeyLength,
      );

      expect(derived.length, KeyProvider.deviceMediaKeyLength);
      expect(derived, equals(expected));
    });

    test('info 改变会导致媒体密钥输出变化', () async {
      final provider = buildProvider();
      final deviceKey = Uint8List.fromList(
        List<int>.generate(32, (index) => index + 1),
      );
      await seedDeviceKey(deviceKey);

      final mediaKey = await provider.getDeviceMediaKey();
      final differentInfoKey = await Hkdf.deriveSha256(
        ikm: Uint8List.fromList(deviceKey),
        salt: null,
        info: _ascii('dayz/media/v2'),
        outputLen: KeyProvider.deviceMediaKeyLength,
      );

      expect(mediaKey, isNot(equals(differentInfoKey)));
    });

    test('媒体密钥与 app db key 不同，且切换主密码模式前后结果不变', () async {
      final provider = buildProvider();
      final deviceKey = Uint8List.fromList(
        List<int>.generate(32, (index) => index + 1),
      );
      final passwordSalt = _ascii('unlock-salt-1234');
      await seedDeviceKey(deviceKey);

      final mediaKeyBefore = await provider.getDeviceMediaKey();
      final appDbKeyBefore = await provider.getAppDbKey();
      expect(mediaKeyBefore, isNot(equals(appDbKeyBefore)));

      await seedPasswordMode(salt: passwordSalt);
      await provider.unlockWithPassword(_ascii('unlock-me'));

      final mediaKeyAfter = await provider.getDeviceMediaKey();
      final appDbKeyAfter = await provider.getAppDbKey();
      expect(mediaKeyAfter, equals(mediaKeyBefore));
      expect(mediaKeyAfter, isNot(equals(appDbKeyAfter)));
    });
  });
}
