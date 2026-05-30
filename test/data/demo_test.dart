// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/data/database.dart';
import 'package:dayz/data/demo.dart';
import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/demo/demo_entry.dart';

void main() {
  test('demos list contains Data demo entry', () {
    final entry = demos.firstWhere((demo) => demo.title == 'Data demo');
    expect(entry.subtitle, 'Drift Repository 插入 / 查询 / 软删除');
  });

  testWidgets('Debug Home renders Data demo entry', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DebugHome()));

    await tester.scrollUntilVisible(
      find.text('Data demo'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Data demo'), findsOneWidget);
    expect(find.text('Drift Repository 插入 / 查询 / 软删除'), findsOneWidget);
  });

  testWidgets('DataDemo can insert query and soft delete an entry', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(MaterialApp(home: DataDemo(database: db)));
    await tester.pumpAndSettle();

    final eventLogFinder = find.byKey(const Key('data-demo-event-log'));
    expect(eventLogFinder, findsOneWidget);

    await tester.tap(find.byKey(const Key('data-demo-create-journal')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Journals: 1, entries: 0'), findsOneWidget);
    expect(eventLogFinder, findsOneWidget);
    expect(_eventLogText(tester), contains('data.demo.create-journal.ok'));

    await tester.tap(find.byKey(const Key('data-demo-create-entry')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Journals: 1, entries: 1'), findsOneWidget);
    expect(find.textContaining('Data demo entry'), findsWidgets);
    expect(_eventLogText(tester), contains('data.demo.create-entry.ok'));

    await tester.tap(find.byKey(const Key('data-demo-load-timeline')));
    await tester.pumpAndSettle();
    expect(find.text('Timeline top 1'), findsOneWidget);
    expect(_eventLogText(tester), contains('data.demo.load-timeline.ok'));

    await tester.tap(find.byKey(const Key('data-demo-soft-delete')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Journals: 1, entries: 0'), findsOneWidget);
    expect(_eventLogText(tester), contains('data.demo.soft-delete.ok'));

    final rawEntries = await db.entriesDao.active().get();
    expect(rawEntries, isEmpty);
  });
}

String _eventLogText(WidgetTester tester) {
  return tester
      .widget<Text>(find.byKey(const Key('data-demo-event-log')))
      .data!;
}
