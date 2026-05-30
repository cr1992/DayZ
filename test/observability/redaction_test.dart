// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/observability/log_level.dart';
import 'package:dayz/observability/log_record.dart';
import 'package:dayz/observability/redaction.dart';

void main() {
  group('redactAbsolutePath Tests', () {
    test('removes iOS application container prefix', () {
      final path =
          '/var/mobile/Containers/Data/Application/1234-5678-ABCD/Documents/media/a.bin';
      expect(redactAbsolutePath(path), 'media/a.bin');
    });

    test('removes Android app_flutter container prefix', () {
      final path = '/data/user/0/com.dayz/app_flutter/media/b.bin';
      expect(redactAbsolutePath(path), 'media/b.bin');
    });

    test('replaces unknown absolute path with REDACTED_ABS placeholder', () {
      expect(redactAbsolutePath('/private/var/foo'), '<REDACTED_ABS>');
      expect(redactAbsolutePath('/Users/username/project'), '<REDACTED_ABS>');
    });

    test('returns relative path as-is', () {
      expect(redactAbsolutePath('media/a.bin'), 'media/a.bin');
      expect(
          redactAbsolutePath('relative/path/to/file.txt'), 'relative/path/to/file.txt');
    });
  });

  group('Redactor.redact Tests', () {
    final testTime = DateTime.utc(2026, 5, 30, 12, 0, 0);

    test('redacts message containing sensitive key-value pairs', () {
      final record = LogRecord(
        level: LogLevel.info,
        event: 'test',
        ts: testTime,
        message: 'Loaded key=1234abcd and secret:xyz987',
        fields: {},
      );

      final redacted = Redactor.redact(record);
      expect(redacted.message, 'Loaded key=*** and secret:***');
    });

    test('redacts message containing absolute paths', () {
      final record = LogRecord(
        level: LogLevel.info,
        event: 'test',
        ts: testTime,
        message:
            'File saved at /var/mobile/Containers/Data/Application/X/Documents/media/photo.jpg and temp file at /tmp/test.tmp',
        fields: {},
      );

      final redacted = Redactor.redact(record);
      expect(
        redacted.message,
        'File saved at media/photo.jpg and temp file at <REDACTED_ABS>',
      );
    });

    test('redacts fields containing sensitive keys', () {
      final record = LogRecord(
        level: LogLevel.warning,
        event: 'test',
        ts: testTime,
        message: 'Warning occurred',
        fields: {
          'appKey': 'abc-123',
          'user_password': 'my-password',
          'mySecret': 'ssh-key-data',
          'token': 'jwt-token',
          'derived_key_bytes': [1, 2, 3],
          'non_sensitive': 'safe_value',
        },
      );

      final redacted = Redactor.redact(record);
      expect(redacted.fields['appKey'], '***');
      expect(redacted.fields['user_password'], '***');
      expect(redacted.fields['mySecret'], '***');
      expect(redacted.fields['token'], '***');
      expect(redacted.fields['derived_key_bytes'], '***');
      expect(redacted.fields['non_sensitive'], 'safe_value');
    });

    test('redacts content_json and content_plain fields and keeps lengths', () {
      final record = LogRecord(
        level: LogLevel.info,
        event: 'test',
        ts: testTime,
        message: 'Editor content',
        fields: {
          'content_json': '{"ops":[{"insert":"Hello World"}]}',
          'content_plain': 'Hello World',
        },
      );

      final redacted = Redactor.redact(record);
      expect(redacted.fields['content_json'], '<redacted:len=34>');
      expect(redacted.fields['content_plain'], '<redacted:len=11>');
    });

    test('redacts absolute paths in field values', () {
      final record = LogRecord(
        level: LogLevel.info,
        event: 'test',
        ts: testTime,
        message: 'Info',
        fields: {
          'db_path': '/data/user/0/com.dayz/app_flutter/db/main.sqlite',
          'random_path': '/etc/hosts',
          'description':
              'Path is /var/mobile/Containers/Data/Application/X/Documents/media/a.bin',
        },
      );

      final redacted = Redactor.redact(record);
      expect(redacted.fields['db_path'], 'db/main.sqlite');
      expect(redacted.fields['random_path'], '<REDACTED_ABS>');
      expect(redacted.fields['description'], 'Path is media/a.bin');
    });
  });
}
