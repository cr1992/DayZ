// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/data/database.dart';
import 'package:dayz/security/key_provider.dart';

class FakeKeyProvider extends KeyProvider {
  final Uint8List _key;
  FakeKeyProvider(this._key);

  @override
  Future<Uint8List> getAppDbKey() async => Uint8List.fromList(_key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('dayz_encrypt_test');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (methodCall) async {
            if (methodCall.method == 'getApplicationDocumentsDirectory') {
              return tempDir.path;
            }
            return null;
          },
        );
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('correct key opens encrypted db and wrong key throws', () async {
    final correctKey = Uint8List.fromList(List.generate(32, (i) => i));
    final wrongKey = Uint8List.fromList(List.generate(32, (i) => i + 1));

    final kpCorrect = FakeKeyProvider(correctKey);
    final kpWrong = FakeKeyProvider(wrongKey);

    final db = await AppDatabase.open(kpCorrect);
    final versionResult = await db.customSelect('PRAGMA cipher;').getSingle();
    expect(versionResult.read<String>('sqlcipher'), equals('sqlcipher'));

    await db.customStatement(
      "INSERT INTO journals (id, name, created_at, updated_at) VALUES ('j1', 'Test', 1000, 1000);",
    );
    await db.close();

    final dbFile = File('${tempDir.path}/db/main.sqlite');
    expect(dbFile.existsSync(), isTrue);
    final bytes = await dbFile.readAsBytes();
    expect(bytes.length, greaterThanOrEqualTo(16));

    final headerStr = String.fromCharCodes(bytes.sublist(0, 15));
    expect(headerStr, isNot(contains('SQLite format 3')));

    await expectLater(
      AppDatabase.open(kpWrong),
      throwsA(isA<WrongKeyException>()),
    );
  });
}
