// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart' show Value;
import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/media/media_store.dart';
import 'package:dayz/backup/backup_exporter.dart';
import 'package:dayz/backup/backup_restorer.dart';

class BackupDemo extends StatefulWidget {
  final AppDatabase? database;
  final KeyProvider? keyProvider;

  const BackupDemo({super.key, this.database, this.keyProvider});

  @override
  State<BackupDemo> createState() => _BackupDemoState();
}

class _BackupDemoState extends State<BackupDemo> {
  late AppDatabase _db;
  late final KeyProvider _keyProvider;
  late MediaStore _mediaStore;
  late File _dbFile;
  late bool _ownsDatabase;

  bool _busy = false;
  String _statusText = 'Ready';
  String _progressPhase = '';
  int _progressProcessed = 0;
  int _progressTotal = 0;
  String _integrityText = 'Self check has not run.';
  bool? _integrityPassed;
  String _benchmarkText = 'Benchmark has not run.';
  bool? _benchmarkPassed;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _benchmarkEntriesController =
      TextEditingController(text: '1000');
  final TextEditingController _benchmarkMediaController = TextEditingController(
    text: '50',
  );
  final TextEditingController _benchmarkMediaMiBController =
      TextEditingController(text: '1');

  List<Entry> _entries = [];
  List<MediaData> _media = [];
  List<String> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _keyProvider = widget.keyProvider ?? KeyProvider();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    setState(() {
      _busy = true;
      _statusText = 'Initializing database...';
    });

    try {
      if (widget.database != null) {
        _db = widget.database!;
        _ownsDatabase = false;
        final docs = await getApplicationDocumentsDirectory();
        _dbFile = File(p.join(docs.path, 'db', 'demo_backup.sqlite'));
      } else {
        final docs = await getApplicationDocumentsDirectory();
        _dbFile = File(p.join(docs.path, 'db', 'demo_backup.sqlite'));
        final appKey = await _keyProvider.getAppDbKey();
        _db = await AppDatabase.openFile(_dbFile, appKey);
        _ownsDatabase = true;
      }
      _recreateStores();
      await _refreshData();
      setState(() {
        _statusText = 'Database initialized successfully';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Initialization failed: $e';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  void _recreateStores() {
    _mediaStore = MediaStore(
      keyProvider: _keyProvider,
      mediaRepo: MediaRepo(_db),
      documentsDirectoryProvider: getApplicationDocumentsDirectory,
    );
  }

  Future<void> _refreshData() async {
    final entries = await _db.entriesDao.active().get();
    final media = await _db.mediaDao.active().get();
    setState(() {
      _entries = entries;
      _media = media;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _searchController.dispose();
    _benchmarkEntriesController.dispose();
    _benchmarkMediaController.dispose();
    _benchmarkMediaMiBController.dispose();
    if (_ownsDatabase) {
      _db.close();
    }
    super.dispose();
  }

  _BenchmarkConfig _readBenchmarkConfig() {
    return _BenchmarkConfig(
      entryCount: _readPositiveInt(_benchmarkEntriesController, 'entries'),
      mediaCount: _readPositiveInt(_benchmarkMediaController, 'media files'),
      mediaSizeMiB: _readPositiveInt(
        _benchmarkMediaMiBController,
        'media size MiB',
      ),
    );
  }

  int _readPositiveInt(TextEditingController controller, String label) {
    final value = int.tryParse(controller.text.trim());
    if (value == null || value <= 0) {
      throw FormatException('$label must be a positive integer');
    }
    return value;
  }

  Future<void> _dropLocalDataAndFiles() async {
    await _db.customStatement('DELETE FROM entries;');
    await _db.customStatement('DELETE FROM media;');
    await _db.customStatement('DELETE FROM entries_fts;');

    final docs = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(docs.path, 'media'));
    if (await mediaDir.exists()) {
      await mediaDir.delete(recursive: true);
    }
    final thumbsDir = Directory(p.join(docs.path, 'thumbs'));
    if (await thumbsDir.exists()) {
      await thumbsDir.delete(recursive: true);
    }
  }

  Future<Duration> _prepareBenchmarkData(_BenchmarkConfig config) async {
    final stopwatch = Stopwatch()..start();

    setState(() {
      _benchmarkText =
          'Seeding benchmark data: ${config.entryCount} entries, '
          '${config.mediaCount} media x ${config.mediaSizeMiB} MiB...';
      _benchmarkPassed = null;
    });

    await _dropLocalDataAndFiles();
    _recreateStores();

    final now = DateTime.now().toUtc();
    var inserted = 0;
    while (inserted < config.entryCount) {
      final next = inserted + 500;
      final end = next > config.entryCount ? config.entryCount : next;
      await _db.batch((batch) {
        for (var i = inserted; i < end; i++) {
          batch.insert(
            _db.entries,
            EntriesCompanion.insert(
              id: 'benchmark_entry_$i',
              contentPlain: Value(
                'Benchmark entry $i benchmarktoken grape restore perf data.',
              ),
              entryDtUtc: now.add(Duration(seconds: i)),
              entryTz: 'Etc/UTC',
              localYear: now.year,
              localMonth: now.month,
              localDay: now.day,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      });
      inserted = end;
      if (inserted == config.entryCount || inserted % 2000 == 0) {
        setState(() {
          _benchmarkText = 'Seeding entries: $inserted / ${config.entryCount}';
        });
      }
    }

    final mediaBytes = Uint8List(config.mediaSizeMiB * 1024 * 1024);
    final mediaStep = config.mediaCount < 20 ? 1 : config.mediaCount ~/ 10;
    for (var i = 0; i < config.mediaCount; i++) {
      await _mediaStore.put(
        bytes: Stream.value(mediaBytes),
        entryId: 'benchmark_entry_${i % config.entryCount}',
        kind: MediaKind.image,
        mime: 'image/png',
        fileSize: mediaBytes.length,
      );
      final done = i + 1;
      if (done == config.mediaCount || done % mediaStep == 0) {
        setState(() {
          _benchmarkText =
              'Seeding media: $done / ${config.mediaCount} '
              '(${config.mediaSizeMiB} MiB each)';
        });
      }
    }

    await _db.customStatement('DELETE FROM entries_fts;');
    await _db.customStatement(
      'INSERT INTO entries_fts(rowid, content_plain) SELECT rowid, content_plain FROM entries WHERE deleted_at IS NULL;',
    );
    await _refreshData();

    stopwatch.stop();
    return stopwatch.elapsed;
  }

  Future<void> _seedBenchmarkData() async {
    setState(() {
      _busy = true;
      _statusText = 'Preparing benchmark data...';
    });

    try {
      final config = _readBenchmarkConfig();
      final seedElapsed = await _prepareBenchmarkData(config);
      setState(() {
        _benchmarkPassed = true;
        _benchmarkText =
            'BENCHMARK DATA READY\n'
            'PASS seeded ${config.entryCount} entries and '
            '${config.mediaCount} media x ${config.mediaSizeMiB} MiB\n'
            'Seed time: ${_formatDuration(seedElapsed)}';
        _statusText = 'Benchmark data prepared successfully.';
      });
    } catch (e) {
      setState(() {
        _benchmarkPassed = false;
        _benchmarkText = 'BENCHMARK DATA FAILED\n$e';
        _statusText = 'Benchmark data preparation failed: $e';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _runFullBenchmark() async {
    setState(() {
      _busy = true;
      _statusText = 'Running full benchmark...';
      _benchmarkPassed = null;
    });

    try {
      final config = _readBenchmarkConfig();
      final seedElapsed = await _prepareBenchmarkData(config);
      final docs = await getApplicationDocumentsDirectory();
      final exportDir = Directory(p.join(docs.path, 'exports'));
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      final backupFile = File(p.join(exportDir.path, 'benchmark.mydiary'));

      setState(() {
        _benchmarkText = 'Running export benchmark...';
      });
      final exportStopwatch = Stopwatch()..start();
      final exporter = BackupExporter(database: _db, keyProvider: _keyProvider);
      await exporter.export(
        password: 'benchmarkpassword',
        outputPath: backupFile.path,
        onProgress: (phase, processed, total) {
          setState(() {
            _benchmarkText = 'Exporting: $phase ($processed / $total)';
          });
        },
      );
      exportStopwatch.stop();

      setState(() {
        _benchmarkText = 'Clearing local data before restore benchmark...';
      });
      await _dropLocalDataAndFiles();
      await _refreshData();

      final restorer = BackupRestorer(database: _db, keyProvider: _keyProvider);
      final session = await restorer.parseAndConfirm(
        inputPath: backupFile.path,
        password: 'benchmarkpassword',
        confirmOverwrite: () async => true,
      );

      setState(() {
        _benchmarkText = 'Running restore benchmark...';
      });
      final restoreStopwatch = Stopwatch()..start();
      final restoredDb = await restorer.apply(session);
      restoreStopwatch.stop();

      _db = restoredDb;
      _ownsDatabase = true;
      _recreateStores();
      await _refreshData();

      final ftsRows = await _db
          .customSelect(
            "SELECT rowid FROM entries_fts WHERE entries_fts MATCH 'benchmarktoken';",
          )
          .get();
      final entryOk = _entries.length == config.entryCount;
      final mediaOk = _media.length == config.mediaCount;
      final ftsOk = ftsRows.length == config.entryCount;
      final exportPassed = exportStopwatch.elapsed < const Duration(minutes: 3);
      final restorePassed =
          restoreStopwatch.elapsed < const Duration(minutes: 4);
      final dataPassed = entryOk && mediaOk && ftsOk;
      final benchmarkPassed = exportPassed && restorePassed && dataPassed;
      final backupSizeMiB = await backupFile.length() / (1024 * 1024);

      setState(() {
        _benchmarkPassed = benchmarkPassed;
        _benchmarkText =
            'BENCHMARK: ${benchmarkPassed ? "PASS" : "FAIL"}\n'
            'Config: ${config.entryCount} entries, '
            '${config.mediaCount} media x ${config.mediaSizeMiB} MiB\n'
            'Seed: ${_formatDuration(seedElapsed)}\n'
            '${exportPassed ? "PASS" : "FAIL"} export: '
            '${_formatDuration(exportStopwatch.elapsed)} (target < 180s)\n'
            '${restorePassed ? "PASS" : "FAIL"} restore: '
            '${_formatDuration(restoreStopwatch.elapsed)} (target < 240s)\n'
            '${entryOk ? "PASS" : "FAIL"} entries restored: '
            '${_entries.length}/${config.entryCount}\n'
            '${mediaOk ? "PASS" : "FAIL"} media rows restored: '
            '${_media.length}/${config.mediaCount}\n'
            '${ftsOk ? "PASS" : "FAIL"} FTS benchmarktoken rows: '
            '${ftsRows.length}/${config.entryCount}\n'
            'Backup size: ${backupSizeMiB.toStringAsFixed(1)} MiB\n'
            'RSS: measure with Xcode Instruments / Android Studio Profiler';
        _statusText = 'Benchmark completed.';
      });
    } catch (e) {
      setState(() {
        _benchmarkPassed = false;
        _benchmarkText = 'BENCHMARK FAILED\n$e';
        _statusText = 'Benchmark failed: $e';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final totalMs = duration.inMilliseconds;
    if (totalMs < 1000) {
      return '${totalMs}ms';
    }
    return '${(totalMs / 1000).toStringAsFixed(1)}s';
  }

  void _useSpecBenchmarkScale() {
    setState(() {
      _benchmarkEntriesController.text = '10000';
      _benchmarkMediaController.text = '500';
      _benchmarkMediaMiBController.text = '3';
      _benchmarkPassed = null;
      _benchmarkText =
          'Spec scale selected: 10000 entries + 500 media x 3 MiB. '
          'Expect long runtime and several GiB of temporary disk usage.';
    });
  }

  InputDecoration _darkBenchmarkInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.black26,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white54),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Future<void> _fillTestData() async {
    setState(() {
      _busy = true;
      _statusText = 'Seeding test data...';
    });

    try {
      final now = DateTime.now().toUtc();

      // Clear existing first for clean demo state
      await _db.customStatement('DELETE FROM entries;');
      await _db.customStatement('DELETE FROM media;');
      await _db.customStatement('DELETE FROM entries_fts;');

      // Insert 3 entries
      await _db.entriesDao.insertEntry(
        EntriesCompanion.insert(
          id: 'entry_1',
          contentPlain: const Value('Apple banana orange tree fruit'),
          entryDtUtc: now,
          entryTz: 'Etc/UTC',
          localYear: now.year,
          localMonth: now.month,
          localDay: now.day,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await _db.entriesDao.insertEntry(
        EntriesCompanion.insert(
          id: 'entry_2',
          contentPlain: const Value('Grape pineapple strawberry sweet berries'),
          entryDtUtc: now.add(const Duration(hours: 1)),
          entryTz: 'Etc/UTC',
          localYear: now.year,
          localMonth: now.month,
          localDay: now.day,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await _db.entriesDao.insertEntry(
        EntriesCompanion.insert(
          id: 'entry_3',
          contentPlain: const Value('Cherry blue sky clouds airplane flight'),
          entryDtUtc: now.add(const Duration(hours: 2)),
          entryTz: 'Etc/UTC',
          localYear: now.year,
          localMonth: now.month,
          localDay: now.day,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Insert 2 media files
      final bytes = utf8.encode('Demo photo metadata image contents');

      await _mediaStore.put(
        bytes: Stream.value(bytes),
        entryId: 'entry_1',
        kind: MediaKind.image,
        mime: 'image/png',
        fileSize: bytes.length,
      );

      await _mediaStore.put(
        bytes: Stream.value(bytes),
        entryId: 'entry_2',
        kind: MediaKind.image,
        mime: 'image/jpeg',
        fileSize: bytes.length,
      );

      // Rebuild FTS
      await _db.customStatement('DELETE FROM entries_fts;');
      await _db.customStatement(
        'INSERT INTO entries_fts(rowid, content_plain) SELECT rowid, content_plain FROM entries WHERE deleted_at IS NULL;',
      );

      await _refreshData();
      setState(() {
        _statusText = 'Successfully seeded 3 entries and 2 media files.';
        _integrityText = 'Self check has not run after seeding.';
        _integrityPassed = null;
      });
    } catch (e) {
      setState(() {
        _statusText = 'Failed to seed data: $e';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _exportBackup() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a password first')),
      );
      return;
    }

    _passwordController.clear(); // Clear immediately for security

    setState(() {
      _busy = true;
      _statusText = 'Exporting backup...';
      _progressPhase = 'starting';
      _progressProcessed = 0;
      _progressTotal = 100;
    });

    try {
      final docs = await getApplicationDocumentsDirectory();
      final exportDir = Directory(p.join(docs.path, 'exports'));
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      final outputFile = File(p.join(exportDir.path, 'test.mydiary'));

      final exporter = BackupExporter(database: _db, keyProvider: _keyProvider);
      await exporter.export(
        password: password,
        outputPath: outputFile.path,
        onProgress: (phase, processed, total) {
          setState(() {
            _progressPhase = phase;
            _progressProcessed = processed;
            _progressTotal = total;
            _statusText = 'Exporting: $phase ($processed / $total)';
          });
        },
      );

      setState(() {
        _statusText = 'Backup successfully saved to exports/test.mydiary';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Backup failed: $e';
      });
    } finally {
      setState(() {
        _busy = false;
        _progressPhase = '';
      });
    }
  }

  Future<void> _clearLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Clear Data'),
        content: const Text(
          'Are you sure you want to drop all entries, media, and search indexes? This is irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Drop All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _statusText = 'Clearing database...';
    });

    try {
      await _db.customStatement('DELETE FROM entries;');
      await _db.customStatement('DELETE FROM media;');
      await _db.customStatement('DELETE FROM entries_fts;');

      final docs = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(p.join(docs.path, 'media'));
      if (await mediaDir.exists()) {
        await mediaDir.delete(recursive: true);
      }
      final thumbsDir = Directory(p.join(docs.path, 'thumbs'));
      if (await thumbsDir.exists()) {
        await thumbsDir.delete(recursive: true);
      }

      await _refreshData();
      setState(() {
        _searchResults.clear();
        _integrityText = 'Self check has not run after clearing local data.';
        _integrityPassed = null;
        _statusText = 'Local database and media files cleared successfully';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Clear failed: $e';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _restoreBackup() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a password first')),
      );
      return;
    }

    _passwordController.clear(); // Clear immediately for security

    setState(() {
      _busy = true;
      _statusText = 'Reading backup file...';
    });

    try {
      final docs = await getApplicationDocumentsDirectory();
      final backupFile = File(p.join(docs.path, 'exports', 'test.mydiary'));
      if (!await backupFile.exists()) {
        throw Exception(
          'Backup file test.mydiary not found. Please export first.',
        );
      }

      final restorer = BackupRestorer(database: _db, keyProvider: _keyProvider);

      final session = await restorer.parseAndConfirm(
        inputPath: backupFile.path,
        password: password,
        confirmOverwrite: () async {
          final confirmOverwrite = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Overwrite Confirmation'),
              content: const Text(
                'A valid backup package was found. Do you want to overwrite all local database and media files with this backup?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Abort'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Overwrite'),
                ),
              ],
            ),
          );
          return confirmOverwrite == true;
        },
      );

      setState(() {
        _statusText = 'Restoring database & media...';
      });

      final restoredDb = await restorer.apply(session);
      _db = restoredDb;
      _ownsDatabase = true;

      _recreateStores();
      await _refreshData();
      await _runIntegrityCheck();

      setState(() {
        _statusText = 'Restore completed successfully!';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Restore failed: $e';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _runIntegrityCheck() async {
    try {
      await _refreshData();
      final docs = await getApplicationDocumentsDirectory();
      final backupFile = File(p.join(docs.path, 'exports', 'test.mydiary'));
      final checks = <String>[];
      var passed = true;

      void check(bool condition, String label) {
        checks.add('${condition ? "PASS" : "FAIL"} $label');
        passed = passed && condition;
      }

      check(_entries.length == 3, 'entries restored: ${_entries.length}/3');
      check(_media.length == 2, 'media rows restored: ${_media.length}/2');

      var decryptableMedia = 0;
      for (final media in _media) {
        try {
          final bytes = await _mediaStore
              .openRead(media.relPath)
              .fold<List<int>>([], (p, e) => p..addAll(e));
          if (bytes.isNotEmpty) {
            decryptableMedia++;
          }
        } catch (_) {}
      }
      check(
        _media.isNotEmpty && decryptableMedia == _media.length,
        'media decryptable: $decryptableMedia/${_media.length}',
      );

      final ftsRows = await _db
          .customSelect(
            "SELECT content_plain FROM entries WHERE rowid IN "
            "(SELECT rowid FROM entries_fts WHERE entries_fts MATCH 'grape');",
          )
          .get();
      final ftsMatched =
          ftsRows.length == 1 &&
          ftsRows.first
              .read<String>('content_plain')
              .contains('Grape pineapple strawberry');
      check(ftsMatched, 'FTS search grape returns restored entry');

      final backupExists =
          await backupFile.exists() && await backupFile.length() > 0;
      check(backupExists, 'exports/test.mydiary exists and is non-empty');
      check(_passwordController.text.isEmpty, 'password field is cleared');

      setState(() {
        _integrityPassed = passed;
        _integrityText = checks.join('\n');
      });
    } catch (e) {
      setState(() {
        _integrityPassed = false;
        _integrityText = 'FAIL self check threw: $e';
      });
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    try {
      final results = await _db
          .customSelect(
            "SELECT content_plain FROM entries WHERE rowid IN "
            "(SELECT rowid FROM entries_fts WHERE entries_fts MATCH '${query.replaceAll("'", "''")}');",
          )
          .get();

      setState(() {
        _searchResults = results
            .map((r) => r.read<String>('content_plain'))
            .toList();
      });
    } catch (e) {
      setState(() {
        _statusText = 'Search error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressVal = _progressTotal > 0
        ? _progressProcessed / _progressTotal
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore Demo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.grey[900],
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS: $_statusText',
                      style: TextStyle(
                        color:
                            _statusText.contains('failed') ||
                                _statusText.contains('Error')
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (_progressPhase.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: progressVal),
                      const SizedBox(height: 4),
                      Text(
                        'Progress: ${(_progressProcessed / _progressTotal * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              key: const Key('backup-demo-integrity'),
              color: Colors.grey[850],
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELF CHECK: ${_integrityPassed == null
                          ? "NOT RUN"
                          : _integrityPassed!
                          ? "PASS"
                          : "FAIL"}',
                      key: const Key('backup-demo-integrity-summary'),
                      style: TextStyle(
                        color: _integrityPassed == null
                            ? Colors.white70
                            : _integrityPassed!
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _integrityText,
                      key: const Key('backup-demo-integrity-details'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('backup-demo-password'),
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Backup Password',
                border: OutlineInputBorder(),
                helperText:
                    'Required for Export and Restore. Password is cleared after input.',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  key: const Key('backup-demo-seed'),
                  onPressed: _busy ? null : _fillTestData,
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Seed Test Data'),
                ),
                ElevatedButton.icon(
                  key: const Key('backup-demo-export'),
                  onPressed: _busy ? null : _exportBackup,
                  icon: const Icon(Icons.unarchive),
                  label: const Text('Export .mydiary'),
                ),
                ElevatedButton.icon(
                  key: const Key('backup-demo-clear'),
                  onPressed: _busy ? null : _clearLocalData,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Clear Local Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                  ),
                ),
                ElevatedButton.icon(
                  key: const Key('backup-demo-restore'),
                  onPressed: _busy ? null : _restoreBackup,
                  icon: const Icon(Icons.system_update_alt),
                  label: const Text('Restore Backup'),
                ),
                ElevatedButton.icon(
                  key: const Key('backup-demo-self-check'),
                  onPressed: _busy ? null : _runIntegrityCheck,
                  icon: const Icon(Icons.fact_check),
                  label: const Text('Run Self Check'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              key: const Key('backup-demo-benchmark'),
              color: Colors.grey[850],
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'BENCHMARK: ${_benchmarkPassed == null
                          ? "NOT RUN"
                          : _benchmarkPassed!
                          ? "PASS"
                          : "FAIL"}',
                      key: const Key('backup-demo-benchmark-summary'),
                      style: TextStyle(
                        color: _benchmarkPassed == null
                            ? Colors.white70
                            : _benchmarkPassed!
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _benchmarkText,
                      key: const Key('backup-demo-benchmark-details'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('backup-demo-benchmark-entries'),
                            controller: _benchmarkEntriesController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            decoration: _darkBenchmarkInputDecoration(
                              'Entries',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            key: const Key('backup-demo-benchmark-media'),
                            controller: _benchmarkMediaController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            decoration: _darkBenchmarkInputDecoration(
                              'Media files',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            key: const Key('backup-demo-benchmark-media-mib'),
                            controller: _benchmarkMediaMiBController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            decoration: _darkBenchmarkInputDecoration(
                              'MiB each',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          key: const Key('backup-demo-benchmark-seed'),
                          onPressed: _busy ? null : _seedBenchmarkData,
                          icon: const Icon(Icons.storage),
                          label: const Text('Seed Benchmark Data'),
                        ),
                        ElevatedButton.icon(
                          key: const Key('backup-demo-benchmark-run'),
                          onPressed: _busy ? null : _runFullBenchmark,
                          icon: const Icon(Icons.speed),
                          label: const Text('Run Full Benchmark'),
                        ),
                        OutlinedButton.icon(
                          key: const Key('backup-demo-benchmark-spec-scale'),
                          onPressed: _busy ? null : _useSpecBenchmarkScale,
                          icon: const Icon(Icons.warning_amber),
                          label: const Text('Use Spec Scale'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Default is a simulator-friendly smoke scale: 1000 entries + 50 media x 1 MiB. Use Spec Scale for 10000 entries + 500 media x 3 MiB. RSS still needs system Profiler.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'FTS Full-Text Search',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _performSearch,
                  child: const Text('Search'),
                ),
              ],
            ),
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Search Matches:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.search),
                  title: Text(_searchResults[index]),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Active Database Content (${_entries.length} Entries, ${_media.length} Media Files):',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                final mediaList = _media
                    .where((m) => m.entryId == entry.id)
                    .toList();
                return Card(
                  child: ListTile(
                    title: Text(entry.contentPlain),
                    subtitle: Text(
                      'ID: ${entry.id} | Timestamp: ${entry.entryDtUtc.toLocal()}\n'
                      'Linked Media: ${mediaList.map((m) => m.id).join(', ')}',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BenchmarkConfig {
  final int entryCount;
  final int mediaCount;
  final int mediaSizeMiB;

  const _BenchmarkConfig({
    required this.entryCount,
    required this.mediaCount,
    required this.mediaSizeMiB,
  });
}
