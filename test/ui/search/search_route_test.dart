// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/app/app_services.dart';
import 'package:dayz/app/router_ports.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/ui/search/search_page.dart';
import 'package:dayz/ui/search/search_source.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/placeholder_screen.dart';

import '../../app/app_test_db.dart';
import '../../l10n/localized_test_app.dart';

void main() {
  setUpAll(initTimezoneData);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpSearch(WidgetTester tester, {Object? extra}) async {
    appRouter.go(Routes.searchPath, extra: extra);
    await tester.pumpWidget(localizedRouterTestApp(routerConfig: appRouter));
    await settle(tester);
  }

  group('port not registered', () {
    setUp(unbindRouterPorts);

    testWidgets('search route stays a placeholder', (tester) async {
      await pumpSearch(tester);

      expect(searchSourcePort, isNull);
      expect(find.byType(PlaceholderScreen), findsOneWidget);
      expect(find.byType(SearchPage), findsNothing);
    });
  });

  group('port bound to an in-memory library', () {
    late AppServices services;

    setUp(() {
      services = inMemoryServices();
      bindRouterPorts(services);
    });

    tearDown(() async {
      unbindRouterPorts();
      await services.close();
    });

    test('bind registers a RepoSearchSource; unbind clears it', () {
      expect(searchSourcePort, isA<RepoSearchSource>());
      unbindRouterPorts();
      expect(searchSourcePort, isNull);
    });

    testWidgets('extra query renders real results; soft delete refreshes '
        '(R10)', (tester) async {
      final older = await tester.runAsync(
        () => addEntry(
          services,
          utc: DateTime.utc(2025, 6, 12),
          text: '开了去年的那罐\n梅子的颜色变得很深',
        ),
      );
      final newer = await tester.runAsync(
        () => addEntry(
          services,
          utc: DateTime.utc(2026, 5, 27),
          text: '外婆教我腌的梅子\n玻璃罐要先用开水烫过',
        ),
      );
      await tester.runAsync(
        () => addEntry(services, utc: DateTime.utc(2026, 5, 28), text: '下雨天'),
      );

      await pumpSearch(tester, extra: '梅子');

      expect(find.byType(PlaceholderScreen), findsNothing);
      expect(find.byType(SearchPage), findsOneWidget);
      expect(find.byKey(SearchPage.hitCardKey(newer!.id)), findsOneWidget);
      expect(find.byKey(SearchPage.hitCardKey(older!.id)), findsOneWidget);
      expect(find.text('下雨天'), findsNothing);
      // 按时间倒序。
      expect(
        tester.getTopLeft(find.byKey(SearchPage.hitCardKey(newer.id))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(SearchPage.hitCardKey(older.id))).dy,
        ),
      );

      await tester.runAsync(() => services.entries.softDelete(older.id));
      await settle(tester);

      expect(find.byKey(SearchPage.hitCardKey(older.id)), findsNothing);
      expect(find.byKey(SearchPage.hitCardKey(newer.id)), findsOneWidget);
      expect(
        find.text(testL10n.searchResultStat(1), findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('without extra the real screen opens in idle', (tester) async {
      await pumpSearch(tester);

      expect(find.byType(SearchPage), findsOneWidget);
      expect(find.byKey(SearchPage.suggestionsKey), findsOneWidget);
    });
  });
}
