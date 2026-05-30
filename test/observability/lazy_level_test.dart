// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/observability/observability.dart';
import 'log_level_test.dart';

void main() {
  group('Lazy evaluation tests', () {
    test('messageBuilder is not evaluated if level is below log level', () {
      final sink = FakeSink();
      final logger = AppLogger.test(
        level: LogLevel.warning,
        sinks: [sink],
      );

      var builderCalled = 0;
      logger.logFine(() {
        builderCalled++;
        return 'Fine message';
      });

      logger.logInfo(() {
        builderCalled++;
        return 'Info message';
      });

      expect(builderCalled, 0);
      expect(sink.records, isEmpty);

      logger.logWarning(() {
        builderCalled++;
        return 'Warning message';
      });

      expect(builderCalled, 1);
      expect(sink.records.length, 1);
      expect(sink.records.first.message, 'Warning message');
    });
  });
}
