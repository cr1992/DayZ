// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/editor/editor_screen.dart';
import 'package:dayz/ui/reader/reader_screen.dart';
import 'package:dayz/ui/reader/reader_view_data.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/localized_test_app.dart';
import 'fakes/fake_repos.dart';

ReaderEntryRecord _record({
  String contentPlain = '雨后的院子\n木桌上还留着水印。',
  String contentJson = '{"document":{"type":"page","children":[]}}',
}) {
  return ReaderEntryRecord(
    id: 'entry-1',
    journalId: null,
    contentPlain: contentPlain,
    contentJson: contentJson,
    entryDtUtc: DateTime.utc(2026, 5, 31, 13, 18),
    entryTz: 'Asia/Shanghai',
    isFavorite: false,
  );
}

void main() {
  group('readerEditorRouteExtra', () {
    test('hands the editor the stored document, title line and date', () {
      final extra = readerEditorRouteExtra(_record());

      expect(extra['mode'], EditorScreenMode.writing);
      expect(extra['entryId'], 'entry-1');
      expect(
        extra['initialContentJson'],
        '{"document":{"type":"page","children":[]}}',
      );
      expect(extra['title'], '雨后的院子');
      expect(extra['entryDate'], DateTime.utc(2026, 5, 31, 13, 18).toLocal());
    });

    test('keeps an empty title empty instead of promoting the body', () {
      // Editor saves `title + '\n' + body`; an untitled entry starts with '\n'.
      final extra = readerEditorRouteExtra(_record(contentPlain: '\n只有正文'));

      expect(extra['title'], '');
    });
  });

  testWidgets(
    'edit opens the editor route with stored content and reloads on return',
    (tester) async {
      final repo = FakeReaderRepository(entries: {'entry-1': _record()});
      var loadCount = 0;
      Object? editorExtra;
      // Stable identity, as the real router provides: a fresh closure per
      // build would itself trigger reloads via didUpdateWidget.
      Future<ReaderViewData?> loadData(String id) {
        loadCount += 1;
        return buildReaderViewData(id, repo);
      }

      final router = GoRouter(
        initialLocation: '/reader',
        routes: [
          GoRoute(
            name: Routes.reader,
            path: '/reader',
            builder: (context, state) => ReaderScreen(
              entryId: 'entry-1',
              repository: repo,
              loadData: loadData,
            ),
          ),
          GoRoute(
            name: Routes.editor,
            path: '/editor',
            builder: (context, state) {
              editorExtra = state.extra;
              return Scaffold(
                body: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('editor-stub'),
                ),
              );
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(localizedRouterTestApp(routerConfig: router));
      await tester.pumpAndSettle();
      expect(loadCount, 1);

      await tester.tap(find.bySemanticsLabel(testL10n.readerActionsSemantic));
      await tester.pumpAndSettle();
      await tester.tap(find.text(testL10n.readerActionEdit));
      await tester.pumpAndSettle();

      expect(find.text('editor-stub'), findsOneWidget);
      expect(editorExtra, isA<Map<String, Object?>>());
      final extra = editorExtra! as Map<String, Object?>;
      expect(extra['entryId'], 'entry-1');
      expect(extra['mode'], EditorScreenMode.writing);
      expect(
        extra['initialContentJson'],
        '{"document":{"type":"page","children":[]}}',
      );
      expect(extra['title'], '雨后的院子');

      await tester.tap(find.text('editor-stub'));
      await tester.pumpAndSettle();

      expect(find.byKey(ReaderScreen.titleKey), findsOneWidget);
      expect(loadCount, 2);
    },
  );

  testWidgets('an injected onEdit still overrides the default editor push', (
    tester,
  ) async {
    final repo = FakeReaderRepository(entries: {'entry-1': _record()});
    final edited = <String>[];

    await tester.pumpWidget(
      localizedMaterialApp(
        home: ReaderScreen(
          entryId: 'entry-1',
          repository: repo,
          loadData: (id) => buildReaderViewData(id, repo),
          onEdit: edited.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(testL10n.readerActionsSemantic));
    await tester.pumpAndSettle();
    await tester.tap(find.text(testL10n.readerActionEdit));
    await tester.pumpAndSettle();

    expect(edited, ['entry-1']);
    expect(repo.byIdCalls, ['entry-1']);
  });
}
