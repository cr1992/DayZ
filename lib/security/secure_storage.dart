// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum SecureStoreError { unavailable, corrupted, unknown }

class SecureStoreException implements Exception {
  final SecureStoreError code;
  final dynamic original;

  SecureStoreException(this.code, this.original);

  @override
  String toString() => 'SecureStoreException(code: $code, original: $original)';
}

class SecureStore {
  final FlutterSecureStorage _storage;

  SecureStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> set(String key, Uint8List bytes) async {
    try {
      final base64String = base64Encode(bytes);
      await _storage.write(key: key, value: base64String);
    } catch (error) {
      throw _wrapException(error);
    }
  }

  Future<Uint8List?> get(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value == null) {
        return null;
      }
      try {
        return base64Decode(value);
      } catch (error) {
        throw SecureStoreException(SecureStoreError.corrupted, error);
      }
    } catch (error) {
      if (error is SecureStoreException) {
        rethrow;
      }
      throw _wrapException(error);
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (error) {
      throw _wrapException(error);
    }
  }

  Future<bool> contains(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (error) {
      throw _wrapException(error);
    }
  }

  SecureStoreException _wrapException(dynamic error) {
    if (error is MissingPluginException) {
      return SecureStoreException(SecureStoreError.unavailable, error);
    }

    if (error is PlatformException) {
      final message = error.message?.toLowerCase() ?? '';
      final code = error.code.toLowerCase();

      if (message.contains('badpadding') ||
          message.contains('decrypt') ||
          code.contains('badpadding')) {
        return SecureStoreException(SecureStoreError.corrupted, error);
      }

      if (code.contains('unavailable') ||
          code.contains('missing_plugin') ||
          message.contains('unavailable') ||
          message.contains('not available') ||
          message.contains('missingplugin') ||
          message.contains('no implementation found') ||
          message.contains('keystore') ||
          message.contains('keychain')) {
        return SecureStoreException(SecureStoreError.unavailable, error);
      }

      return SecureStoreException(SecureStoreError.unknown, error);
    }

    return SecureStoreException(SecureStoreError.unknown, error);
  }
}
