// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// @Ray

import 'dart:io';
import 'dart:typed_data';
import 'exceptions.dart';

const String backupMagic = 'MYDIARY\x00';
const int backupVersion = 1;

class BackupHeader {
  final String magic;
  final int version;
  final Uint8List salt;
  final int encryptedPayloadSize;

  const BackupHeader({
    required this.magic,
    required this.version,
    required this.salt,
    required this.encryptedPayloadSize,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupHeader &&
          runtimeType == other.runtimeType &&
          magic == other.magic &&
          version == other.version &&
          _bytesEquals(salt, other.salt) &&
          encryptedPayloadSize == other.encryptedPayloadSize;

  @override
  int get hashCode =>
      magic.hashCode ^
      version.hashCode ^
      salt.hashCode ^
      encryptedPayloadSize.hashCode;

  static bool _bytesEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Writes the backup header to [sink].
void writeHeader(IOSink sink, BackupHeader header) {
  final magicBytes = Uint8List.fromList(header.magic.codeUnits);
  if (magicBytes.length != 8) {
    throw ArgumentError('Magic must be exactly 8 bytes long');
  }
  sink.add(magicBytes);

  sink.add([header.version]);

  final saltLen = header.salt.length;
  final saltLenBytes = Uint8List(2);
  final saltLenData = ByteData.view(saltLenBytes.buffer);
  saltLenData.setUint16(0, saltLen, Endian.big);
  sink.add(saltLenBytes);

  sink.add(header.salt);

  final payloadSizeBytes = Uint8List(8);
  final payloadSizeData = ByteData.view(payloadSizeBytes.buffer);
  payloadSizeData.setUint64(0, header.encryptedPayloadSize, Endian.big);
  sink.add(payloadSizeBytes);
}

/// Reads the backup header from a [RandomAccessFile].
/// Throws [InvalidBackupFormatException] if magic or version mismatch.
Future<BackupHeader> readHeader(RandomAccessFile file) async {
  // 1. Read magic (8 bytes)
  final magicBytes = await file.read(8);
  if (magicBytes.length < 8) {
    throw const InvalidBackupFormatException('File too short to read magic');
  }
  final magic = String.fromCharCodes(magicBytes);
  if (magic != backupMagic) {
    throw InvalidBackupFormatException('Invalid magic: expected $backupMagic');
  }

  // 2. Read version (1 byte)
  final versionBytes = await file.read(1);
  if (versionBytes.isEmpty) {
    throw const InvalidBackupFormatException('File too short to read version');
  }
  final version = versionBytes[0];
  if (version != backupVersion) {
    throw SchemaIncompatible('Unsupported backup version: $version');
  }

  // 3. Read salt len (2 bytes)
  final saltLenBytes = await file.read(2);
  if (saltLenBytes.length < 2) {
    throw const InvalidBackupFormatException(
      'File too short to read salt length',
    );
  }
  final saltLenData = ByteData.view(saltLenBytes.buffer);
  final saltLen = saltLenData.getUint16(0, Endian.big);

  // 4. Read salt (saltLen bytes)
  final salt = await file.read(saltLen);
  if (salt.length < saltLen) {
    throw const InvalidBackupFormatException('File too short to read salt');
  }

  // 5. Read payload size (8 bytes)
  final payloadSizeBytes = await file.read(8);
  if (payloadSizeBytes.length < 8) {
    throw const InvalidBackupFormatException(
      'File too short to read payload size',
    );
  }
  final payloadSizeData = ByteData.view(payloadSizeBytes.buffer);
  final payloadSize = payloadSizeData.getUint64(0, Endian.big);

  return BackupHeader(
    magic: magic,
    version: version,
    salt: salt,
    encryptedPayloadSize: payloadSize,
  );
}
