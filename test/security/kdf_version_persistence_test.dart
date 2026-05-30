// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/security/argon2_kdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KdfParams persistence', () {
    test('version roundtrip 后可重建逐字段相等的参数', () {
      final original = const KdfParams.v1();
      final json = original.toJson();
      final reconstructed = KdfParams.fromJson(Map<String, dynamic>.from(json));

      expect(json['version'], 1);
      expect(reconstructed, original);
      expect(reconstructed.version, original.version);
      expect(reconstructed.mCostKiB, original.mCostKiB);
      expect(reconstructed.tCost, original.tCost);
      expect(reconstructed.parallelism, original.parallelism);
      expect(reconstructed.outputLen, original.outputLen);
    });

    test('未知 version 抛 ArgumentError', () {
      expect(() => KdfParams.fromJson({'version': 999}), throwsArgumentError);
    });

    test('缺失或非法 version 抛 ArgumentError', () {
      expect(() => KdfParams.fromJson({}), throwsArgumentError);
      expect(() => KdfParams.fromJson({'version': 'v1'}), throwsArgumentError);
    });
  });
}
