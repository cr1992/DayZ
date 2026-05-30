// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/editing_session_repo.dart';

void main() {
  late AppDatabase db;
  late EditingSessionRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = EditingSessionRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('upsert current clear and keep at most one row', () async {
    expect(await repo.current(), isNull);

    final first = await repo.upsert(
      targetId: 'entry-1',
      draftJson: '{"insert":"first"}',
      isNew: true,
      cursorPos: 3,
    );
    expect(first.id, EditingSessionRepo.currentId);
    expect(first.targetId, 'entry-1');
    expect(first.isNew, isTrue);

    final second = await repo.upsert(
      targetId: 'entry-2',
      draftJson: '{"insert":"second"}',
      isNew: false,
      cursorPos: 7,
    );
    expect(second.id, EditingSessionRepo.currentId);
    expect(second.targetId, 'entry-2');
    expect(second.draftJson, '{"insert":"second"}');
    expect(second.cursorPos, 7);
    expect(second.isNew, isFalse);

    final rows = await db.select(db.editingSessions).get();
    expect(rows, hasLength(1));

    await repo.clear();
    expect(await repo.current(), isNull);
    expect(await db.select(db.editingSessions).get(), isEmpty);
  });
}
