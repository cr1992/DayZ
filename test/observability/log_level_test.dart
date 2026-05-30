// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/observability/log_level.dart';
import 'package:dayz/observability/log_record.dart';
import 'package:dayz/observability/log_sink.dart';

class FakeSink implements LogSink {
  final List<LogRecord> records = [];
  bool isFlushed = false;
  bool isClosed = false;

  @override
  void add(LogRecord redacted) {
    records.add(redacted);
  }

  @override
  Future<void> flush() async {
    isFlushed = true;
  }

  @override
  Future<void> close() async {
    isClosed = true;
  }
}

void main() {
  group('LogLevel Tests', () {
    test('defaultLevelFor returns correct levels', () {
      expect(defaultLevelFor(true), LogLevel.info);
      expect(defaultLevelFor(false), LogLevel.fine);
    });

    test('LogLevel comparison satisfies FINE < INFO < WARNING < SEVERE', () {
      expect(LogLevel.fine < LogLevel.info, isTrue);
      expect(LogLevel.info < LogLevel.warning, isTrue);
      expect(LogLevel.warning < LogLevel.severe, isTrue);

      expect(LogLevel.severe > LogLevel.warning, isTrue);
      expect(LogLevel.warning >= LogLevel.info, isTrue);
      expect(LogLevel.info <= LogLevel.info, isTrue);
    });
  });

  group('LogRecord & LogSink Contract Tests', () {
    test('FakeSink receives LogRecord correctly', () async {
      final sink = FakeSink();
      final record = LogRecord(
        level: LogLevel.info,
        event: 'test.event',
        ts: DateTime.utc(2026, 5, 30, 12, 0, 0),
        message: 'Hello, world!',
        fields: {'key1': 'value1', 'key2': 123},
      );

      sink.add(record);

      expect(sink.records.length, 1);
      final received = sink.records.first;
      expect(received.level, LogLevel.info);
      expect(received.event, 'test.event');
      expect(received.ts, DateTime.utc(2026, 5, 30, 12, 0, 0));
      expect(received.message, 'Hello, world!');
      expect(received.fields, {'key1': 'value1', 'key2': 123});

      await sink.flush();
      expect(sink.isFlushed, isTrue);

      await sink.close();
      expect(sink.isClosed, isTrue);
    });
  });
}
