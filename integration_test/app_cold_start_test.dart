// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// 在真机上验证生产装配路径：真实 SQLCipher 文件库 + 真 KeyProvider → 时间线挂真数据。
//
// 跑法：flutter test integration_test/app_cold_start_test.dart -d <android 设备 id>
//
// 测试本身只增删带 DevSeed 标记的示例数据；但 `flutter test -d <设备>` 跑完会**卸载 App**，
// 设备上该 App 的全部数据（含加密库与设备密钥）随之清空。走查数据要在测试后重新写入。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dayz/app.dart';
import 'package:dayz/app/app_services.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/demo/dev_seed_demo.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/shell/placeholder_screen.dart';
import 'package:dayz/ui/shell/app_shell.dart';
import 'package:dayz/ui/shell/shell_drawer.dart';
import 'package:dayz/ui/timeline/timeline_month_section.dart';
import 'package:dayz/ui/timeline/timeline_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cold start mounts the real timeline over the encrypted DB', (
    tester,
  ) async {
    initTimezoneData();
    final services = await AppServices.open();
    expect(services, isNotNull, reason: '设备上的加密库应能用设备密钥打开');
    addTearDown(() async {
      await DevSeed.clear(services!);
      await services.close();
    });

    await DevSeed.clear(services!);
    final now = DateTime.now().toUtc();
    final written = await DevSeed.seed(services, now: now);
    expect(written, greaterThan(0));

    shellState.selectJournal(null);
    appRouter.go(Routes.timelinePath);
    await tester.pumpWidget(DayZApp(services: services));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.byType(TimelinePage), findsOneWidget);
    expect(find.byType(PlaceholderScreen), findsNothing);
    final local = DateTime.now();
    expect(
      find.byKey(timelineMonthHeaderTestKey(local.year, local.month)),
      findsOneWidget,
    );

    // 抽屉日记本来自库：两本示例日记本都在。
    // 顶栏归外壳所有：菜单钮是 AppShell 顶栏的 leading IconButton。
    await tester.tap(
      find.descendant(of: find.byType(AppShell), matching: find.byType(IconButton)).first,
    );
    await tester.pumpAndSettle();
    final drawer = find.byType(ShellDrawer);
    expect(drawer, findsOneWidget);
    expect(
      find.descendant(
        of: drawer,
        matching: find.text('${DevSeed.journalPrefix}日常'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: drawer,
        matching: find.text('${DevSeed.journalPrefix}旅行'),
      ),
      findsOneWidget,
    );

    // 选「旅行」本：时间线只剩旅行条目（卡片都带地点「大理」）。
    await tester.tap(
      find.descendant(
        of: drawer,
        matching: find.text('${DevSeed.journalPrefix}旅行'),
      ),
    );
    await tester.pumpAndSettle();
    if (find.byType(ShellDrawer).evaluate().isNotEmpty) {
      Navigator.of(tester.element(find.byType(ShellDrawer))).pop();
      await tester.pumpAndSettle();
    }
    expect(find.text('第一次自己做红烧肉'), findsNothing);
    expect(find.textContaining('大理'), findsWidgets);
  });
}
