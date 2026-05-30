// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'log_record.dart';
import 'log_sink.dart';
import 'log_rotation.dart';

/// 具备大小轮转与异步有界队列的落盘日志 Sink。
///
/// * 单文件上限 1 MiB，最多保留 3 个备份文件。
/// * 写入发生在单写者异步循环中，不会阻塞调用方。
/// * 任何 I/O 或轮转失败都会静默降级并触发 Console 警告，决不抛出异常。
class RotatingFileSink implements LogSink {
  final Directory _logsDir;
  final String _logFilename;

  final List<LogRecord> _queue = [];
  bool _isProcessing = false;
  int _degradationCount = 0;
  Completer<void>? _flushCompleter;
  bool _isClosed = false;

  RotatingFileSink(this._logsDir, {this._logFilename = 'app.log'});

  /// 获取当前降级计数（丢弃或写入失败次数）
  int get degradationCount => _degradationCount;

  @override
  void add(LogRecord redacted) {
    if (_isClosed) return;

    if (_queue.length >= queueCapacity) {
      _queue.removeAt(0);
      _degradationCount++;
      _triggerDegradationWarning("Log queue overflow, oldest record dropped.");
    }

    _queue.add(redacted);
    _startProcessor();
  }

  void _startProcessor() {
    if (_isProcessing) return;
    _isProcessing = true;
    _processQueue();
  }

  Future<void> _processQueue() async {
    while (_queue.isNotEmpty) {
      final record = _queue.first;
      try {
        await _writeRecord(record);
      } catch (e) {
        _degradationCount++;
        _triggerDegradationWarning("Failed to write log record: $e");
      }
      _queue.removeAt(0);
    }
    _isProcessing = false;
    if (_flushCompleter != null) {
      _flushCompleter!.complete();
      _flushCompleter = null;
    }
  }

  Future<void> _writeRecord(LogRecord record) async {
    final tsStr = record.ts.toUtc().toIso8601String();
    final levelStr = record.level.name.toUpperCase();
    final eventStr = record.event;
    final msgStr = record.message != null ? ' - ${record.message}' : '';
    final fieldsStr = record.fields.isNotEmpty ? ' ${record.fields}' : '';
    final line = '[$tsStr] [$levelStr] [$eventStr]$msgStr$fieldsStr\n';
    final bytes = utf8.encode(line);

    if (!await _logsDir.exists()) {
      await _logsDir.create(recursive: true);
    }

    final file = File(p.join(_logsDir.path, _logFilename));
    int currentSize = 0;
    if (await file.exists()) {
      currentSize = await file.length();
    }

    final backupFiles = <String>[];
    await for (final entity in _logsDir.list()) {
      if (entity is File) {
        final name = p.basename(entity.path);
        if (name.startsWith('$_logFilename.')) {
          backupFiles.add(name);
        }
      }
    }

    final decision = evaluateRotation(currentSize, bytes.length, backupFiles);

    if (decision.rotate) {
      for (final toDelete in decision.filesToDelete) {
        final f = File(p.join(_logsDir.path, toDelete));
        if (await f.exists()) {
          await f.delete();
        }
      }

      for (var i = maxFiles - 1; i >= 1; i--) {
        final src = File(p.join(_logsDir.path, '$_logFilename.$i'));
        if (await src.exists()) {
          await src.rename(p.join(_logsDir.path, '$_logFilename.${i + 1}'));
        }
      }

      if (await file.exists()) {
        await file.rename(p.join(_logsDir.path, '$_logFilename.1'));
      }
    }

    await file.writeAsBytes(bytes, mode: FileMode.append, flush: true);
  }

  void _triggerDegradationWarning(String msg) {
    // ignore: avoid_print
    print('[OBSERVABILITY DEGRADED] $msg');
  }

  @override
  Future<void> flush() async {
    if (_queue.isEmpty && !_isProcessing) return;
    _flushCompleter ??= Completer<void>();
    await _flushCompleter!.future;
  }

  @override
  Future<void> close() async {
    _isClosed = true;
    await flush();
  }
}
