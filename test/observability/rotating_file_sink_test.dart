// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/observability/log_level.dart';
import 'package:dayz/observability/log_record.dart';
import 'package:dayz/observability/rotating_file_sink.dart';
import 'package:dayz/observability/log_rotation.dart';
import 'package:path/path.dart' as p;

void main() {
  group('RotatingFileSink Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('rotating_file_sink_test');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Rotation and file limits', () async {
      final sink = RotatingFileSink(tempDir);

      final largeString = 'A' * 1000;
      final totalRecords = 4500; // 4.5 MB, exceeds softMaxBytes (1MB) * 4

      for (var i = 0; i < totalRecords; i++) {
        sink.add(LogRecord(
          level: LogLevel.info,
          event: 'test.event',
          ts: DateTime.utc(2026, 5, 30, 12, 0, 0),
          message: largeString,
          fields: {},
        ));
      }

      await sink.flush();

      final files = tempDir.listSync().whereType<File>().toList();
      expect(files.length, lessThanOrEqualTo(maxFiles + 1));

      for (final file in files) {
        final len = await file.length();
        expect(len, lessThanOrEqualTo(softMaxBytes + 1500));
      }

      final mainLog = File(p.join(tempDir.path, 'app.log'));
      expect(await mainLog.exists(), isTrue);

      final log3 = File(p.join(tempDir.path, 'app.log.3'));
      expect(await log3.exists(), isTrue);

      final log4 = File(p.join(tempDir.path, 'app.log.4'));
      expect(await log4.exists(), isFalse);

      await sink.close();
    });

    test('Redacted output in log file', () async {
      final sink = RotatingFileSink(tempDir);
      sink.add(LogRecord(
        level: LogLevel.info,
        event: 'security.check',
        ts: DateTime.utc(2026, 5, 30, 12, 0, 0),
        message: 'Loaded file at media/image.png',
        fields: {'key': '***'},
      ));

      await sink.flush();

      final logFile = File(p.join(tempDir.path, 'app.log'));
      final content = await logFile.readAsString();
      expect(
        content,
        contains(
            '[2026-05-30T12:00:00.000Z] [INFO] [security.check] - Loaded file at media/image.png {key: ***}'),
      );

      await sink.close();
    });
  });
}
