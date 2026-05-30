// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';
import 'dart:typed_data';
import 'package:dayz/security/secure_storage.dart';

class DeviceKey {
  static const String _keyName = 'device_db_key';

  static Future<bool> exists({SecureStore? store}) async {
    final s = store ?? SecureStore();
    return await s.contains(_keyName);
  }

  static Future<Uint8List> ensure({SecureStore? store, Random? random}) async {
    final s = store ?? SecureStore();
    final r = random ?? Random.secure();
    
    final keyExists = await exists(store: s);
    if (keyExists) {
      final key = await s.get(_keyName);
      if (key == null) {
        throw SecureStoreException(
          SecureStoreError.corrupted,
          'Key flag exists but value is null',
        );
      }
      return key;
    } else {
      final newKey = Uint8List.fromList(
        List<int>.generate(32, (i) => r.nextInt(256)),
      );
      await s.set(_keyName, newKey);
      return newKey;
    }
  }
}
