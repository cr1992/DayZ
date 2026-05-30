// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:convert';

import '../data/repositories/editing_session_repo.dart';
import '../observability/app_logger.dart';
import 'debouncer.dart';
import 'draft_recovery_status.dart';

class DraftChange {
  const DraftChange({
    required this.targetId,
    required this.draftJson,
    required this.isNew,
    required this.cursorPos,
  });

  final String? targetId;
  final String draftJson;
  final bool isNew;
  final int? cursorPos;
}

class DraftSessionSnapshot {
  const DraftSessionSnapshot({
    required this.targetId,
    required this.draftJson,
    required this.isNew,
    required this.cursorPos,
    required this.lastUpdated,
  });

  final String? targetId;
  final String? draftJson;
  final bool isNew;
  final int? cursorPos;
  final DateTime lastUpdated;
}

abstract class DraftSessionStore {
  Future<DraftSessionSnapshot?> current();

  Future<void> upsert(DraftChange change);

  Future<void> clear();
}

class EditingSessionDraftStore implements DraftSessionStore {
  const EditingSessionDraftStore(this._repo);

  final EditingSessionRepo _repo;

  @override
  Future<DraftSessionSnapshot?> current() async {
    final session = await _repo.current();
    if (session == null) {
      return null;
    }

    return DraftSessionSnapshot(
      targetId: session.targetId,
      draftJson: session.draftJson,
      isNew: session.isNew,
      cursorPos: session.cursorPos,
      lastUpdated: session.updatedAt,
    );
  }

  @override
  Future<void> upsert(DraftChange change) async {
    await _repo.upsert(
      targetId: change.targetId,
      draftJson: change.draftJson,
      isNew: change.isNew,
      cursorPos: change.cursorPos,
    );
  }

  @override
  Future<void> clear() {
    return _repo.clear();
  }
}

class DraftSaveError {
  const DraftSaveError({
    required this.change,
    required this.error,
    required this.stackTrace,
    required this.attempts,
    required this.occurredAt,
  });

  final DraftChange change;
  final Object error;
  final StackTrace stackTrace;
  final int attempts;
  final DateTime occurredAt;
}

class DraftCoordinator {
  DraftCoordinator({
    DraftSessionStore? store,
    Duration debounceDuration = const Duration(milliseconds: 1500),
    List<Duration> retryDelays = const <Duration>[
      Duration(milliseconds: 100),
      Duration(milliseconds: 300),
      Duration(milliseconds: 900),
    ],
  }) : _store = store ?? _MemoryDraftSessionStore(),
       _retryDelays = List<Duration>.unmodifiable(retryDelays) {
    if (_retryDelays.length > 3) {
      throw ArgumentError.value(
        retryDelays,
        'retryDelays',
        'Must contain at most 3 retry delays.',
      );
    }
    if (_retryDelays.any((delay) => delay.isNegative)) {
      throw ArgumentError.value(
        retryDelays,
        'retryDelays',
        'Must not contain negative durations.',
      );
    }

    _debouncer = Debouncer<DraftChange>(
      duration: debounceDuration,
      onFire: _enqueueSave,
    );
  }

  final DraftSessionStore _store;
  final List<Duration> _retryDelays;
  late final Debouncer<DraftChange> _debouncer;

  Future<void> _queueTail = Future<void>.value();
  DraftChange? _lastChange;
  _SavedDraftSignature? _lastSavedSignature;
  final List<DraftSaveError> _saveErrors = <DraftSaveError>[];

  DraftChange? get lastChange => _lastChange;

  List<DraftSaveError> get saveErrors =>
      List<DraftSaveError>.unmodifiable(_saveErrors);

  DraftSaveError? get lastSaveError =>
      _saveErrors.isEmpty ? null : _saveErrors.last;

  void onChanged({
    required String? targetId,
    required String draftJson,
    required bool isNew,
    int? cursorPos,
  }) {
    final change = DraftChange(
      targetId: targetId,
      draftJson: draftJson,
      isNew: isNew,
      cursorPos: cursorPos,
    );

    final previousChange = _lastChange;
    final isSwitchingTarget =
        _debouncer.hasPending &&
        previousChange != null &&
        previousChange.targetId != change.targetId;

    if (isSwitchingTarget) {
      unawaited(_flushDebouncerSafely());
    }

    _lastChange = change;
    _debouncer.fire(change);
  }

  Future<void> forceFlush() async {
    await _debouncer.flushNow();
    await _queueTail;
  }

  Future<void> clear() async {
    AppLogger.instance.logInfo('draft.coordinator.clear');
    _debouncer.cancel();
    await _enqueue(() async {
      await _store.clear();
      _lastSavedSignature = null;
    });
    _lastChange = null;
  }

  Future<DraftRecoveryStatus> startupCheck() async {
    final snapshot = await _store.current();
    AppLogger.instance.logInfo('draft.coordinator.startupCheck', fields: {
      'hasResidual': snapshot != null,
      'targetId': snapshot?.targetId,
    });
    if (snapshot == null) {
      _lastSavedSignature = null;
      return const DraftRecoveryStatus(hasResidual: false);
    }

    final draftJson = snapshot.draftJson;
    _lastSavedSignature = draftJson == null
        ? null
        : _SavedDraftSignature(
            targetId: snapshot.targetId,
            isNew: snapshot.isNew,
            draftHash: _sha256Hex(utf8.encode(draftJson)),
          );

    return DraftRecoveryStatus(
      hasResidual: true,
      targetId: snapshot.targetId,
      isNew: snapshot.isNew,
      lastUpdated: snapshot.lastUpdated,
    );
  }

  void dispose() {
    _debouncer.dispose();
  }

  Future<void> _flushDebouncerSafely() async {
    try {
      await _debouncer.flushNow();
    } catch (error, stackTrace) {
      _recordSaveError(_lastChange, error, stackTrace, attempts: 1);
    }
  }

  Future<void> _enqueueSave(DraftChange change) {
    return _enqueue(() => _saveWithRetry(change));
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final run = _queueTail.then((_) => action());
    _queueTail = run.catchError((Object _) {});
    return run;
  }

  Future<void> _saveWithRetry(DraftChange change) async {
    final draftHash = _sha256Hex(utf8.encode(change.draftJson));
    final nextSignature = _SavedDraftSignature(
      targetId: change.targetId,
      isNew: change.isNew,
      draftHash: draftHash,
    );

    if (_lastSavedSignature == nextSignature) {
      AppLogger.instance.logInfo('draft.coordinator.save.skipped', fields: {
        'targetId': change.targetId,
        'isNew': change.isNew,
      });
      return;
    }

    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 0; attempt <= _retryDelays.length; attempt += 1) {
      try {
        AppLogger.instance.logInfo('draft.coordinator.save.start', fields: {
          'targetId': change.targetId,
          'isNew': change.isNew,
          'attempt': attempt,
        });
        await _store.upsert(change);
        _lastSavedSignature = nextSignature;
        AppLogger.instance.logInfo('draft.coordinator.save.success', fields: {
          'targetId': change.targetId,
          'isNew': change.isNew,
          'attempt': attempt,
        });
        return;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;

        AppLogger.instance.logWarning('draft.coordinator.save.retry', fields: {
          'targetId': change.targetId,
          'isNew': change.isNew,
          'attempt': attempt,
          'error': error.toString(),
        });

        if (attempt == _retryDelays.length) {
          break;
        }

        await Future<void>.delayed(_retryDelays[attempt]);
      }
    }

    _recordSaveError(
      change,
      lastError ?? StateError('Draft save failed.'),
      lastStackTrace ?? StackTrace.current,
      attempts: _retryDelays.length + 1,
    );
  }

  void _recordSaveError(
    DraftChange? change,
    Object error,
    StackTrace stackTrace, {
    required int attempts,
  }) {
    if (change == null) {
      return;
    }

    AppLogger.instance.logSevere('draft.coordinator.save.failed', fields: {
      'targetId': change.targetId,
      'isNew': change.isNew,
      'attempts': attempts,
      'error': error.toString(),
    });

    _saveErrors.add(
      DraftSaveError(
        change: change,
        error: error,
        stackTrace: stackTrace,
        attempts: attempts,
        occurredAt: DateTime.now().toUtc(),
      ),
    );
  }
}

class _MemoryDraftSessionStore implements DraftSessionStore {
  DraftSessionSnapshot? _snapshot;

  @override
  Future<DraftSessionSnapshot?> current() async {
    return _snapshot;
  }

  @override
  Future<void> upsert(DraftChange change) async {
    _snapshot = DraftSessionSnapshot(
      targetId: change.targetId,
      draftJson: change.draftJson,
      isNew: change.isNew,
      cursorPos: change.cursorPos,
      lastUpdated: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> clear() async {
    _snapshot = null;
  }
}

class _SavedDraftSignature {
  const _SavedDraftSignature({
    required this.targetId,
    required this.isNew,
    required this.draftHash,
  });

  final String? targetId;
  final bool isNew;
  final String draftHash;

  @override
  bool operator ==(Object other) {
    return other is _SavedDraftSignature &&
        other.targetId == targetId &&
        other.isNew == isNew &&
        other.draftHash == draftHash;
  }

  @override
  int get hashCode => Object.hash(targetId, isNew, draftHash);
}

String _sha256Hex(List<int> data) {
  const initialHash = <int>[
    0x6a09e667,
    0xbb67ae85,
    0x3c6ef372,
    0xa54ff53a,
    0x510e527f,
    0x9b05688c,
    0x1f83d9ab,
    0x5be0cd19,
  ];
  const roundConstants = <int>[
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2,
  ];

  final bytes = <int>[...data];
  final bitLength = bytes.length * 8;
  bytes.add(0x80);
  while ((bytes.length % 64) != 56) {
    bytes.add(0);
  }
  for (var shift = 56; shift >= 0; shift -= 8) {
    bytes.add((bitLength >> shift) & 0xff);
  }

  final hash = List<int>.of(initialHash);
  final words = List<int>.filled(64, 0);

  for (var offset = 0; offset < bytes.length; offset += 64) {
    for (var i = 0; i < 16; i += 1) {
      final index = offset + i * 4;
      words[i] =
          (bytes[index] << 24) |
          (bytes[index + 1] << 16) |
          (bytes[index + 2] << 8) |
          bytes[index + 3];
    }
    for (var i = 16; i < 64; i += 1) {
      final s0 =
          _rotateRight(words[i - 15], 7) ^
          _rotateRight(words[i - 15], 18) ^
          (words[i - 15] >> 3);
      final s1 =
          _rotateRight(words[i - 2], 17) ^
          _rotateRight(words[i - 2], 19) ^
          (words[i - 2] >> 10);
      words[i] = _uint32(words[i - 16] + s0 + words[i - 7] + s1);
    }

    var a = hash[0];
    var b = hash[1];
    var c = hash[2];
    var d = hash[3];
    var e = hash[4];
    var f = hash[5];
    var g = hash[6];
    var h = hash[7];

    for (var i = 0; i < 64; i += 1) {
      final sum1 =
          _rotateRight(e, 6) ^ _rotateRight(e, 11) ^ _rotateRight(e, 25);
      final ch = (e & f) ^ ((~e) & g);
      final temp1 = _uint32(h + sum1 + ch + roundConstants[i] + words[i]);
      final sum0 =
          _rotateRight(a, 2) ^ _rotateRight(a, 13) ^ _rotateRight(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = _uint32(sum0 + maj);

      h = g;
      g = f;
      f = e;
      e = _uint32(d + temp1);
      d = c;
      c = b;
      b = a;
      a = _uint32(temp1 + temp2);
    }

    hash[0] = _uint32(hash[0] + a);
    hash[1] = _uint32(hash[1] + b);
    hash[2] = _uint32(hash[2] + c);
    hash[3] = _uint32(hash[3] + d);
    hash[4] = _uint32(hash[4] + e);
    hash[5] = _uint32(hash[5] + f);
    hash[6] = _uint32(hash[6] + g);
    hash[7] = _uint32(hash[7] + h);
  }

  return hash.map((part) => part.toRadixString(16).padLeft(8, '0')).join();
}

int _rotateRight(int value, int shift) {
  return _uint32((value >> shift) | (value << (32 - shift)));
}

int _uint32(int value) {
  return value & 0xffffffff;
}
