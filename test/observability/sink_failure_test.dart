// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/observability/log_level.dart';
import 'package:dayz/observability/log_record.dart';
import 'package:dayz/observability/rotating_file_sink.dart';
import 'package:path/path.dart' as p;

void main() {
  group('RotatingFileSink Failure & Queue Overflow Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('sink_failure_test');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('IO failure handling without throwing', () async {
      final blockedDir = Directory(p.join(tempDir.path, 'blocked_file'));
      final blockingFile = File(blockedDir.path);
      await blockingFile.writeAsString('I block directory creation');

      final sink = RotatingFileSink(blockedDir);

      expect(
          () => sink.add(LogRecord(
                level: LogLevel.info,
                event: 'test',
                ts: DateTime.now(),
                fields: {},
              )),
          returnsNormally);

      await sink.flush();
      expect(sink.degradationCount, 1);

      await sink.close();
    });

    test('Queue overflow drops oldest and increments degradation count', () async {
      final sink = RotatingFileSink(tempDir);

      final recordsCount = 4100;
      for (var i = 0; i < recordsCount; i++) {
        sink.add(LogRecord(
          level: LogLevel.info,
          event: 'overflow',
          ts: DateTime.now(),
          fields: {'index': i},
        ));
      }

      await sink.flush();
      expect(sink.degradationCount, greaterThan(0));

      await sink.close();
    });
  });
}
