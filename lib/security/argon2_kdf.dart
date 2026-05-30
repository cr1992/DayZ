// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:typed_data';

import 'package:argon2id_ffi/argon2id_ffi.dart';

class KdfParams {
  final int mCostKiB;
  final int tCost;
  final int parallelism;
  final int outputLen;
  final int version;

  const KdfParams({
    required this.mCostKiB,
    required this.tCost,
    required this.parallelism,
    required this.outputLen,
    required this.version,
  });

  const KdfParams.v1()
    : mCostKiB = 65536,
      tCost = 3,
      parallelism = 1,
      outputLen = 32,
      version = 1;

  static KdfParams fromVersion(int version) {
    switch (version) {
      case 1:
        return const KdfParams.v1();
      default:
        throw ArgumentError('Unknown version: $version');
    }
  }

  Map<String, Object?> toJson() => {'version': version};

  factory KdfParams.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['version'];
    final version = switch (rawVersion) {
      int value => value,
      num value when value == value.toInt() => value.toInt(),
      _ => null,
    };
    if (version == null) {
      throw ArgumentError('Missing or invalid version: $rawVersion');
    }
    return KdfParams.fromVersion(version);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KdfParams &&
          runtimeType == other.runtimeType &&
          mCostKiB == other.mCostKiB &&
          tCost == other.tCost &&
          parallelism == other.parallelism &&
          outputLen == other.outputLen &&
          version == other.version;

  @override
  int get hashCode =>
      Object.hash(mCostKiB, tCost, parallelism, outputLen, version);
}

class Argon2Kdf {
  /// Argon2id 派生（后端 = 自研 `argon2id_ffi`，RustCrypto + 手写 dart:ffi）。
  /// 算法/版本(0x13)/参数与原 dargon2 一致——相同入参派生密钥逐字节相同，切换不改密钥。
  /// 重活在 argon2id_ffi 内部跑在 Isolate，不阻塞 UI；无需初始化。
  static Future<Uint8List> deriveKey(
    Uint8List password,
    Uint8List salt,
    KdfParams params,
  ) async {
    try {
      return await argon2idDeriveKey(
        password: password,
        salt: salt,
        mCost: params.mCostKiB,
        tCost: params.tCost,
        parallelism: params.parallelism,
        outputLen: params.outputLen,
      );
    } finally {
      _zero(password);
    }
  }

  static void _zero(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }
}
