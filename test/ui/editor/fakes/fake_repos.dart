// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

class FakeSavedEntry {
  const FakeSavedEntry({
    required this.id,
    required this.contentJson,
    required this.contentPlain,
  });

  final String id;
  final String contentJson;
  final String contentPlain;
}

class FakeEntryRepo {
  final List<FakeSavedEntry> savedEntries = <FakeSavedEntry>[];

  Future<void> save({
    required String id,
    required String contentJson,
    required String contentPlain,
  }) async {
    savedEntries.add(
      FakeSavedEntry(
        id: id,
        contentJson: contentJson,
        contentPlain: contentPlain,
      ),
    );
  }
}

class FakeMediaMeta {
  const FakeMediaMeta({
    required this.id,
    required this.entryId,
    required this.kind,
    required this.relPath,
    required this.mime,
    this.width,
    this.height,
    this.durationMs,
    this.fileSize,
  });

  final String id;
  final String entryId;
  final String kind;
  final String relPath;
  final String mime;
  final int? width;
  final int? height;
  final int? durationMs;
  final int? fileSize;
}

class FakeMediaRepo {
  final List<FakeMediaMeta> addedMedia = <FakeMediaMeta>[];
  final List<String> softDeletedIds = <String>[];
  final List<String> hardDeletedIds = <String>[];

  Future<void> addMeta(
    String id,
    String entryId,
    String kind,
    String relPath, {
    required String mime,
    int? width,
    int? height,
    int? durationMs,
    int? fileSize,
  }) async {
    addedMedia.add(
      FakeMediaMeta(
        id: id,
        entryId: entryId,
        kind: kind,
        relPath: relPath,
        mime: mime,
        width: width,
        height: height,
        durationMs: durationMs,
        fileSize: fileSize,
      ),
    );
  }

  Future<void> softDelete(String id) async {
    softDeletedIds.add(id);
  }

  Future<void> hardDelete(String id) async {
    hardDeletedIds.add(id);
  }
}

class FakeJournalRepo {}

class FakeTagRepo {}

class FakeEditingSessionRepo {}
