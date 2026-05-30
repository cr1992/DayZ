// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'log_record.dart';
import 'log_sink.dart';

/// 零依赖的控制台输出 Sink。
///
/// 将已脱敏的 [LogRecord] 格式化为单行文本，并输出到标准输出/控制台。
class ConsoleSink implements LogSink {
  final void Function(String) _writer;

  /// 构造函数，支持注入自定义写入器（便于测试）
  ConsoleSink([void Function(String)? writer]) : _writer = writer ?? _defaultWriter;

  static void _defaultWriter(String line) {
    try {
      // ignore: avoid_print
      print(line);
    } catch (_) {
      // add 绝不能抛异常
    }
  }

  @override
  void add(LogRecord redacted) {
    try {
      final tsStr = redacted.ts.toUtc().toIso8601String();
      final levelStr = redacted.level.name.toUpperCase();
      final eventStr = redacted.event;
      final msgStr = redacted.message != null ? ' - ${redacted.message}' : '';
      final fieldsStr = redacted.fields.isNotEmpty ? ' ${redacted.fields}' : '';

      final line = '[$tsStr] [$levelStr] [$eventStr]$msgStr$fieldsStr';
      _writer(line);
    } catch (_) {
      // add 绝不能抛异常
    }
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> close() async {}
}
