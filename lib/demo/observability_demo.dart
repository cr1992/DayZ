// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dayz/observability/observability.dart';
import 'package:dayz/observability/rotating_file_sink.dart';
import 'package:dayz/observability/log_paths.dart';

class ObservabilityDemo extends StatefulWidget {
  const ObservabilityDemo({super.key});

  @override
  State<ObservabilityDemo> createState() => _ObservabilityDemoState();
}

class _ObservabilityDemoState extends State<ObservabilityDemo> {
  RotatingFileSink? _fileSink;
  String _logsDirPath = '加载中...';
  int _degradationCount = 0;

  @override
  void initState() {
    super.initState();
    _initFileSink();
  }

  Future<void> _initFileSink() async {
    final appSupport = await getApplicationSupportDirectory();
    final logsDir = resolveLogsDir(appSupport);
    setState(() {
      _logsDirPath = logsDir.path;
    });

    final logger = AppLogger.instance;
    var sink = logger.sinks.whereType<RotatingFileSink>().firstOrNull;
    if (sink == null) {
      sink = RotatingFileSink(logsDir);
      await logger.attachFileSink(sink);
    }
    setState(() {
      _fileSink = sink;
      _degradationCount = sink!.degradationCount;
    });
  }

  void _refreshStatus() {
    if (_fileSink != null) {
      setState(() {
        _degradationCount = _fileSink!.degradationCount;
      });
    }
  }

  void _triggerLog(LogLevel level, String message) {
    switch (level) {
      case LogLevel.fine:
        AppLogger.instance.logFine(message, fields: {'test_field': 'fine_val'});
        break;
      case LogLevel.info:
        AppLogger.instance.logInfo(message, fields: {'test_field': 'info_val'});
        break;
      case LogLevel.warning:
        AppLogger.instance.logWarning(
          message,
          fields: {'test_field': 'warn_val'},
        );
        break;
      case LogLevel.severe:
        AppLogger.instance.logSevere(
          message,
          fields: {'test_field': 'severe_val'},
        );
        break;
    }
    _refreshStatus();
  }

  void _forceRotation() {
    // 写入一个超过 1 MiB 的大对象强制轮转
    final largeMsg = 'R' * (1024 * 1024 + 100);
    AppLogger.instance.logInfo(largeMsg);
    _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final currentLevel = AppLogger.instance.isLoggable(LogLevel.fine)
        ? 'FINE'
        : AppLogger.instance.isLoggable(LogLevel.info)
        ? 'INFO'
        : AppLogger.instance.isLoggable(LogLevel.warning)
        ? 'WARNING'
        : 'SEVERE';

    return Scaffold(
      appBar: AppBar(title: const Text('可观测性演示')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '日志级别：$currentLevel',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            AppLogger.instance.setLevel(LogLevel.fine);
                            setState(() {});
                          },
                          child: const Text('FINE'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            AppLogger.instance.setLevel(LogLevel.info);
                            setState(() {});
                          },
                          child: const Text('INFO'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            AppLogger.instance.setLevel(LogLevel.warning);
                            setState(() {});
                          },
                          child: const Text('WARN'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            AppLogger.instance.setLevel(LogLevel.severe);
                            setState(() {});
                          },
                          child: const Text('SEVERE'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '触发日志记录：',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () =>
                              _triggerLog(LogLevel.fine, '用户触发 FINE 日志'),
                          child: const Text('记录 FINE'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _triggerLog(LogLevel.info, '用户触发 INFO 日志'),
                          child: const Text('记录 INFO'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _triggerLog(LogLevel.warning, '用户触发 WARN 日志'),
                          child: const Text('记录 WARN'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _triggerLog(LogLevel.severe, '用户触发 SEVERE 日志'),
                          child: const Text('记录 SEVERE'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '轮转与降级状态：',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('日志目录：$_logsDirPath'),
                    const SizedBox(height: 4),
                    Text('降级次数：$_degradationCount'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _forceRotation,
                          child: const Text('强制轮转（1MB+）'),
                        ),
                        ElevatedButton(
                          onPressed: _refreshStatus,
                          child: const Text('刷新状态'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
