// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'console_sink.dart';
import 'log_level.dart';
import 'log_record.dart';
import 'log_sink.dart';
import 'redaction.dart';

/// AppLogger 日志门面。
///
/// 它是整个应用日志记录的唯一入口与信任根。
/// 提供分级过滤、惰性闭包求值、自动脱敏，并安全地分发到所有注册的 Sinks 中。
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();

  /// 获取 AppLogger 的全局单例实例。
  static AppLogger get instance => _instance;
  
  /// 获取当前已注册的所有 Sinks 列表
  List<LogSink> get sinks => List.unmodifiable(_sinks);

  LogLevel _level = LogLevel.info;
  final List<LogSink> _sinks = [];
  DateTime Function() _clock = DateTime.now;

  AppLogger._internal() {
    _sinks.add(ConsoleSink());
    _level = defaultLevelFor(kReleaseMode);
  }

  /// 供单元测试使用的构造函数，支持注入自定义参数。
  @visibleForTesting
  AppLogger.test({
    LogLevel? level,
    List<LogSink>? sinks,
    DateTime Function()? clock,
  })  : _level = level ?? LogLevel.fine,
        _clock = clock ?? DateTime.now {
    if (sinks != null) {
      _sinks.addAll(sinks);
    }
  }

  /// 设置当前日志记录的最低级别。
  void setLevel(LogLevel level) {
    _level = level;
  }

  /// 检查指定级别的日志是否可以被记录。
  bool isLoggable(LogLevel level) {
    return level >= _level;
  }

  /// 异步注册 Sink。
  Future<void> attachFileSink(LogSink sink) async {
    _sinks.add(sink);
  }

  /// 基础日志记录方法，仅记录事件码与自定义字段，不含自由文本消息。
  void log(LogLevel level, String event, {Map<String, Object?> fields = const {}}) {
    if (!isLoggable(level)) return;

    final record = LogRecord(
      level: level,
      event: event,
      ts: _clock(),
      message: null,
      fields: fields,
    );

    _dispatch(record);
  }

  void _logLazy(LogLevel level, Object messageOrBuilder, Map<String, Object?> fields) {
    if (!isLoggable(level)) return;

    if (messageOrBuilder is! String && messageOrBuilder is! String Function()) {
      throw ArgumentError('Message must be either a String or a String Function()');
    }

    String? message;
    if (messageOrBuilder is String Function()) {
      message = messageOrBuilder();
    } else if (messageOrBuilder is String) {
      message = messageOrBuilder;
    }

    final record = LogRecord(
      level: level,
      event: 'log',
      ts: _clock(),
      message: message,
      fields: fields,
    );

    _dispatch(record);
  }

  void _dispatch(LogRecord record) {
    final redacted = Redactor.redact(record);
    for (final sink in _sinks) {
      try {
        sink.add(redacted);
      } catch (_) {
        // 绝不向上抛出异常，保障调用端安全与降级
      }
    }
  }

  /// 等待当前所有 Sinks 完成日志写入。
  Future<void> flush() async {
    await Future.wait(_sinks.map((s) => s.flush()));
  }

  /// 关闭所有 Sinks 释放资源。
  Future<void> close() async {
    await Future.wait(_sinks.map((s) => s.close()));
  }

  /// 记录 FINE 级别日志（支持 String 或 String Function() 惰性构建）
  void logFine(Object messageOrBuilder, {Map<String, Object?> fields = const {}}) {
    _logLazy(LogLevel.fine, messageOrBuilder, fields);
  }

  /// 记录 INFO 级别日志（支持 String 或 String Function() 惰性构建）
  void logInfo(Object messageOrBuilder, {Map<String, Object?> fields = const {}}) {
    _logLazy(LogLevel.info, messageOrBuilder, fields);
  }

  /// 记录 WARNING 级别日志（支持 String 或 String Function() 惰性构建）
  void logWarning(Object messageOrBuilder, {Map<String, Object?> fields = const {}}) {
    _logLazy(LogLevel.warning, messageOrBuilder, fields);
  }

  /// 记录 SEVERE 级别日志（支持 String 或 String Function() 惰性构建）
  void logSevere(Object messageOrBuilder, {Map<String, Object?> fields = const {}}) {
    _logLazy(LogLevel.severe, messageOrBuilder, fields);
  }
}
