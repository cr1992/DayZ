// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/journal_repo.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/security/rekey_service.dart';

class FakeKeyProvider extends KeyProvider {
  final Uint8List _key;

  FakeKeyProvider(this._key);

  @override
  Future<Uint8List> getAppDbKey() async => Uint8List.fromList(_key);
}

void main() {
  test('rekey makes database open with new key and reject old key', () async {
    final tempDir = Directory.systemTemp.createTempSync('dayz_rekey_test');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    final dbFile = File('${tempDir.path}/main.sqlite');
    final oldKey = Uint8List.fromList(List.generate(32, (index) => index + 1));
    final newKey = Uint8List.fromList(List.generate(32, (index) => index + 65));

    final db = await AppDatabase.openFile(dbFile, Uint8List.fromList(oldKey));
    final journal = await JournalRepo(db).create('Private');
    await db.close();

    final service = RekeyService(
      dbFile: dbFile,
      keyProvider: FakeKeyProvider(oldKey),
      availableBytesProvider: (_) async => 1024 * 1024,
    );

    await service.rekey(Uint8List.fromList(newKey));

    await expectLater(
      AppDatabase.openFile(dbFile, Uint8List.fromList(oldKey)),
      throwsA(isA<WrongKeyException>()),
    );

    final reopened = await AppDatabase.openFile(
      dbFile,
      Uint8List.fromList(newKey),
    );
    addTearDown(reopened.close);

    expect(await reopened.journalsDao.byId(journal.id), isNotNull);
  });
}
