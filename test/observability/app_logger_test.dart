// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/observability/observability.dart';
import 'log_level_test.dart';

class FakeLogSink extends FakeSink {}

void main() {
  group('AppLogger Tests', () {
    final fixedTime = DateTime.utc(2026, 5, 30, 12, 0, 0);

    test('Log level filtering', () {
      final sink = FakeLogSink();
      final logger = AppLogger.test(
        level: LogLevel.warning,
        sinks: [sink],
        clock: () => fixedTime,
      );

      logger.log(LogLevel.info, 'info.event');
      logger.log(LogLevel.warning, 'warn.event');
      logger.log(LogLevel.severe, 'severe.event');

      expect(sink.records.length, 2);
      expect(sink.records[0].event, 'warn.event');
      expect(sink.records[1].event, 'severe.event');
    });

    test('AppLogger forces redaction on dispatch', () {
      final sink = FakeLogSink();
      final logger = AppLogger.test(
        level: LogLevel.fine,
        sinks: [sink],
        clock: () => fixedTime,
      );

      logger.logInfo('Loaded secret=12345', fields: {
        'my_password': 'my-pwd',
        'file_path':
            '/var/mobile/Containers/Data/Application/X/Documents/media/image.png',
      });

      expect(sink.records.length, 1);
      final record = sink.records.first;
      expect(record.message, 'Loaded secret=***');
      expect(record.fields['my_password'], '***');
      expect(record.fields['file_path'], 'media/image.png');
    });

    test('Injectable clock is used for timestamping', () {
      final sink = FakeLogSink();
      final logger = AppLogger.test(
        level: LogLevel.info,
        sinks: [sink],
        clock: () => fixedTime,
      );

      logger.log(LogLevel.info, 'test.event');
      expect(sink.records.first.ts, fixedTime);
    });

    test('Zero-config ConsoleSink by default', () {
      expect(() => AppLogger.instance.logInfo('Console test'), returnsNormally);
    });

    test('AppLogger throws when logging non-string non-builder', () {
      final logger = AppLogger.test(level: LogLevel.fine, sinks: []);
      expect(() => logger.logInfo(12345), throwsArgumentError);
    });
  });
}
