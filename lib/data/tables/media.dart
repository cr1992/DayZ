// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/drift.dart';
import 'entries.dart';

class Media extends Table {
  TextColumn get id => text()();
  TextColumn get entryId =>
      text().references(Entries, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => text()();
  TextColumn get relPath => text()();
  TextColumn get mime => text().nullable()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();
  IntColumn get fileSize => integer().nullable()();

  TextColumn get thumbPath => text().nullable()();
  IntColumn get thumbW => integer().nullable()();
  IntColumn get thumbH => integer().nullable()();
  DateTimeColumn get thumbSrcUpdatedAt => dateTime().nullable()();

  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
