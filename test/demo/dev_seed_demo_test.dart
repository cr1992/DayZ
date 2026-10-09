// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dayz/app.dart';
import 'package:dayz/app/app_services.dart';
import 'package:dayz/app/router_ports.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/demo/demo_entry.dart';
import 'package:dayz/demo/dev_seed_demo.dart';
import 'package:dayz/l10n/locale_controller.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/timeline/timeline_month_section.dart';
import 'package:dayz/ui/widgets/dayz_empty_state.dart';

import '../app/app_test_db.dart';

void main() {
  late AppServices services;

  setUpAll(initTimezoneData);

  setUp(() => services = inMemoryServices());

  tearDown(() => services.close());

  test('seed spans 6 months and 2 journals; clear keeps real data', () async {
    final real = await addEntry(
      services,
      utc: DateTime.utc(2026, 7, 1),
      text: 'real entry',
    );

    final written = await DevSeed.seed(
      services,
      now: DateTime.utc(2026, 10, 9, 12),
    );
    expect(written, greaterThanOrEqualTo(12));

    final months = await services.entries.countByMonth();
    final seededMonths = months.keys.toSet();
    expect(seededMonths.length, greaterThanOrEqualTo(6));
    final journals = await services.journals.list();
    expect(journals, hasLength(2));
    final counts = await services.journals.entryCounts();
    expect(counts.values.every((c) => c > 0), isTrue);
    expect(counts.values.fold<int>(0, (a, b) => a + b), written);

    final removed = await DevSeed.clear(services);
    expect(removed, written);
    expect(await services.journals.list(), isEmpty);
    expect(await DevSeed.countEntries(services.database), 1);
    expect(await services.entries.byId(real.id), isNotNull);
  });

  test('seed bumps the content revision', () async {
    final before = services.contentRevision.value;
    await DevSeed.seed(services, now: DateTime.utc(2026, 10, 9));
    expect(services.contentRevision.value, greaterThan(before));
  });

  test('demos list ends with the dev seed demo', () {
    expect(demos.last.title, '示例数据');
    expect(demos.last.builder(_FakeContext()), isA<DevSeedDemo>());
  });

  testWidgets('seeding while timeline is mounted refreshes it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final locale = LocaleController();
    addTearDown(locale.dispose);
    await locale.setLocale(const Locale('zh'));
    shellState.setJournals(const []);
    shellState.selectJournal(null);
    appRouter.go(Routes.timelinePath);
    bindRouterPorts(services);
    addTearDown(unbindRouterPorts);

    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await tester.pumpWidget(
      DayZApp(localeController: locale, services: services),
    );
    await settle();
    expect(find.byType(DayzEmptyState), findsOneWidget);

    await tester.runAsync(
      () => DevSeed.seed(services, now: DateTime.utc(2026, 10, 9, 12)),
    );
    await settle();

    expect(find.byType(DayzEmptyState), findsNothing);
    expect(find.byKey(timelineMonthHeaderTestKey(2026, 10)), findsOneWidget);
  });
}

class _FakeContext extends Fake implements BuildContext {}
