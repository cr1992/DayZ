// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dayz/app.dart';
import 'package:dayz/app/app_services.dart';
import 'package:dayz/app/timeline_host.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/ui/timeline/timeline_month_section.dart';

import '../l10n/localized_test_app.dart';
import 'app_test_db.dart';

void main() {
  late AppServices services;
  late String workId;
  late String lifeId;
  late String workEntryId;
  late String lifeEntryId;

  setUpAll(initTimezoneData);

  setUp(() async {
    services = inMemoryServices();
    workId = (await services.journals.create('Work')).id;
    lifeId = (await services.journals.create('Life')).id;
    workEntryId = (await addEntry(
      services,
      journalId: workId,
      utc: DateTime.utc(2026, 3, 2),
      text: 'work title',
    )).id;
    lifeEntryId = (await addEntry(
      services,
      journalId: lifeId,
      utc: DateTime.utc(2026, 1, 5),
      text: 'life title',
    )).id;
  });

  tearDown(() => services.close());

  Widget host(String? journalId) => localizedTestApp(
    child: TimelineHost(repo: services.timelineRepo, journalId: journalId),
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('loads entries on first pump and re-scopes on journal change', (
    tester,
  ) async {
    await tester.pumpWidget(host(null));
    await settle(tester);

    expect(find.byKey(timelineEntryCardTestKey(workEntryId)), findsOneWidget);
    expect(find.byKey(timelineEntryCardTestKey(lifeEntryId)), findsOneWidget);

    await tester.pumpWidget(host(lifeId));
    await settle(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(timelineEntryCardTestKey(lifeEntryId)), findsOneWidget);
    expect(find.byKey(timelineEntryCardTestKey(workEntryId)), findsNothing);
    expect(find.byKey(timelineMonthHeaderTestKey(2026, 3)), findsNothing);
  });

  testWidgets('DayZApp without services pumps without throwing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const DayZApp());
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
