// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum SecureStoreError {
  unavailable,
  corrupted,
  unknown,
}

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
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  Future<void> set(String key, Uint8List bytes) async {
    try {
      final base64String = base64Encode(bytes);
      await _storage.write(key: key, value: base64String);
    } catch (e) {
      throw _wrapException(e);
    }
  }

  Future<Uint8List?> get(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value == null) return null;
      try {
        return base64Decode(value);
      } catch (e) {
        throw SecureStoreException(SecureStoreError.corrupted, e);
      }
    } catch (e) {
      if (e is SecureStoreException) {
        rethrow;
      }
      throw _wrapException(e);
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw _wrapException(e);
    }
  }

  Future<bool> contains(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      throw _wrapException(e);
    }
  }

  SecureStoreException _wrapException(dynamic e) {
    if (e is PlatformException) {
      final message = e.message?.toLowerCase() ?? '';
      final code = e.code.toLowerCase();
      if (message.contains('badpadding') || message.contains('decrypt') || code.contains('badpadding')) {
        return SecureStoreException(SecureStoreError.corrupted, e);
      }
      return SecureStoreException(SecureStoreError.unknown, e);
    }
    return SecureStoreException(SecureStoreError.unknown, e);
  }
}
