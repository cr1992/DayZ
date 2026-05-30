// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/data/database.dart';

void main() {
  test('onCreate migration builds all schema entities', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table';")
        .get();
    final tableNames = rows.map((row) => row.read<String>('name')).toSet();

    expect(db.schemaVersion, greaterThan(0));
    expect(tableNames, containsAll(_expectedTables));

    final version = await db.customSelect('PRAGMA user_version;').getSingle();
    expect(version.read<int>('user_version'), db.schemaVersion);
  });

  test('onUpgrade route is reachable for older schema versions', () async {
    final tempDir = Directory.systemTemp.createTempSync('dayz_migration_test');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    final dbFile = File('${tempDir.path}/main.sqlite');
    final seedDb = AppDatabase(NativeDatabase(dbFile));
    await seedDb.customSelect('SELECT 1;').getSingle();
    await seedDb.close();

    final observedTransitions = <({int from, int to})>[];
    final upgradedDb = AppDatabase(
      NativeDatabase(dbFile),
      schemaVersionForTesting: 2,
      onUpgradeForTesting: (_, from, to) async {
        observedTransitions.add((from: from, to: to));
      },
    );
    addTearDown(upgradedDb.close);

    await upgradedDb.customSelect('SELECT 1;').getSingle();

    expect(observedTransitions, hasLength(1));
    expect(
      observedTransitions.single.from,
      lessThan(observedTransitions.single.to),
    );
    expect(observedTransitions.single.to, upgradedDb.schemaVersion);
  });
}

const _expectedTables = {
  'journals',
  'entries',
  'media',
  'tags',
  'entry_tags',
  'editing_session',
  'entries_fts',
};
