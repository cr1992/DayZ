// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dayz/data/database.dart';
import 'package:dayz/security/key_provider.dart';

enum RekeyProgressStage { copying, rekeying, cleaning, done }

typedef RekeyProgressCallback = void Function(RekeyProgressStage stage);
typedef AvailableBytesProvider = Future<int> Function(File dbFile);
typedef RekeyRunner = Future<void> Function(RekeyRequest request);

class RekeyRequest {
  final String dbPath;
  final Uint8List oldKey;
  final Uint8List newKey;

  RekeyRequest({
    required this.dbPath,
    required this.oldKey,
    required this.newKey,
  });
}

class InsufficientDiskSpaceException implements Exception {
  final int availableBytes;
  final int requiredBytes;

  const InsufficientDiskSpaceException({
    required this.availableBytes,
    required this.requiredBytes,
  });

  @override
  String toString() {
    return 'InsufficientDiskSpaceException(availableBytes: $availableBytes, requiredBytes: $requiredBytes)';
  }
}

class RekeyCleanupException implements Exception {
  final Object cause;

  const RekeyCleanupException(this.cause);

  @override
  String toString() => 'RekeyCleanupException(cause: $cause)';
}

class RekeyService {
  final File dbFile;
  final KeyProvider keyProvider;
  final AvailableBytesProvider availableBytesProvider;
  final RekeyRunner rekeyRunner;

  RekeyService({
    required this.dbFile,
    required this.keyProvider,
    required this.availableBytesProvider,
    RekeyRunner? rekeyRunner,
  }) : rekeyRunner = rekeyRunner ?? _runRekeyInIsolate;

  Future<void> rekey(
    Uint8List newKey, {
    RekeyProgressCallback? onProgress,
  }) async {
    final oldKey = await keyProvider.getAppDbKey();
    final backupFile = File('${dbFile.path}.bak');

    try {
      await _ensureSufficientDiskSpace();

      try {
        onProgress?.call(RekeyProgressStage.copying);
        await _copyReplacing(source: dbFile, target: backupFile);

        onProgress?.call(RekeyProgressStage.rekeying);
        await rekeyRunner(
          RekeyRequest(
            dbPath: dbFile.path,
            oldKey: Uint8List.fromList(oldKey),
            newKey: Uint8List.fromList(newKey),
          ),
        );
      } catch (_) {
        await _restoreBackupIfPresent(backupFile);
        rethrow;
      }

      onProgress?.call(RekeyProgressStage.cleaning);
      try {
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
      } catch (error) {
        throw RekeyCleanupException(error);
      }

      onProgress?.call(RekeyProgressStage.done);
    } finally {
      _zero(oldKey);
      _zero(newKey);
    }
  }

  Future<void> _ensureSufficientDiskSpace() async {
    final currentDbSize = await dbFile.length();
    final requiredBytes = ((currentDbSize * 12) + 9) ~/ 10;
    final availableBytes = await availableBytesProvider(dbFile);
    if (availableBytes < requiredBytes) {
      throw InsufficientDiskSpaceException(
        availableBytes: availableBytes,
        requiredBytes: requiredBytes,
      );
    }
  }

  static Future<void> _copyReplacing({
    required File source,
    required File target,
  }) async {
    if (await target.exists()) {
      await target.delete();
    }
    await source.copy(target.path);
  }

  Future<void> _restoreBackupIfPresent(File backupFile) async {
    if (!await backupFile.exists()) {
      return;
    }
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    await backupFile.copy(dbFile.path);
  }

  static Future<void> _runRekeyInIsolate(RekeyRequest request) {
    return Isolate.run(() => _rekeyStub(request));
  }

  static void _zero(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }
}

Future<void> _rekeyStub(RekeyRequest request) async {
  try {
    final db = await AppDatabase.openFile(
      File(request.dbPath),
      Uint8List.fromList(request.oldKey),
    );
    try {
      await db.rekey(Uint8List.fromList(request.newKey));
    } finally {
      await db.close();
    }
  } finally {
    for (var i = 0; i < request.oldKey.length; i++) {
      request.oldKey[i] = 0;
    }
    for (var i = 0; i < request.newKey.length; i++) {
      request.newKey[i] = 0;
    }
  }
}
