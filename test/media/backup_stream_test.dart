// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:typed_data';

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/media/media_codec.dart';
import 'package:dayz/media/media_store.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'media_test_utils.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late MediaStore store;
  late EntryRepo entryRepo;

  setUpAll(initTimezoneData);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('dayz_media_backup_test');
    db = AppDatabase(NativeDatabase.memory());
    entryRepo = EntryRepo(db);
    store = MediaStore(
      keyProvider: _FakeMediaKeyProvider(testKey()),
      mediaRepo: MediaRepo(db),
      documentsDirectoryProvider: () async => tempDir,
      idGenerator: () => 'media-backup-id',
    );
  });

  tearDown(() async {
    await db.close();
    tempDir.deleteSync(recursive: true);
  });

  test(
    'streamForBackup can be piped into encryptForBackup without temp files',
    () async {
      final entry = await entryRepo.create(
        contentJson: '{"insert":"backup"}',
        contentPlain: 'backup',
        entryDtUtc: DateTime.utc(2026, 5, 30),
        entryTz: 'UTC',
      );
      final plain = Uint8List.fromList(
        List<int>.generate(4096, (i) => i & 0xff),
      );
      final relPath = await store.put(
        bytes: byteStream(plain),
        entryId: entry.id,
        kind: MediaKind.image,
        mime: 'image/png',
        fileSize: plain.length,
      );

      final backupKey = testKey(44);
      final backupCipher = await collectBytes(
        store.encryptForBackup(store.streamForBackup(relPath), backupKey),
      );
      final restored = await collectBytes(
        MediaCodec().decrypt(cipher: byteStream(backupCipher), key: backupKey),
      );

      expect(restored, plain);
      final tempFiles = await Directory(
        '${tempDir.path}/media',
      ).list().where((entity) => entity.path.endsWith('.tmp')).toList();
      expect(tempFiles, isEmpty);
    },
  );
}

class _FakeMediaKeyProvider extends Fake implements KeyProvider {
  final Uint8List key;

  _FakeMediaKeyProvider(this.key);

  @override
  Future<Uint8List> getDeviceMediaKey() async => Uint8List.fromList(key);
}
