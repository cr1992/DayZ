// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/backup/backup_format.dart';
import 'package:dayz/backup/exceptions.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dayz_backup_format_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Write and read identical BackupHeader', () async {
    final file = File(p.join(tempDir.path, 'test_backup.mydiary'));
    final header = BackupHeader(
      magic: backupMagic,
      version: backupVersion,
      salt: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
      encryptedPayloadSize: 1024,
    );

    // Write header
    final sink = file.openWrite();
    writeHeader(sink, header);
    await sink.flush();
    await sink.close();

    // Read header
    final raf = await file.open(mode: FileMode.read);
    try {
      final read = await readHeader(raf);
      expect(read, equals(header));
    } finally {
      await raf.close();
    }
  });

  test('Throws InvalidBackupFormatException on bad magic', () async {
    final file = File(p.join(tempDir.path, 'bad_magic.mydiary'));
    final header = BackupHeader(
      magic: 'BADMAGIC',
      version: backupVersion,
      salt: Uint8List.fromList([1, 2, 3, 4]),
      encryptedPayloadSize: 100,
    );

    final sink = file.openWrite();
    writeHeader(sink, header);
    await sink.flush();
    await sink.close();

    final raf = await file.open(mode: FileMode.read);
    try {
      await expectLater(
        readHeader(raf),
        throwsA(isA<InvalidBackupFormatException>()),
      );
    } finally {
      await raf.close();
    }
  });

  test('Throws SchemaIncompatible on unsupported version', () async {
    final file = File(p.join(tempDir.path, 'bad_version.mydiary'));
    final header = BackupHeader(
      magic: backupMagic,
      version: 99, // unsupported version
      salt: Uint8List.fromList([1, 2, 3, 4]),
      encryptedPayloadSize: 100,
    );

    final sink = file.openWrite();
    writeHeader(sink, header);
    await sink.flush();
    await sink.close();

    final raf = await file.open(mode: FileMode.read);
    try {
      await expectLater(readHeader(raf), throwsA(isA<SchemaIncompatible>()));
    } finally {
      await raf.close();
    }
  });
}
