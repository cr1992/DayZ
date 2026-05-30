// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' show Value;
import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/media/media_store.dart';
import 'package:dayz/thumbnails/thumbnail_cache.dart';
import 'package:dayz/backup/backup_exporter.dart';
import 'package:dayz/backup/backup_restorer.dart';

class TestKeyProvider extends KeyProvider {
  final Uint8List _appKey;
  final Uint8List _mediaKey;

  TestKeyProvider(this._appKey, this._mediaKey);

  @override
  Future<Uint8List> getAppDbKey() async => Uint8List.fromList(_appKey);

  @override
  Future<Uint8List> getDeviceMediaKey() async => Uint8List.fromList(_mediaKey);

  @override
  Future<Uint8List> deriveBackupKey(Uint8List password, Uint8List salt) async {
    final key = Uint8List(32);
    for (var i = 0; i < key.length; i++) {
      key[i] = password[i % password.length] ^ salt[i % salt.length] ^ i;
    }
    return key;
  }
}

void mockPathProvider(Directory documentsDir, Directory tempDir) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return documentsDir.path;
          }
          if (methodCall.method == 'getTemporaryDirectory') {
            return tempDir.path;
          }
          return null;
        },
      );
}

class SpyThumbnailCache extends ThumbnailCache {
  int warmupCallCount = 0;
  List<String>? warmupMediaIds;
  Completer<void>? warmupCompleter;

  SpyThumbnailCache({
    required super.mediaRepo,
    required super.keyProvider,
    required super.db,
    super.documentsDirectoryProvider,
  });

  @override
  void warmup(List<String> mediaIds) {
    warmupCallCount++;
    warmupMediaIds = List.from(mediaIds);
    if (warmupCompleter != null) {
      warmupCompleter!.future.then((_) {
        super.warmup(mediaIds);
      });
    } else {
      super.warmup(mediaIds);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Directory docsDir;
  late Directory tDir;

  late File originalDbFile;
  late AppDatabase originalDb;
  late TestKeyProvider keyProvider;

  final appKey = Uint8List.fromList(List.generate(32, (i) => i));
  final mediaKey = Uint8List.fromList(List.generate(32, (i) => i + 10));

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dayz_restorer_fts_test');
    docsDir = Directory(p.join(tempDir.path, 'documents'))
      ..createSync(recursive: true);
    tDir = Directory(p.join(tempDir.path, 'temp'))..createSync(recursive: true);
    mockPathProvider(docsDir, tDir);

    originalDbFile = File(p.join(docsDir.path, 'db', 'main.sqlite'));
    keyProvider = TestKeyProvider(appKey, mediaKey);

    originalDb = await AppDatabase.openFile(
      originalDbFile,
      Uint8List.fromList(appKey),
    );
  });

  tearDown(() async {
    try {
      await originalDb.close();
    } catch (_) {}
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('restore rebuilds FTS and runs thumbnail warmup asynchronously', () async {
    // 1. Create a backup file representing a database with 2 entries and 2 media files
    final backupDbFile = File(p.join(tempDir.path, 'backup_src.sqlite'));
    final backupDb = await AppDatabase.openFile(
      backupDbFile,
      Uint8List.fromList(appKey),
    );
    final backupMediaStore = MediaStore(
      keyProvider: keyProvider,
      mediaRepo: MediaRepo(backupDb),
      documentsDirectoryProvider: () async => docsDir,
    );

    final now = DateTime.utc(2026, 5, 30, 10);
    await backupDb.entriesDao.insertEntry(
      EntriesCompanion.insert(
        id: 'entry_a',
        contentPlain: const Value('Apple banana orange'),
        entryDtUtc: now,
        entryTz: 'UTC',
        localYear: 2026,
        localMonth: 5,
        localDay: 30,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await backupDb.entriesDao.insertEntry(
      EntriesCompanion.insert(
        id: 'entry_b',
        contentPlain: const Value('Grape pineapple strawberry'),
        entryDtUtc: now,
        entryTz: 'UTC',
        localYear: 2026,
        localMonth: 5,
        localDay: 30,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await backupMediaStore.put(
      bytes: Stream.value(utf8.encode('Image A')),
      entryId: 'entry_a',
      kind: MediaKind.image,
      mime: 'image/png',
    );
    await backupMediaStore.put(
      bytes: Stream.value(utf8.encode('Image B')),
      entryId: 'entry_b',
      kind: MediaKind.image,
      mime: 'image/jpeg',
    );

    final mediaRecords = await backupDb.mediaDao.active().get();
    expect(mediaRecords.length, equals(2));
    final mediaIds = mediaRecords.map((m) => m.id).toList();

    final backupFile = File(p.join(tempDir.path, 'backup.mydiary'));
    final exporter = BackupExporter(
      database: backupDb,
      keyProvider: keyProvider,
    );
    await exporter.export(
      password: 'restorepassword',
      outputPath: backupFile.path,
      onProgress: (_, _, _) {},
    );
    await backupDb.close();

    // 2. Perform parse
    final parseRestorer = BackupRestorer(
      database: originalDb,
      keyProvider: keyProvider,
    );
    final session = await parseRestorer.parseAndConfirm(
      inputPath: backupFile.path,
      password: 'restorepassword',
      confirmOverwrite: () async => true,
    );

    // 3. Inject a SpyThumbnailCache that hangs warmup
    final spyWarmupCompleter = Completer<void>();
    final spyCache = SpyThumbnailCache(
      mediaRepo: MediaRepo(
        originalDb,
      ), // db will be closed/replaced, but spyCache constructor just takes it
      keyProvider: keyProvider,
      db: originalDb,
      documentsDirectoryProvider: () async => docsDir,
    )..warmupCompleter = spyWarmupCompleter;

    final restorer = BackupRestorer(
      database: originalDb,
      keyProvider: keyProvider,
      thumbnailCache: spyCache,
    );

    // 4. Time the apply operation to ensure it is asynchronous and does not await warmup
    final stopwatch = Stopwatch()..start();
    final restoredDb = await restorer.apply(session);
    stopwatch.stop();

    // Warmup is hung, so apply() must return quickly (e.g. < 50ms or < 200ms on slower CI machines)
    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(200),
      reason: 'Warmup must not block restore completion',
    );

    // 5. Verify FTS Table contents
    final ftsCountResult = await restoredDb
        .customSelect('SELECT count(*) FROM entries_fts;')
        .getSingle();
    final ftsCount = ftsCountResult.read<int>('count(*)');
    expect(ftsCount, equals(2));

    // Verify FTS query actually matches terms
    final searchResult = await restoredDb
        .customSelect(
          "SELECT rowid FROM entries_fts WHERE entries_fts MATCH 'banana';",
        )
        .getSingleOrNull();
    expect(searchResult, isNotNull);

    // 6. Verify warmup spy behavior
    expect(spyCache.warmupCallCount, equals(1));
    expect(spyCache.warmupMediaIds, containsAll(mediaIds));

    // Verify thumbs directory remains empty since warmup is hung
    final thumbsDir = Directory(p.join(docsDir.path, 'thumbs'));
    final thumbsExist = await thumbsDir.exists();
    if (thumbsExist) {
      final files = await thumbsDir.list().toList();
      expect(files, isEmpty);
    }

    await restoredDb.close();
  });
}
