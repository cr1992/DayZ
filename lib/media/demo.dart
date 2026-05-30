// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../data/time_zone_triple.dart';
import '../gen/assets.gen.dart';
import '../security/key_provider.dart';
import 'media_store.dart';
import 'paths.dart';

typedef DemoBytesLoader = Future<Uint8List> Function();
typedef BackupFileFactory = Future<File> Function();
typedef DemoMediaFileResolver = Future<File> Function(String relPath);

class MediaDemo extends StatefulWidget {
  final MediaStore? store;
  final String? entryId;
  final DemoBytesLoader? loadDemoBytes;
  final BackupFileFactory? createBackupFile;
  final DemoMediaFileResolver? resolveMediaFile;

  const MediaDemo({
    super.key,
    this.store,
    this.entryId,
    this.loadDemoBytes,
    this.createBackupFile,
    this.resolveMediaFile,
  });

  @override
  State<MediaDemo> createState() => _MediaDemoState();
}

class _MediaDemoState extends State<MediaDemo> {
  late final MediaStore _store;

  String? _entryId;
  String? _relPath;
  String? _plainSha256;
  String? _readSha256;
  String? _backupHeaderHex;
  int? _plainSize;
  int? _encryptedSize;
  bool _busy = false;
  String _status = 'Ready';

  @override
  void initState() {
    super.initState();
    initTimezoneData();
    _entryId = widget.entryId ?? 'media-demo-entry';
    _store =
        widget.store ??
        MediaStore.withRepository(
          loadDeviceMediaKey: KeyProvider().getDeviceMediaKey,
          metadataRepository: _DemoMetadataRepository(),
        );
  }

  Future<void> _writeDemoImage() {
    return _run('Writing demo image', () async {
      final entryId = await _ensureEntryId();
      final bytes = await _loadDemoBytes();
      final relPath = await _store.put(
        bytes: Stream<List<int>>.value(bytes),
        entryId: entryId,
        kind: MediaKind.image,
        mime: 'image/png',
        fileSize: bytes.length,
      );
      final encryptedFile = await _resolveMediaFile(relPath);
      final encryptedSize = await encryptedFile.length();
      final sha = await _sha256Hex(bytes);

      setState(() {
        _relPath = relPath;
        _plainSha256 = sha;
        _readSha256 = null;
        _backupHeaderHex = null;
        _plainSize = bytes.length;
        _encryptedSize = encryptedSize;
        _status = 'Written: $relPath';
      });
    });
  }

  Future<void> _readAndVerify() {
    return _run('Reading media', () async {
      final relPath = _relPath;
      if (relPath == null) {
        setState(() {
          _status = 'No media written';
        });
        return;
      }

      final bytes = await _collect(_store.openRead(relPath));
      final sha = await _sha256Hex(bytes);
      setState(() {
        _readSha256 = sha;
        _status = sha == _plainSha256 ? 'Verified: sha256 match' : 'Mismatch';
      });
    });
  }

  Future<void> _encryptForBackup() {
    return _run('Encrypting backup copy', () async {
      final relPath = _relPath;
      if (relPath == null) {
        setState(() {
          _status = 'No media written';
        });
        return;
      }

      final backupFile = await _createBackupFile();
      final sink = backupFile.openWrite();
      try {
        await sink.addStream(
          _store.encryptForBackup(
            _store.streamForBackup(relPath),
            _demoBackupKey(),
          ),
        );
      } finally {
        await sink.close();
      }

      final header = await backupFile.openRead(0, 16).fold<BytesBuilder>(
        BytesBuilder(copy: false),
        (builder, chunk) {
          builder.add(chunk);
          return builder;
        },
      );
      setState(() {
        _backupHeaderHex = _hex(header.takeBytes());
        _status = 'Backup encrypted';
      });
    });
  }

  Future<void> _run(String status, Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _status = status;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'Error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<String> _ensureEntryId() async {
    return _entryId ?? 'media-demo-entry';
  }

  Future<Uint8List> _loadDemoBytes() async {
    final loader = widget.loadDemoBytes;
    if (loader != null) {
      return loader();
    }
    final data = await rootBundle.load(Assets.editor.demoImage.path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<File> _createBackupFile() async {
    final factory = widget.createBackupFile;
    if (factory != null) {
      return factory();
    }
    final temp = await getTemporaryDirectory();
    return File('${temp.path}/dayz_media_backup_demo.bin');
  }

  Future<File> _resolveMediaFile(String relPath) {
    final resolver = widget.resolveMediaFile;
    if (resolver != null) {
      return resolver(relPath);
    }
    return resolveRelPath(relPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                key: const Key('media-demo-write'),
                onPressed: _busy ? null : _writeDemoImage,
                child: const Text('写入 demo 图'),
              ),
              ElevatedButton(
                key: const Key('media-demo-read'),
                onPressed: _busy ? null : _readAndVerify,
                child: const Text('读取并校验'),
              ),
              ElevatedButton(
                key: const Key('media-demo-backup'),
                onPressed: _busy ? null : _encryptForBackup,
                child: const Text('重加密为备份'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(_status, key: const Key('media-demo-status')),
          if (_relPath != null) Text('rel_path: $_relPath'),
          if (_plainSize != null && _encryptedSize != null)
            Text('size: plain=$_plainSize, encrypted=$_encryptedSize'),
          if (_plainSha256 != null) Text('plain sha256: $_plainSha256'),
          if (_readSha256 != null) Text('read sha256: $_readSha256'),
          if (_backupHeaderHex != null)
            Text('backup header: $_backupHeaderHex'),
        ],
      ),
    );
  }
}

Future<String> _sha256Hex(List<int> bytes) async {
  final digest = await Sha256().hash(bytes);
  return _hex(digest.bytes);
}

String _hex(List<int> bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

Uint8List _demoBackupKey() {
  return Uint8List.fromList(List<int>.generate(32, (index) => 0x80 + index));
}

Future<Uint8List> _collect(Stream<List<int>> stream) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in stream) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}

class _DemoMetadataRepository implements MediaMetadataRepository {
  final Set<String> _ids = <String>{};

  @override
  Future<void> addMeta(
    String id,
    String entryId,
    String kind,
    String relPath, {
    String? mime,
    int? width,
    int? height,
    int? durationMs,
    int? fileSize,
  }) async {
    _ids.add(id);
  }

  @override
  Future<void> hardDelete(String id) async {
    _ids.remove(id);
  }

  @override
  Future<void> softDelete(String id) async {
    if (!_ids.contains(id)) {
      throw StateError('Media not found: $id');
    }
  }
}
