// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:typed_data';

import 'package:dayz/security/key_provider.dart';
import 'package:dayz/security/rekey_service.dart';
import 'package:dayz/security/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RekeyService', () {
    late FakeFlutterSecureStorage fakeStorage;
    late SecureStore secureStore;
    late SharedPreferences prefs;

    KeyProvider buildProvider() {
      return KeyProvider(
        store: secureStore,
        preferencesFactory: () async => prefs,
      );
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      fakeStorage = FakeFlutterSecureStorage();
      secureStore = SecureStore(storage: fakeStorage);
      await secureStore.set(
        'device_db_key',
        Uint8List.fromList(List<int>.generate(32, (index) => index + 1)),
      );
    });

    test('备份后 rekey 失败时回滚到备份前字节内容', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'dayz-rekey-rollback-',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final dbFile = File('${tempDir.path}/main.sqlite');
      final originalBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6]);
      await dbFile.writeAsBytes(originalBytes, flush: true);

      final service = RekeyService(
        dbFile: dbFile,
        keyProvider: buildProvider(),
        availableBytesProvider: (_) async => 1024 * 1024,
        rekeyRunner: (_) async {
          await dbFile.writeAsBytes([9, 9, 9, 9], flush: true);
          throw StateError('boom');
        },
      );

      await expectLater(
        service.rekey(Uint8List.fromList(List<int>.filled(32, 7))),
        throwsStateError,
      );
      expect(await dbFile.readAsBytes(), equals(originalBytes));
    });

    test('磁盘空间不足时直接拒绝执行', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'dayz-rekey-nospace-',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final dbFile = File('${tempDir.path}/main.sqlite');
      await dbFile.writeAsBytes(List<int>.filled(10, 1), flush: true);

      final service = RekeyService(
        dbFile: dbFile,
        keyProvider: buildProvider(),
        availableBytesProvider: (_) async => 11,
        rekeyRunner: (_) async {},
      );

      await expectLater(
        service.rekey(Uint8List.fromList(List<int>.filled(32, 8))),
        throwsA(isA<InsufficientDiskSpaceException>()),
      );
      expect(File('${dbFile.path}.bak').existsSync(), isFalse);
    });

    test('进度回调按 copying → rekeying → cleaning → done 顺序触发', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'dayz-rekey-progress-',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final dbFile = File('${tempDir.path}/main.sqlite');
      await dbFile.writeAsBytes([1, 2, 3, 4], flush: true);
      final stages = <RekeyProgressStage>[];

      final service = RekeyService(
        dbFile: dbFile,
        keyProvider: buildProvider(),
        availableBytesProvider: (_) async => 1024 * 1024,
        rekeyRunner: (_) async {},
      );

      await service.rekey(
        Uint8List.fromList(List<int>.filled(32, 9)),
        onProgress: stages.add,
      );

      expect(
        stages,
        equals([
          RekeyProgressStage.copying,
          RekeyProgressStage.rekeying,
          RekeyProgressStage.cleaning,
          RekeyProgressStage.done,
        ]),
      );
      expect(File('${dbFile.path}.bak').existsSync(), isFalse);
    });
  });
}
