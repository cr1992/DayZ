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
  String _logsDirPath = 'Loading...';
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
        AppLogger.instance.logWarning(message, fields: {'test_field': 'warn_val'});
        break;
      case LogLevel.severe:
        AppLogger.instance.logSevere(message, fields: {'test_field': 'severe_val'});
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
      appBar: AppBar(
        title: const Text('Observability Demo'),
      ),
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
                    Text('Log Level: $currentLevel',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                    )
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
                    const Text('Trigger Log Records:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () =>
                              _triggerLog(LogLevel.fine, 'User triggered fine log'),
                          child: const Text('Log FINE'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _triggerLog(LogLevel.info, 'User triggered info log'),
                          child: const Text('Log INFO'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _triggerLog(LogLevel.warning, 'User triggered warning log'),
                          child: const Text('Log WARN'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _triggerLog(LogLevel.severe, 'User triggered severe log'),
                          child: const Text('Log SEVERE'),
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
                    const Text('Rotation & Degradation Status:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Logs Directory: $_logsDirPath'),
                    const SizedBox(height: 4),
                    Text('Degradation Count: $_degradationCount'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _forceRotation,
                          child: const Text('Force Rotation (1MB+)'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _refreshStatus,
                          child: const Text('Refresh Status'),
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
