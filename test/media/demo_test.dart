// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:typed_data';

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/demo/demo_entry.dart';
import 'package:dayz/media/demo.dart';
import 'package:dayz/media/media_store.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demos list contains Media demo entry', () {
    final entry = demos.firstWhere((demo) => demo.title == 'Media demo');
    expect(entry.subtitle, '媒体加密写入 / 读取 / 备份重加密');
  });

  testWidgets('Debug Home renders Media demo entry', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DebugHome()));

    await tester.scrollUntilVisible(
      find.text('Media demo'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Media demo'), findsOneWidget);
  });

  testWidgets('MediaDemo interactive flow writes image and encrypts backup verifying D2 header', (tester) async {
    final tempDir = Directory.systemTemp.createTempSync('dayz_media_demo_test');
    final db = AppDatabase(NativeDatabase.memory());
    final mediaRepo = MediaRepo(db);
    final store = MediaStore(
      keyProvider: _FakeMediaKeyProvider(Uint8List(32)),
      mediaRepo: mediaRepo,
      documentsDirectoryProvider: () async => tempDir,
      idGenerator: () => 'demo-media-id',
    );

    final demoImgFile = File('${tempDir.path}/media/demo-media-id.bin');
    final backupImgFile = File('${tempDir.path}/dayz_media_backup_demo.bin');

    await tester.pumpWidget(MaterialApp(
      home: MediaDemo(
        store: store,
        entryId: 'test-entry-id',
        loadDemoBytes: () async => Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]),
        createBackupFile: () async => backupImgFile,
        resolveMediaFile: (rel) async => demoImgFile,
      ),
    ));

    expect(find.byKey(const Key('media-demo-status')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('media-demo-status'))).data, 'Ready');

    // Use runAsync to allow real file IO and encryption to process
    await tester.runAsync(() async {
      // 1. Write demo image
      await tester.tap(find.byKey(const Key('media-demo-write')));
      for (var i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        final status = tester.widget<Text>(find.byKey(const Key('media-demo-status'))).data;
        if (status != null && status.startsWith('Written:')) {
          break;
        }
      }
    });
    expect(tester.widget<Text>(find.byKey(const Key('media-demo-status'))).data, startsWith('Written:'));

    // 2. Read and verify
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('media-demo-read')));
      for (var i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        final status = tester.widget<Text>(find.byKey(const Key('media-demo-status'))).data;
        if (status == 'Verified: sha256 match') {
          break;
        }
      }
    });
    expect(tester.widget<Text>(find.byKey(const Key('media-demo-status'))).data, 'Verified: sha256 match');

    // 3. Encrypt backup
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('media-demo-backup')));
      for (var i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        final status = tester.widget<Text>(find.byKey(const Key('media-demo-status'))).data;
        if (status == 'Backup encrypted') {
          break;
        }
      }
    });
    expect(tester.widget<Text>(find.byKey(const Key('media-demo-status'))).data, 'Backup encrypted');

    // Verify backup header
    expect(backupImgFile.existsSync(), isTrue);
    final header = backupImgFile.readAsBytesSync().sublist(0, 16);
    expect(header.sublist(0, 4), [0x44, 0x4d, 0x45, 0x44]); // magic == 'DMED'
    expect(header[4], 1); // version == 1
    expect(header[5], 1); // algorithm == 1 (Aes256Gcm)

    await db.close();
    tempDir.deleteSync(recursive: true);
  });
}

class _FakeMediaKeyProvider extends Fake implements KeyProvider {
  final Uint8List key;
  _FakeMediaKeyProvider(this.key);

  @override
  Future<Uint8List> getDeviceMediaKey() async => key;
}
