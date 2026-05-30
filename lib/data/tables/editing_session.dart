// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/drift.dart';

@DataClassName('EditingSession')
class EditingSessions extends Table {
  @override
  String get tableName => 'editing_session';

  TextColumn get id => text()();
  TextColumn get targetId => text().nullable()();
  TextColumn get draftJson => text().nullable()();
  IntColumn get cursorPos => integer().nullable()();
  BoolColumn get isNew => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
