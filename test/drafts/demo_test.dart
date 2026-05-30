// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dayz/data/database.dart';
import 'package:dayz/demo/demo_entry.dart';
import 'package:dayz/drafts/demo.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demos list contains Drafts demo entry', () {
    final entry = demos.firstWhere((demo) => demo.title == 'Drafts demo');
    expect(entry.subtitle, '自动保存草稿与恢复状态演示');
  });

  testWidgets('DraftsDemo auto saves after debounce window', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(MaterialApp(home: DraftsDemo(database: db)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('drafts-demo-editor')),
      'hello',
    );
    await tester.pump(const Duration(milliseconds: 1499));

    expect(await db.select(db.editingSessions).get(), isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    final rows = await db.select(db.editingSessions).get();
    expect(rows, hasLength(1));
    expect(rows.single.draftJson, contains('hello'));
    expect(find.text('Last saved: No save yet'), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('drafts-demo-session'))).data,
      contains('hello'),
    );
  });

  testWidgets('DraftsDemo simulate paused flushes immediately', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(MaterialApp(home: DraftsDemo(database: db)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('drafts-demo-editor')),
      'paused',
    );
    await tester.tap(find.byKey(const Key('drafts-demo-paused')));
    await tester.pumpAndSettle();

    final rows = await db.select(db.editingSessions).get();
    expect(rows, hasLength(1));
    expect(rows.single.draftJson, contains('paused'));
    expect(find.text('Paused flush saved'), findsOneWidget);
  });

  testWidgets('DraftsDemo submit and clear empties editing session', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(MaterialApp(home: DraftsDemo(database: db)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('drafts-demo-editor')), 'done');
    await tester.tap(find.byKey(const Key('drafts-demo-submit-clear')));
    await tester.pumpAndSettle();

    expect(await db.select(db.editingSessions).get(), isEmpty);
    expect(await db.select(db.entries).get(), hasLength(1));
    expect(find.text('Submitted and cleared'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('drafts-demo-session'))).data,
      'empty',
    );
  });

  testWidgets('DraftsDemo simulate restart restores residual draft', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(MaterialApp(home: DraftsDemo(database: db)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('drafts-demo-editor')),
      'recover me',
    );
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();

    await tester.tap(find.byKey(const Key('drafts-demo-leave-draft')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drafts-demo-simulate-restart')));
    await tester.pumpAndSettle();

    expect(find.text('Residual draft detected'), findsOneWidget);
    expect(
      find.text('Simulated restart: residual draft detected'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('drafts-demo-editor')))
          .controller!
          .text,
      'recover me',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('drafts-demo-session'))).data,
      contains('recover me'),
    );
  });
}
