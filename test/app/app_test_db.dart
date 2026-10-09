// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/native.dart';

import 'package:dayz/app/app_services.dart';
import 'package:dayz/data/database.dart';

/// 内存库版组合根，供 test/app 下的装配测试共用。
AppServices inMemoryServices() {
  return AppServices.forDatabase(AppDatabase(NativeDatabase.memory()));
}

Future<Entry> addEntry(
  AppServices services, {
  String? journalId,
  required DateTime utc,
  required String text,
}) {
  return services.entries.create(
    journalId: journalId,
    contentJson: '{}',
    contentPlain: text,
    entryDtUtc: utc,
    entryTz: 'Etc/UTC',
  );
}
