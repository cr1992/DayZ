// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/block_types.dart';
import 'package:dayz/media/media_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_draft_coordinator.dart';
import 'fakes/fake_editor_doc_codec.dart';
import 'fakes/fake_media_store.dart';
import 'fakes/fake_repos.dart';

void main() {
  test(
    'editor fakes support codec, draft, media, and repository smoke paths',
    () async {
      final codec = FakeEditorDocCodec();
      final document = Document(
        root: pageNode(
          children: [
            paragraphNode(text: 'Hello editor'),
            Node(
              type: ImageBlockKeys.type,
              attributes: {
                ImageBlockKeys.url: EditorImageReference.urlForMediaId(
                  'media-1',
                ),
              },
            ),
          ],
        ),
      );

      final encoded = codec.encode(document);
      final decoded = codec.decode(encoded);

      expect(decoded.version, FakeEditorDocCodec.currentDocVersion);
      expect(decoded.document.toJson(), document.toJson());
      expect(codec.extractPlainText(document), contains('Hello editor'));
      expect(jsonDecode(encoded), contains('docVersion'));

      final drafts = FakeDraftCoordinator();
      drafts.onChanged(
        targetId: 'entry-1',
        draftJson: encoded,
        isNew: false,
        cursorPos: 12,
      );
      await drafts.forceFlush();

      expect(drafts.changes, hasLength(1));
      expect(drafts.changes.single.targetId, 'entry-1');
      expect(drafts.forceFlushCount, 1);

      final mediaRepo = FakeMediaRepo();
      final mediaStore = FakeMediaStore(mediaRepo: mediaRepo);
      final relPath = await mediaStore.put(
        bytes: Stream<List<int>>.value([1, 2, 3]),
        entryId: 'entry-1',
        kind: MediaKind.image,
        mime: 'image/png',
        fileSize: 3,
      );

      expect(relPath, 'media/media-1.bin');
      expect(await mediaStore.openReadBytes(relPath), [1, 2, 3]);
      expect(mediaRepo.addedMedia, hasLength(1));
      expect(mediaRepo.addedMedia.single.id, 'media-1');
      expect(mediaRepo.addedMedia.single.entryId, 'entry-1');

      final entryRepo = FakeEntryRepo();
      await entryRepo.save(
        id: 'entry-1',
        contentJson: encoded,
        contentPlain: codec.extractPlainText(document),
      );

      expect(entryRepo.savedEntries.single.id, 'entry-1');
      expect(
        entryRepo.savedEntries.single.contentPlain,
        contains('Hello editor'),
      );
    },
  );
}
