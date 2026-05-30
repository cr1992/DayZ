// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/security/argon2_kdf.dart';

void main() {
  group('KdfParams Persistence', () {
    test('KdfParams version roundtrip', () {
      final original = const KdfParams.v1();
      final json = original.toJson();
      
      // Verify json serialization
      expect(json['version'], 1);
      
      // Deserialize and verify reconstruction
      final reconstructed = KdfParams.fromJson(json);
      expect(reconstructed, original);
      
      // Detailed field verification
      expect(reconstructed.version, original.version);
      expect(reconstructed.mCostKiB, original.mCostKiB);
      expect(reconstructed.tCost, original.tCost);
      expect(reconstructed.parallelism, original.parallelism);
      expect(reconstructed.outputLen, original.outputLen);
    });

    test('KdfParams throws ArgumentError for unknown versions', () {
      expect(
        () => KdfParams.fromJson({'version': 999}),
        throwsArgumentError,
      );
    });
  });
}
