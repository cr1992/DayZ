// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/observability/log_level.dart';
import 'package:dayz/observability/log_record.dart';
import 'package:dayz/observability/console_sink.dart';

void main() {
  group('ConsoleSink Tests', () {
    test('Formats and writes record correctly', () {
      final writtenLines = <String>[];
      final sink = ConsoleSink((line) => writtenLines.add(line));

      final record = LogRecord(
        level: LogLevel.warning,
        event: 'auth.fail',
        ts: DateTime.utc(2026, 5, 30, 12, 0, 0),
        message: 'Login failed',
        fields: {'user': 'alice'},
      );

      sink.add(record);

      expect(writtenLines.length, 1);
      expect(
        writtenLines.first,
        '[2026-05-30T12:00:00.000Z] [WARNING] [auth.fail] - Login failed {user: alice}',
      );
    });

    test('add does not throw even if writer throws', () {
      final sink = ConsoleSink((line) => throw Exception('Writer error'));

      final record = LogRecord(
        level: LogLevel.severe,
        event: 'db.error',
        ts: DateTime.now(),
        fields: {},
      );

      expect(() => sink.add(record), returnsNormally);
    });
  });
}
