// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/backup/manifest.dart';
import 'package:dayz/backup/tar_stream.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dayz_tar_stream_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Manifest JSON roundtrip', () {
    test('serializes and deserializes accurately', () {
      final now = DateTime.now().toUtc();
      final manifest = Manifest(
        formatVersion: 1,
        backupType: 'full',
        schemaVersion: 1,
        generatedAt: now,
        appVersion: '1.2.3',
        entryCount: 42,
        mediaCount: 2,
        mediaIndex: [
          const ManifestMediaItem(id: 'media_1', mime: 'image/jpeg', size: 100),
          const ManifestMediaItem(id: 'media_2', mime: 'image/png', size: 200),
        ],
      );

      final jsonStr = manifest.toJsonString();
      final deserialized = Manifest.fromJsonString(jsonStr);

      expect(deserialized, equals(manifest));
      expect(
        deserialized.generatedAt.millisecondsSinceEpoch,
        equals(manifest.generatedAt.millisecondsSinceEpoch),
      );
    });
  });

  group('TarStreamWriter and TarStreamReader', () {
    test('writes and reads 3 entries correctly', () async {
      final outputFile = File(p.join(tempDir.path, 'test.tar'));
      final outputSink = outputFile.openWrite();

      final writer = TarStreamWriter(outputSink);

      final entry1Data = utf8.encode('Hello World from Entry 1!');
      final entry2Data = utf8.encode('Another entry here - Entry 2.');
      final entry3Data = utf8.encode('And the third entry content.');

      // Add as stream
      await writer.addEntry(
        'entry1.txt',
        Stream.value(entry1Data),
        size: entry1Data.length,
      );

      // Add as synchronous data
      await writer.addDataEntry('entry2.txt', entry2Data);

      // Add as stream without size specified
      await writer.addEntry('subdir/entry3.txt', Stream.value(entry3Data));

      await writer.close();
      await outputSink.close();

      // Read them back
      final inputStream = outputFile.openRead();
      final reader = TarStreamReader(inputStream);

      // Verify Entry 1
      expect(await reader.moveNext(), isTrue);
      expect(reader.name, equals('entry1.txt'));
      expect(reader.size, equals(entry1Data.length));
      final read1 = await reader.contents.fold<List<int>>(
        [],
        (p, e) => p..addAll(e),
      );
      expect(read1, equals(entry1Data));

      // Verify Entry 2
      expect(await reader.moveNext(), isTrue);
      expect(reader.name, equals('entry2.txt'));
      expect(reader.size, equals(entry2Data.length));
      final read2 = await reader.contents.fold<List<int>>(
        [],
        (p, e) => p..addAll(e),
      );
      expect(read2, equals(entry2Data));

      // Verify Entry 3
      expect(await reader.moveNext(), isTrue);
      expect(reader.name, equals('subdir/entry3.txt'));
      final read3 = await reader.contents.fold<List<int>>(
        [],
        (p, e) => p..addAll(e),
      );
      expect(read3, equals(entry3Data));

      // No more entries
      expect(await reader.moveNext(), isFalse);
      await reader.cancel();
    });
  });
}
