// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/drift.dart';
import 'journals.dart';

class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get journalId => text().nullable().references(Journals, #id)();
  TextColumn get contentJson => text().withDefault(const Constant(''))();
  TextColumn get contentPlain => text().withDefault(const Constant(''))();

  DateTimeColumn get entryDtUtc => dateTime()();
  TextColumn get entryTz => text()();
  IntColumn get localYear => integer()();
  IntColumn get localMonth => integer()();
  IntColumn get localDay => integer()();

  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  TextColumn get placeName => text().nullable()();
  TextColumn get weatherCode => text().nullable()();
  RealColumn get weatherTemp => real().nullable()();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  TextColumn get serverRev => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
