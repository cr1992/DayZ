// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/media/media_store.dart';

import 'fake_repos.dart';

class FakeMediaStore {
  FakeMediaStore({required this.mediaRepo, String? nextMediaId})
    : _nextMediaId = nextMediaId ?? 'media-1';

  final FakeMediaRepo mediaRepo;
  final Map<String, List<int>> storedBytes = <String, List<int>>{};
  final List<FakeMediaStorePutCall> putCalls = <FakeMediaStorePutCall>[];
  String _nextMediaId;

  Future<String> put({
    required Stream<List<int>> bytes,
    required String entryId,
    required MediaKind kind,
    required String mime,
    int? width,
    int? height,
    int? durationMs,
    int? fileSize,
  }) async {
    final id = _nextMediaId;
    final relPath = 'media/$id.bin';
    final collected = <int>[];
    await for (final chunk in bytes) {
      collected.addAll(chunk);
    }
    storedBytes[relPath] = List<int>.unmodifiable(collected);
    putCalls.add(
      FakeMediaStorePutCall(
        id: id,
        entryId: entryId,
        kind: kind,
        mime: mime,
        relPath: relPath,
        fileSize: fileSize,
      ),
    );
    await mediaRepo.addMeta(
      id,
      entryId,
      kind.name,
      relPath,
      mime: mime,
      width: width,
      height: height,
      durationMs: durationMs,
      fileSize: fileSize,
    );
    _nextMediaId = _nextSequentialId(id);
    return relPath;
  }

  Stream<List<int>> openRead(String relPath) async* {
    final bytes = storedBytes[relPath];
    if (bytes == null) {
      throw StateError('No fake media stored at $relPath');
    }
    yield bytes;
  }

  Future<List<int>> openReadBytes(String relPath) async {
    final output = <int>[];
    await for (final chunk in openRead(relPath)) {
      output.addAll(chunk);
    }
    return output;
  }

  static String _nextSequentialId(String id) {
    final match = RegExp(r'^(.*?)(\d+)$').firstMatch(id);
    if (match == null) {
      return '${id}_next';
    }
    final prefix = match.group(1)!;
    final number = int.parse(match.group(2)!);
    return '$prefix${number + 1}';
  }
}

class FakeMediaStorePutCall {
  const FakeMediaStorePutCall({
    required this.id,
    required this.entryId,
    required this.kind,
    required this.mime,
    required this.relPath,
    required this.fileSize,
  });

  final String id;
  final String entryId;
  final MediaKind kind;
  final String mime;
  final String relPath;
  final int? fileSize;
}
