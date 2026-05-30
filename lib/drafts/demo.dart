// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/repositories/editing_session_repo.dart';
import '../data/repositories/entry_repo.dart';
import '../data/repositories/journal_repo.dart';
import '../data/time_zone_triple.dart';
import 'draft_coordinator.dart';
import 'draft_recovery_status.dart';
import 'lifecycle_bridge.dart';

class DraftsDemo extends StatefulWidget {
  const DraftsDemo({
    super.key,
    this.database,
    this.coordinator,
    this.lifecycleBridge,
  });

  final AppDatabase? database;
  final DraftCoordinator? coordinator;
  final LifecycleBridge? lifecycleBridge;

  @override
  State<DraftsDemo> createState() => _DraftsDemoState();
}

class _DraftsDemoState extends State<DraftsDemo> {
  late final AppDatabase _db;
  late final EditingSessionRepo _editingSessionRepo;
  late final EntryRepo _entryRepo;
  late final JournalRepo _journalRepo;
  late final DraftCoordinator _coordinator;
  late final LifecycleBridge _lifecycleBridge;
  late final bool _ownsDatabase;
  late final bool _ownsCoordinator;
  late final TextEditingController _textController;
  Timer? _autoRefreshTimer;

  DraftRecoveryStatus _recoveryStatus = const DraftRecoveryStatus(
    hasResidual: false,
  );
  EditingSession? _session;
  DateTime? _lastSavedAt;
  String _status = 'Ready';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    initTimezoneData();
    _db = widget.database ?? AppDatabase(NativeDatabase.memory());
    _ownsDatabase = widget.database == null;
    _editingSessionRepo = EditingSessionRepo(_db);
    _entryRepo = EntryRepo(_db);
    _journalRepo = JournalRepo(_db);
    _coordinator =
        widget.coordinator ??
        DraftCoordinator(store: EditingSessionDraftStore(_editingSessionRepo));
    _ownsCoordinator = widget.coordinator == null;
    _lifecycleBridge =
        widget.lifecycleBridge ?? LifecycleBridge(coordinator: _coordinator);
    _textController = TextEditingController();
    _bootstrap();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _textController.dispose();
    if (_ownsCoordinator) {
      _coordinator.dispose();
    }
    if (_ownsDatabase) {
      _db.close();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final status = await _coordinator.startupCheck();
    final session = await _editingSessionRepo.current();
    if (!mounted) {
      return;
    }

    setState(() {
      _recoveryStatus = status;
      _session = session;
      _lastSavedAt = session?.updatedAt;
      if (session?.draftJson != null) {
        _textController.text = _plainFromDraftJson(session!.draftJson!);
      }
      _status = status.hasResidual ? 'Residual draft detected' : 'No draft';
    });
  }

  void _onTextChanged(String value) {
    final draftJson = _draftJsonForText(value);
    _coordinator.onChanged(
      targetId: null,
      draftJson: draftJson,
      isNew: true,
      cursorPos: _textController.selection.baseOffset,
    );
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        unawaited(_forceFlushAndRefresh(status: 'Auto saved'));
      }
    });
    setState(() {
      _status = 'Editing';
    });
  }

  Future<void> _simulatePaused() {
    return _run('Paused flush', () async {
      await _lifecycleBridge.handleLifecycleState(AppLifecycleState.paused);
      await _refreshSession(status: 'Paused flush saved');
    });
  }

  Future<void> _submitAndClear() {
    return _run('Submit', () async {
      final journal = await _ensureJournal();
      final text = _textController.text;
      await _entryRepo.create(
        journalId: journal.id,
        contentJson: _draftJsonForText(text),
        contentPlain: text,
        entryDtUtc: DateTime.now().toUtc(),
        entryTz: 'Asia/Shanghai',
      );
      await _coordinator.clear();
      await _refreshSession(status: 'Submitted and cleared');
    });
  }

  Future<void> _abandonWithoutClear() {
    return _run('Leave draft', () async {
      await _refreshSession(status: 'Left draft in editing_session');
    });
  }

  Future<void> _simulateRestart() {
    return _run('Simulate restart', () async {
      _textController.clear();
      setState(() {
        _recoveryStatus = const DraftRecoveryStatus(hasResidual: false);
        _session = null;
        _lastSavedAt = null;
      });

      final status = await _coordinator.startupCheck();
      final session = await _editingSessionRepo.current();
      if (!mounted) {
        return;
      }

      setState(() {
        _recoveryStatus = status;
        _session = session;
        _lastSavedAt = session?.updatedAt;
        if (session?.draftJson != null) {
          final text = _plainFromDraftJson(session!.draftJson!);
          _textController.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }
        _status = status.hasResidual
            ? 'Simulated restart: residual draft detected'
            : 'Simulated restart: no draft';
      });
    });
  }

  Future<void> _refreshSession({String? status}) async {
    final session = await _editingSessionRepo.current();
    if (!mounted) {
      return;
    }

    setState(() {
      _session = session;
      _lastSavedAt = session?.updatedAt;
      _recoveryStatus = DraftRecoveryStatus(
        hasResidual: session != null,
        targetId: session?.targetId,
        isNew: session?.isNew ?? false,
        lastUpdated: session?.updatedAt,
      );
      _status = status ?? (session == null ? 'No draft' : 'Draft present');
    });
  }

  Future<void> _forceFlushAndRefresh({required String status}) async {
    await _coordinator.forceFlush();
    await _refreshSession(status: status);
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

  Future<Journal> _ensureJournal() async {
    final journals = await _journalRepo.list();
    if (journals.isNotEmpty) {
      return journals.first;
    }
    return _journalRepo.create('Drafts demo journal', color: '#4D7CFE');
  }

  String _sessionText() {
    final session = _session;
    if (session == null) {
      return 'empty';
    }
    return [
      'targetId=${session.targetId ?? "new"}',
      'isNew=${session.isNew}',
      'cursor=${session.cursorPos ?? "-"}',
      'draft=${session.draftJson ?? ""}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final lastSavedText = _lastSavedAt == null
        ? 'No save yet'
        : _lastSavedAt!.toUtc().toIso8601String();

    return Scaffold(
      appBar: AppBar(title: const Text('Drafts demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _recoveryStatus.hasResidual
                ? 'Residual draft detected'
                : 'No residual draft',
            key: const Key('drafts-demo-recovery-status'),
          ),
          const SizedBox(height: 8),
          Text(_status, key: const Key('drafts-demo-status')),
          const SizedBox(height: 16),
          TextField(
            key: const Key('drafts-demo-editor'),
            controller: _textController,
            maxLines: 6,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Draft text',
            ),
            onChanged: _onTextChanged,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('drafts-demo-paused'),
                onPressed: _busy ? null : _simulatePaused,
                icon: const Icon(Icons.pause_circle_outline),
                label: const Text('Simulate paused'),
              ),
              FilledButton.icon(
                key: const Key('drafts-demo-submit-clear'),
                onPressed: _busy ? null : _submitAndClear,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Submit and clear'),
              ),
              OutlinedButton.icon(
                key: const Key('drafts-demo-leave-draft'),
                onPressed: _busy ? null : _abandonWithoutClear,
                icon: const Icon(Icons.logout),
                label: const Text('Leave draft'),
              ),
              OutlinedButton.icon(
                key: const Key('drafts-demo-simulate-restart'),
                onPressed: _busy ? null : _simulateRestart,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Simulate restart'),
              ),
              OutlinedButton.icon(
                key: const Key('drafts-demo-refresh'),
                onPressed: _busy ? null : () => _refreshSession(),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Last saved: $lastSavedText',
            key: const Key('drafts-demo-last-saved'),
          ),
          const SizedBox(height: 16),
          Text(
            _sessionText(),
            key: const Key('drafts-demo-session'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

String _draftJsonForText(String text) {
  return jsonEncode({
    'type': 'doc',
    'content': [
      {'text': text},
    ],
  });
}

String _plainFromDraftJson(String draftJson) {
  final decoded = jsonDecode(draftJson);
  if (decoded is! Map<String, Object?>) {
    return '';
  }
  final content = decoded['content'];
  if (content is! List || content.isEmpty) {
    return '';
  }
  final first = content.first;
  if (first is! Map) {
    return '';
  }
  return first['text']?.toString() ?? '';
}
