// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:dayz/data/database.dart';
import 'package:dayz/demo/demo_entry.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/backup/demo.dart';

class TestKeyProvider extends KeyProvider {
  final Uint8List _appKey;
  final Uint8List _mediaKey;

  TestKeyProvider(this._appKey, this._mediaKey);

  @override
  Future<Uint8List> getAppDbKey() async => Uint8List.fromList(_appKey);

  @override
  Future<Uint8List> getDeviceMediaKey() async => Uint8List.fromList(_mediaKey);

  @override
  Future<Uint8List> deriveBackupKey(Uint8List password, Uint8List salt) async {
    final key = Uint8List(32);
    for (var i = 0; i < key.length; i++) {
      key[i] = password[i % password.length] ^ salt[i % salt.length] ^ i;
    }
    return key;
  }
}

void mockPathProvider(Directory documentsDir, Directory tempDir) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return documentsDir.path;
          }
          if (methodCall.method == 'getTemporaryDirectory') {
            return tempDir.path;
          }
          return null;
        },
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Directory docsDir;
  late Directory tDir;

  late File dbFile;
  late AppDatabase db;
  late TestKeyProvider keyProvider;

  final appKey = Uint8List.fromList(List.generate(32, (i) => i));
  final mediaKey = Uint8List.fromList(List.generate(32, (i) => i + 10));

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dayz_backup_demo_test');
    docsDir = Directory(p.join(tempDir.path, 'documents'))
      ..createSync(recursive: true);
    tDir = Directory(p.join(tempDir.path, 'temp'))..createSync(recursive: true);
    mockPathProvider(docsDir, tDir);

    dbFile = File(p.join(docsDir.path, 'db', 'main.sqlite'));
    keyProvider = TestKeyProvider(appKey, mediaKey);

    db = await AppDatabase.openFile(dbFile, Uint8List.fromList(appKey));
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('BackupDemo is registered and renders UI', (
    WidgetTester tester,
  ) async {
    // 1. Verify demo is registered in demos list
    final demoEntry = demos.firstWhere((d) => d.title == '备份与恢复 demo');
    expect(demoEntry, isNotNull);

    // 2. Render BackupDemo widget
    await tester.pumpWidget(
      MaterialApp(
        home: BackupDemo(database: db, keyProvider: keyProvider),
      ),
    );

    // Give it a pump to build and init database
    await tester.pumpAndSettle();
    await _pumpUntil(
      tester,
      find.textContaining('Database initialized successfully'),
    );

    // 3. Verify buttons render successfully
    expect(find.text('Seed Test Data'), findsOneWidget);
    expect(find.text('Export .mydiary'), findsOneWidget);
    expect(find.text('Clear Local Data'), findsOneWidget);
    expect(find.text('Restore Backup'), findsOneWidget);
    expect(find.text('Run Self Check'), findsOneWidget);
    expect(find.text('SELF CHECK: NOT RUN'), findsOneWidget);
    expect(find.text('Seed Benchmark Data'), findsOneWidget);
    expect(find.text('Run Full Benchmark'), findsOneWidget);
    expect(find.text('Use Spec Scale'), findsOneWidget);
    expect(find.text('BENCHMARK: NOT RUN'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);

    // Verify password input text field renders
    expect(
      find.byType(TextField),
      findsNWidgets(5),
    ); // Password, search, and three benchmark fields.

    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('backup-demo-benchmark-entries')),
          )
          .controller
          ?.text,
      '1000',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('backup-demo-benchmark-media')),
          )
          .controller
          ?.text,
      '50',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('backup-demo-benchmark-media-mib')),
          )
          .controller
          ?.text,
      '1',
    );

    await _tap(
      tester,
      find.byKey(const Key('backup-demo-benchmark-spec-scale')),
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('backup-demo-benchmark-entries')),
          )
          .controller
          ?.text,
      '10000',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('backup-demo-benchmark-media')),
          )
          .controller
          ?.text,
      '500',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('backup-demo-benchmark-media-mib')),
          )
          .controller
          ?.text,
      '3',
    );
  });

  testWidgets('BackupDemo full flow ends with deterministic self check PASS', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BackupDemo(database: db, keyProvider: keyProvider),
      ),
    );
    await tester.pumpAndSettle();
    await _pumpUntil(
      tester,
      find.textContaining('Database initialized successfully'),
    );

    await _tap(tester, find.byKey(const Key('backup-demo-seed')));
    await _pumpUntil(
      tester,
      find.textContaining('Successfully seeded 3 entries and 2 media files.'),
    );

    await tester.enterText(
      find.byKey(const Key('backup-demo-password')),
      'demo-password',
    );
    await _tap(tester, find.byKey(const Key('backup-demo-export')));
    await _pumpUntil(tester, find.textContaining('Backup successfully saved'));

    await _tap(tester, find.byKey(const Key('backup-demo-clear')));
    await _pumpUntil(tester, find.text('Drop All'));
    await tester.tap(find.text('Drop All'));
    await _pumpUntil(
      tester,
      find.textContaining('Local database and media files cleared'),
    );

    await tester.enterText(
      find.byKey(const Key('backup-demo-password')),
      'demo-password',
    );
    await _tap(tester, find.byKey(const Key('backup-demo-restore')));
    await _pumpUntil(tester, find.text('Overwrite'));
    await tester.tap(find.text('Overwrite'));
    await _pumpUntil(tester, find.text('SELF CHECK: PASS'));

    expect(find.text('SELF CHECK: PASS'), findsOneWidget);
    expect(find.textContaining('PASS entries restored: 3/3'), findsOneWidget);
    expect(
      find.textContaining('PASS media rows restored: 2/2'),
      findsOneWidget,
    );
    expect(find.textContaining('PASS media decryptable: 2/2'), findsOneWidget);
    expect(
      find.textContaining('PASS FTS search grape returns restored entry'),
      findsOneWidget,
    );
    expect(
      find.textContaining('PASS exports/test.mydiary exists and is non-empty'),
      findsOneWidget,
    );
    expect(
      find.textContaining('PASS password field is cleared'),
      findsOneWidget,
    );
  });

  testWidgets('BackupDemo benchmark flow seeds data and reports PASS', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BackupDemo(database: db, keyProvider: keyProvider),
      ),
    );
    await tester.pumpAndSettle();
    await _pumpUntil(
      tester,
      find.textContaining('Database initialized successfully'),
    );

    await tester.enterText(
      find.byKey(const Key('backup-demo-benchmark-entries')),
      '3',
    );
    await tester.enterText(
      find.byKey(const Key('backup-demo-benchmark-media')),
      '1',
    );
    await tester.enterText(
      find.byKey(const Key('backup-demo-benchmark-media-mib')),
      '1',
    );
    await _tap(tester, find.byKey(const Key('backup-demo-benchmark-run')));
    await _pumpUntil(tester, find.text('BENCHMARK: PASS'), maxPumps: 180);

    expect(find.text('BENCHMARK: PASS'), findsOneWidget);
    expect(
      find.textContaining('Config: 3 entries, 1 media x 1 MiB'),
      findsOneWidget,
    );
    expect(find.textContaining('PASS entries restored: 3/3'), findsOneWidget);
    expect(
      find.textContaining('PASS media rows restored: 1/1'),
      findsOneWidget,
    );
    expect(
      find.textContaining('PASS FTS benchmarktoken rows: 3/3'),
      findsOneWidget,
    );
  });
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 120,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  final visibleTexts = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .join('\n');
  fail('Timed out waiting for $finder\nVisible text:\n$visibleTexts');
}
