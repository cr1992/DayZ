// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('schema version is 1', () async {
    expect(db.schemaVersion, equals(1));
    final result = await db.customSelect('PRAGMA user_version;').getSingle();
    expect(result.read<int>('user_version'), equals(1));
  });

  test('all tables and virtual tables exist', () async {
    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table';")
        .get();

    final tableNames = rows.map((r) => r.read<String>('name')).toList();

    final expectedTables = [
      'journals',
      'entries',
      'media',
      'tags',
      'entry_tags',
      'editing_session',
      'entries_fts',
    ];

    for (final table in expectedTables) {
      expect(tableNames, contains(table), reason: 'Table $table should exist');
    }
  });

  test('all indexes exist', () async {
    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index';")
        .get();

    final indexNames = rows.map((r) => r.read<String>('name')).toList();

    final expectedIndexes = [
      'idx_entries_timeline',
      'idx_entries_monthday',
      'idx_entries_updated',
      'idx_entries_sync',
      'idx_media_entry',
      'idx_entrytags_tag',
      'idx_tags_name',
    ];

    for (final index in expectedIndexes) {
      expect(indexNames, contains(index), reason: 'Index $index should exist');
    }
  });
}
