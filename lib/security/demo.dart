// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:typed_data';

import 'package:dayz/security/argon2_kdf.dart';
import 'package:dayz/security/device_key.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:flutter/material.dart';

typedef DeviceKeyExistsLoader = Future<bool> Function();
typedef AppPasswordModeLoader = Future<AppPasswordMode> Function();
typedef SecurityDeriveBenchmarker = Future<Duration> Function();

class SecurityDemo extends StatefulWidget {
  final DeviceKeyExistsLoader? deviceKeyExists;
  final AppPasswordModeLoader? modeLoader;
  final SecurityDeriveBenchmarker? deriveBenchmarker;

  const SecurityDemo({
    super.key,
    this.deviceKeyExists,
    this.modeLoader,
    this.deriveBenchmarker,
  });

  @override
  State<SecurityDemo> createState() => _SecurityDemoState();
}

class _SecurityDemoState extends State<SecurityDemo> {
  bool _loading = true;
  bool? _deviceKeyReady;
  AppPasswordMode? _mode;
  bool _running = false;
  Duration? _lastElapsed;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final existsLoader = widget.deviceKeyExists ?? DeviceKey.exists;
      final modeLoader = widget.modeLoader ?? KeyProvider().currentMode;
      final ready = await existsLoader();
      final mode = await modeLoader();
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _deviceKeyReady = ready;
        _mode = mode;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '状态读取失败：$error';
      });
    }
  }

  Future<void> _runBenchmark() async {
    setState(() {
      _running = true;
      _error = null;
    });

    try {
      final benchmarker = widget.deriveBenchmarker ?? _defaultBenchmarker;
      final elapsed = await benchmarker();
      if (!mounted) {
        return;
      }
      setState(() {
        _lastElapsed = elapsed;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = '派生失败：$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
        });
      }
    }
  }

  Future<Duration> _defaultBenchmarker() async {
    final stopwatch = Stopwatch()..start();
    await Argon2Kdf.deriveKey(
      Uint8List.fromList('security-demo-password'.codeUnits),
      Uint8List.fromList(List<int>.generate(16, (index) => index + 1)),
      const KdfParams.v1(),
    );
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  String _deviceKeyStatusText() {
    if (_loading) {
      return '读取中…';
    }
    return _deviceKeyReady == true ? '已生成' : '未生成';
  }

  String _modeText() {
    if (_loading) {
      return '读取中…';
    }
    return switch (_mode) {
      AppPasswordMode.password => 'password',
      _ => 'none',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('设备密钥状态'),
            subtitle: Text(_deviceKeyStatusText()),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('当前模式'),
            subtitle: Text(_modeText()),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _running ? null : _runBenchmark,
            child: Text(_running ? '派生中…' : '触发一次 Argon2 派生'),
          ),
          const SizedBox(height: 12),
          if (_lastElapsed != null)
            Text('最近派生耗时：${_lastElapsed!.inMilliseconds} ms'),
          if (_error != null) ...[const SizedBox(height: 12), Text(_error!)],
        ],
      ),
    );
  }
}
