// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:typed_data';

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/media/media_store.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'media_test_utils.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late EntryRepo entryRepo;
  late MediaStore store;

  setUpAll(initTimezoneData);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('dayz_media_store_test');
    db = AppDatabase(NativeDatabase.memory());
    entryRepo = EntryRepo(db);
    store = MediaStore(
      keyProvider: _FakeMediaKeyProvider(testKey()),
      mediaRepo: MediaRepo(db),
      documentsDirectoryProvider: () async => tempDir,
      idGenerator: () => 'media-id-1',
    );
  });

  tearDown(() async {
    await db.close();
    tempDir.deleteSync(recursive: true);
  });

  test(
    'put writes encrypted file, metadata, and openRead restores bytes',
    () async {
      final entryId = await _createEntry(entryRepo);
      final plain = Uint8List.fromList(
        List<int>.generate(512, (i) => i & 0xff),
      );

      final relPath = await store.put(
        bytes: byteStream(plain),
        entryId: entryId,
        kind: MediaKind.image,
        mime: 'image/png',
        width: 32,
        height: 16,
        fileSize: plain.length,
      );

      expect(relPath, 'media/media-id-1.bin');
      final file = File(p.join(tempDir.path, relPath));
      expect(await file.exists(), isTrue);
      expect(await collectBytes(store.openRead(relPath)), plain);

      final row = await db.mediaDao.byId('media-id-1');
      expect(row, isNotNull);
      expect(row!.id, 'media-id-1');
      expect(row.relPath, relPath);
      expect(row.kind, 'image');
      expect(row.mime, 'image/png');
      expect(row.width, 32);
      expect(row.height, 16);
      expect(row.fileSize, plain.length);
    },
  );

  test('put removes encrypted file when metadata insert fails', () async {
    final failingStore = MediaStore.withRepository(
      loadDeviceMediaKey: () async => testKey(),
      metadataRepository: _FailingMetadataRepository(),
      documentsDirectoryProvider: () async => tempDir,
      idGenerator: () => 'media-id-fail',
    );

    await expectLater(
      failingStore.put(
        bytes: byteStream([1, 2, 3]),
        entryId: 'entry-missing',
        kind: MediaKind.image,
        mime: 'image/png',
        fileSize: 3,
      ),
      throwsA(isA<StateError>()),
    );

    expect(
      await File(p.join(tempDir.path, 'media', 'media-id-fail.bin')).exists(),
      isFalse,
    );
    expect(
      await File(
        p.join(tempDir.path, 'media', 'media-id-fail.bin.tmp'),
      ).exists(),
      isFalse,
    );
  });

  test('hardDelete removes file and db row', () async {
    final entryId = await _createEntry(entryRepo);
    final relPath = await store.put(
      bytes: byteStream([1, 2, 3]),
      entryId: entryId,
      kind: MediaKind.image,
      mime: 'image/png',
      fileSize: 3,
    );

    await store.hardDelete('media-id-1');

    expect(await File(p.join(tempDir.path, relPath)).exists(), isFalse);
    expect(await db.mediaDao.byId('media-id-1'), isNull);
  });

  test('hardDelete repairs missing-file db row by deleting metadata', () async {
    final entryId = await _createEntry(entryRepo);
    final relPath = await store.put(
      bytes: byteStream([1, 2, 3]),
      entryId: entryId,
      kind: MediaKind.image,
      mime: 'image/png',
      fileSize: 3,
    );
    await File(p.join(tempDir.path, relPath)).delete();

    await store.hardDelete('media-id-1');

    expect(await db.mediaDao.byId('media-id-1'), isNull);
  });

  test('softDelete marks metadata deleted and keeps encrypted file', () async {
    final entryId = await _createEntry(entryRepo);
    final relPath = await store.put(
      bytes: byteStream([1, 2, 3]),
      entryId: entryId,
      kind: MediaKind.image,
      mime: 'image/png',
      fileSize: 3,
    );

    await store.softDelete('media-id-1');

    final row = await db.mediaDao.byId('media-id-1');
    expect(row, isNotNull);
    expect(row!.deletedAt, isNotNull);
    expect(await File(p.join(tempDir.path, relPath)).exists(), isTrue);
  });
}

Future<String> _createEntry(EntryRepo entryRepo) async {
  final entry = await entryRepo.create(
    contentJson: '{"insert":"media"}',
    contentPlain: 'media',
    entryDtUtc: DateTime.utc(2026, 5, 30),
    entryTz: 'UTC',
  );
  return entry.id;
}

class _FakeMediaKeyProvider extends Fake implements KeyProvider {
  final Uint8List key;

  _FakeMediaKeyProvider(this.key);

  @override
  Future<Uint8List> getDeviceMediaKey() async => Uint8List.fromList(key);
}

class _FailingMetadataRepository implements MediaMetadataRepository {
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
  }) async {
    throw StateError('db failed');
  }

  @override
  Future<void> hardDelete(String id) async {}

  @override
  Future<void> softDelete(String id) async {}
}
