// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dayz/security/argon2_kdf.dart';
import 'package:dayz/security/device_key.dart';
import 'package:dayz/security/hkdf.dart';
import 'package:dayz/security/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppPasswordMode { none, password }

typedef PreferencesFactory = Future<SharedPreferences> Function();
typedef Argon2Deriver =
    Future<Uint8List> Function(
      Uint8List password,
      Uint8List salt,
      KdfParams params,
    );

class KeyProviderLocked implements Exception {
  const KeyProviderLocked();

  @override
  String toString() => 'KeyProviderLocked()';
}

class KeyProviderConfigurationException implements Exception {
  final String message;

  const KeyProviderConfigurationException(this.message);

  @override
  String toString() => 'KeyProviderConfigurationException($message)';
}

class KeyProvider {
  static const String modePrefKey = 'app_password_mode';
  static const String passwordSaltStorageKey = 'app_password_salt';
  static const String passwordKdfParamsPrefKey = 'app_password_kdf_params';
  static const int backupSaltLength = 16;
  static const String deviceMediaInfo = 'dayz/media/v1';
  static const int deviceMediaKeyLength = 32;

  final SecureStore _store;
  final PreferencesFactory _preferencesFactory;
  final Argon2Deriver _argon2Deriver;
  final HkdfSha256Deriver _hkdfDeriver;
  final Random _random;

  Uint8List? _unlockedDbKey;

  KeyProvider({
    SecureStore? store,
    PreferencesFactory? preferencesFactory,
    Argon2Deriver? argon2Deriver,
    HkdfSha256Deriver? hkdfDeriver,
    Random? random,
  }) : _store = store ?? SecureStore(),
       _preferencesFactory =
           preferencesFactory ?? SharedPreferences.getInstance,
       _argon2Deriver = argon2Deriver ?? Argon2Kdf.deriveKey,
       _hkdfDeriver = hkdfDeriver ?? Hkdf.deriveSha256,
       _random = random ?? Random.secure();

  Future<AppPasswordMode> currentMode() async {
    final prefs = await _preferencesFactory();
    return _decodeMode(prefs.getString(modePrefKey));
  }

  Future<Uint8List> getAppDbKey() async {
    switch (await currentMode()) {
      case AppPasswordMode.none:
        final deviceKey = await DeviceKey.ensure(store: _store);
        try {
          return Uint8List.fromList(deviceKey);
        } finally {
          _zero(deviceKey);
        }
      case AppPasswordMode.password:
        final cached = _unlockedDbKey;
        if (cached == null) {
          throw const KeyProviderLocked();
        }
        return Uint8List.fromList(cached);
    }
  }

  Future<void> unlockWithPassword(Uint8List password) async {
    try {
      if (await currentMode() != AppPasswordMode.password) {
        return;
      }

      final salt = await _loadPasswordSalt();
      final params = await _loadPasswordKdfParams();
      final derived = await _argon2Deriver(password, salt, params);
      _replaceUnlockedDbKey(derived);
    } finally {
      _zero(password);
    }
  }

  void lock() {
    final cached = _unlockedDbKey;
    if (cached != null) {
      _zero(cached);
      _unlockedDbKey = null;
    }
  }

  /// 备份口令派生接口。复用统一的 Argon2id 参数版本，不预设它与主密码存在关联。
  Future<Uint8List> deriveBackupKey(Uint8List password, Uint8List salt) async {
    if (password.isEmpty) {
      _zero(password);
      throw ArgumentError.value(password, 'password', '备份口令不能为空');
    }
    if (salt.isEmpty) {
      _zero(password);
      throw ArgumentError.value(salt, 'salt', '备份盐不能为空');
    }

    return _argon2Deriver(password, salt, const KdfParams.v1());
  }

  /// 生成 16 字节 CSPRNG 备份盐，供 backup-full-snapshot 直接消费。
  Uint8List generateBackupSalt() {
    return Uint8List.fromList(
      List<int>.generate(backupSaltLength, (_) => _random.nextInt(256)),
    );
  }

  Future<Uint8List> getDeviceMediaKey() async {
    final deviceRootKey = await DeviceKey.ensure(store: _store);
    try {
      return _hkdfDeriver(
        ikm: deviceRootKey,
        salt: null,
        info: Uint8List.fromList(utf8.encode(deviceMediaInfo)),
        outputLen: deviceMediaKeyLength,
      );
    } finally {
      _zero(deviceRootKey);
    }
  }

  Future<KdfParams> _loadPasswordKdfParams() async {
    final prefs = await _preferencesFactory();
    final raw = prefs.getString(passwordKdfParamsPrefKey);
    if (raw == null || raw.isEmpty) {
      return const KdfParams.v1();
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const KeyProviderConfigurationException(
        'app password KDF params 格式非法',
      );
    }
    return KdfParams.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<Uint8List> _loadPasswordSalt() async {
    final salt = await _store.get(passwordSaltStorageKey);
    if (salt == null) {
      throw const KeyProviderConfigurationException('password mode salt 不存在');
    }
    return salt;
  }

  void _replaceUnlockedDbKey(Uint8List nextKey) {
    final previous = _unlockedDbKey;
    _unlockedDbKey = Uint8List.fromList(nextKey);
    _zero(nextKey);
    if (previous != null) {
      _zero(previous);
    }
  }

  static AppPasswordMode _decodeMode(String? raw) {
    return switch (raw) {
      'password' => AppPasswordMode.password,
      _ => AppPasswordMode.none,
    };
  }

  static void _zero(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }
}
