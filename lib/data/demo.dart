// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';

import '../observability/observability.dart';
import 'database.dart';
import 'repositories/entry_repo.dart';
import 'repositories/journal_repo.dart';
import 'time_zone_triple.dart';

class DataDemo extends StatefulWidget {
  final AppDatabase? database;

  const DataDemo({super.key, this.database});

  @override
  State<DataDemo> createState() => _DataDemoState();
}

class _DataDemoState extends State<DataDemo> {
  static const int _maxEventLines = 12;

  late final AppDatabase _db;
  late final JournalRepo _journalRepo;
  late final EntryRepo _entryRepo;
  late final bool _ownsDatabase;

  List<Journal> _journals = const [];
  List<Entry> _entries = const [];
  List<String> _eventLines = const [];
  String _status = 'Ready';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    initTimezoneData();
    _db = widget.database ?? AppDatabase(NativeDatabase.memory());
    _ownsDatabase = widget.database == null;
    _journalRepo = JournalRepo(_db);
    _entryRepo = EntryRepo(_db);
    _recordEvent('data.demo.init', fields: {'owns_database': _ownsDatabase});
    _refresh();
  }

  @override
  void dispose() {
    _recordEvent(
      'data.demo.dispose',
      fields: {'owns_database': _ownsDatabase},
      appendToUi: false,
    );
    if (_ownsDatabase) {
      _db.close();
    }
    super.dispose();
  }

  Future<void> _run(
    String status,
    String event,
    Future<void> Function() action,
  ) async {
    setState(() {
      _busy = true;
      _status = status;
    });

    _recordEvent('$event.start');
    try {
      await action();
      await _refresh(setBusy: false);
      _recordEvent(
        '$event.ok',
        fields: {'journals': _journals.length, 'entries': _entries.length},
      );
    } catch (error) {
      _recordEvent('$event.error', error: error);
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

  Future<void> _refresh({bool setBusy = true}) async {
    if (setBusy && mounted) {
      setState(() {
        _busy = true;
      });
    }

    final journals = await _journalRepo.list();
    final page = await _entryRepo.timeline(limit: 10);
    _recordEvent(
      'data.demo.refresh.ok',
      fields: {'journals': journals.length, 'entries': page.items.length},
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _journals = journals;
      _entries = page.items;
      _status = 'Journals: ${journals.length}, entries: ${page.items.length}';
      if (setBusy) {
        _busy = false;
      }
    });
  }

  Future<Journal> _ensureJournal() async {
    final journals = await _journalRepo.list();
    if (journals.isNotEmpty) {
      _recordEvent(
        'data.demo.ensure-journal.existing',
        fields: {'journal_id': _shortId(journals.first.id)},
      );
      return journals.first;
    }
    final journal = await _journalRepo.create(
      'Data demo journal',
      color: '#4D7CFE',
    );
    _recordEvent(
      'data.demo.ensure-journal.created',
      fields: {'journal_id': _shortId(journal.id)},
    );
    return journal;
  }

  Future<void> _createJournal() {
    return _run('Creating journal', 'data.demo.create-journal', () async {
      final journal = await _journalRepo.create(
        'Journal ${_journals.length + 1}',
        sortOrder: _journals.length,
      );
      _recordEvent(
        'data.demo.create-journal.inserted',
        fields: {'journal_id': _shortId(journal.id)},
      );
    });
  }

  Future<void> _createEntry() {
    return _run('Creating entry', 'data.demo.create-entry', () async {
      final journal = await _ensureJournal();
      final now = DateTime.now().toUtc();
      final entry = await _entryRepo.create(
        journalId: journal.id,
        contentJson: '{"insert":"Data demo entry"}',
        contentPlain: 'Data demo entry ${_entries.length + 1}',
        entryDtUtc: now,
        entryTz: 'Asia/Shanghai',
      );
      _recordEvent(
        'data.demo.create-entry.inserted',
        fields: {
          'entry_id': _shortId(entry.id),
          'journal_id': _shortId(journal.id),
          'entry_tz': entry.entryTz.replaceAll('/', '_'),
          'local_date':
              '${entry.localYear}-${entry.localMonth}-${entry.localDay}',
        },
      );
    });
  }

  Future<void> _loadTimeline() {
    return _run('Loading timeline', 'data.demo.load-timeline', () async {
      final page = await _entryRepo.timeline(limit: 10);
      _recordEvent(
        'data.demo.load-timeline.loaded',
        fields: {
          'entries': page.items.length,
          'next_cursor': page.nextCursor != null,
        },
      );
    });
  }

  Future<void> _softDeleteFirstEntry() {
    return _run('Soft deleting entry', 'data.demo.soft-delete', () async {
      if (_entries.isEmpty) {
        _recordEvent('data.demo.soft-delete.skipped-empty');
        return;
      }
      final entryId = _entries.first.id;
      await _entryRepo.softDelete(entryId);
      _recordEvent(
        'data.demo.soft-delete.deleted',
        fields: {'entry_id': _shortId(entryId)},
      );
    });
  }

  void _recordEvent(
    String event, {
    Map<String, Object?> fields = const {},
    Object? error,
    bool appendToUi = true,
  }) {
    final safeFields = <String, Object?>{
      ...fields,
      if (error != null) 'error_type': error.runtimeType.toString(),
    };

    if (error == null) {
      AppLogger.instance.log(LogLevel.info, event, fields: safeFields);
    } else {
      AppLogger.instance.log(LogLevel.warning, event, fields: safeFields);
    }

    if (!appendToUi || !mounted) {
      return;
    }
    final suffix = safeFields.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    final line = suffix.isEmpty ? event : '$event $suffix';
    setState(() {
      _eventLines = [line, ..._eventLines].take(_maxEventLines).toList();
    });
  }

  String _shortId(String id) {
    return id.length <= 8 ? id : id.substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('data-demo-create-journal'),
                onPressed: _busy ? null : _createJournal,
                icon: const Icon(Icons.folder_outlined),
                label: const Text('Create journal'),
              ),
              FilledButton.icon(
                key: const Key('data-demo-create-entry'),
                onPressed: _busy ? null : _createEntry,
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Create entry'),
              ),
              FilledButton.icon(
                key: const Key('data-demo-load-timeline'),
                onPressed: _busy ? null : _loadTimeline,
                icon: const Icon(Icons.view_timeline_outlined),
                label: const Text('Load timeline'),
              ),
              FilledButton.icon(
                key: const Key('data-demo-soft-delete'),
                onPressed: _busy ? null : _softDeleteFirstEntry,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Soft delete'),
              ),
              FilledButton.icon(
                key: const Key('data-demo-refresh'),
                onPressed: _busy ? null : _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(_status, key: const Key('data-demo-status')),
          const SizedBox(height: 16),
          Text('Timeline top ${_entries.length}'),
          const SizedBox(height: 8),
          for (final entry in _entries)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(entry.contentPlain),
              subtitle: Text(entry.entryDtUtc.toUtc().toIso8601String()),
            ),
          const SizedBox(height: 16),
          const Text('Recent events'),
          const SizedBox(height: 8),
          Text(
            _eventLines.isEmpty ? 'No events yet' : _eventLines.join('\n'),
            key: const Key('data-demo-event-log'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
