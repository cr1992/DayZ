// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:typed_data';

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/media/exceptions.dart';
import 'package:dayz/media/media_store.dart';
import 'package:dayz/media/paths.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'media_test_utils.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late EntryRepo entryRepo;

  setUpAll(initTimezoneData);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync(
      'dayz_media_path_safety_test',
    );
    db = AppDatabase(NativeDatabase.memory());
    entryRepo = EntryRepo(db);
  });

  tearDown(() async {
    await db.close();
    tempDir.deleteSync(recursive: true);
  });

  test(
    'public return values and exception messages do not expose absolute paths',
    () async {
      final store = MediaStore(
        keyProvider: _FakeMediaKeyProvider(testKey()),
        mediaRepo: MediaRepo(db),
        documentsDirectoryProvider: () async => tempDir,
        idGenerator: () => 'safe-id',
      );
      final entry = await entryRepo.create(
        contentJson: '{"insert":"safe"}',
        contentPlain: 'safe',
        entryDtUtc: DateTime.utc(2026, 5, 30),
        entryTz: 'UTC',
      );

      final relPath = await store.put(
        bytes: byteStream([1, 2, 3]),
        entryId: entry.id,
        kind: MediaKind.image,
        mime: 'image/png',
        fileSize: 3,
      );
      expect(relPath, 'media/safe-id.bin');
      expect(p.isAbsolute(relPath), isFalse);

      await _expectMediaExceptionWithoutAbsolutePath(
        () => collectBytes(store.openRead('media/missing.bin')),
        tempDir.path,
        isA<MediaNotFoundException>(),
      );

      final badFile = File(p.join(tempDir.path, 'media', 'bad.bin'));
      await badFile.parent.create(recursive: true);
      await badFile.writeAsBytes([1, 2, 3]);
      await _expectMediaExceptionWithoutAbsolutePath(
        () => collectBytes(store.openRead('media/bad.bin')),
        tempDir.path,
        isA<MediaCorruptedException>(),
      );
    },
  );

  test('KeyMissingException message does not expose absolute paths', () async {
    final store = MediaStore.withRepository(
      loadDeviceMediaKey: () async => throw StateError('no key'),
      metadataRepository: _NoopMetadataRepository(),
      documentsDirectoryProvider: () async => tempDir,
      idGenerator: () => 'missing-key-id',
    );

    await _expectMediaExceptionWithoutAbsolutePath(
      () => store.put(
        bytes: byteStream([1]),
        entryId: 'entry',
        kind: MediaKind.image,
        mime: 'image/png',
        fileSize: 1,
      ),
      tempDir.path,
      isA<KeyMissingException>(),
    );
  });

  test('relativize rejects outside documents paths', () {
    expect(
      () => relativizeWithDocumentsDir(
        p.join(tempDir.parent.path, 'outside.bin'),
        documentsPath: tempDir.path,
      ),
      throwsArgumentError,
    );
  });
}

Future<void> _expectMediaExceptionWithoutAbsolutePath(
  Future<void> Function() action,
  String absolutePrefix,
  Matcher matcher,
) async {
  Object? captured;
  try {
    await action();
  } catch (error) {
    captured = error;
  }

  expect(captured, matcher);
  expect(captured.toString(), isNot(contains(absolutePrefix)));
}

class _FakeMediaKeyProvider extends Fake implements KeyProvider {
  final Uint8List key;

  _FakeMediaKeyProvider(this.key);

  @override
  Future<Uint8List> getDeviceMediaKey() async => Uint8List.fromList(key);
}

class _NoopMetadataRepository implements MediaMetadataRepository {
  @override
  Future<void> addMeta(
    String id,
    String entryId,
    String kind,
    String relPath, {
    String? mime,
    int? width,
    int? height,
    int? durationMs,
    int? fileSize,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> hardDelete(String id) async {}

  @override
  Future<void> softDelete(String id) async {}
}
