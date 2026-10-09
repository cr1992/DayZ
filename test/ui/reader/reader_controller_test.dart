// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/reader/reader_controller.dart';
import 'package:dayz/ui/reader/reader_view_data.dart';
import 'package:dayz/ui/shell/dayz_sheet.dart';
import 'package:dayz/ui/shell/dayz_toast.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';
import 'fakes/fake_repos.dart';

void main() {
  test('toggleFavorite updates repository and rolls back on failure', () async {
    final repo = FakeReaderRepository();
    final feedback = FakeReaderFeedback();
    final controller = ReaderController(
      data: _readerData(favorite: false),
      repository: repo,
    );

    await controller.toggleFavorite(testL10n, feedback);

    expect(controller.favorite, isTrue);
    expect(repo.favoriteUpdates, [(id: 'entry-1', isFavorite: true)]);
    expect(feedback.toasts.single.text, testL10n.readerToastFavoriteAdded);
    expect(feedback.toasts.single.tone, DayzToastTone.fav);

    repo.favoriteFailure = StateError('write failed');
    await controller.toggleFavorite(testL10n, feedback);

    expect(controller.favorite, isTrue);
    expect(repo.favoriteUpdates.last, (id: 'entry-1', isFavorite: false));
    expect(feedback.toasts.last.text, testL10n.readerToastActionFailed);
    expect(feedback.toasts.last.tone, DayzToastTone.danger);
  });

  test('delete soft deletes and exposes undo restore action', () async {
    final repo = FakeReaderRepository();
    final feedback = FakeReaderFeedback()..deleteConfirmed = true;
    final controller = ReaderController(
      data: _readerData(favorite: false),
      repository: repo,
    );

    await controller.delete(testL10n, feedback);

    expect(feedback.deletePrompts.single.title, testL10n.readerDeleteTitle);
    expect(repo.softDeleteCalls, ['entry-1']);
    expect(feedback.closedReaderCount, 1);
    expect(feedback.toasts.single.text, testL10n.readerToastDeleted);
    expect(feedback.toasts.single.tone, DayzToastTone.danger);

    final undo = feedback.toasts.single.action!;
    expect(undo.label, testL10n.toastUndo);
    await undo.onPressed();

    expect(repo.restoreCalls, ['entry-1']);
    expect(feedback.toasts.last.text, testL10n.readerToastRestored);
    expect(feedback.toasts.last.tone, DayzToastTone.ok);
  });

  test('delete failure keeps the reader open', () async {
    final repo = FakeReaderRepository()
      ..deleteFailure = StateError('delete failed');
    final feedback = FakeReaderFeedback()..deleteConfirmed = true;
    final controller = ReaderController(
      data: _readerData(favorite: false),
      repository: repo,
    );

    await controller.delete(testL10n, feedback);

    expect(repo.softDeleteCalls, ['entry-1']);
    expect(feedback.closedReaderCount, 0);
    expect(feedback.toasts.single.text, testL10n.readerToastActionFailed);
  });

  test(
    'moveToJournal updates journal id and shows target journal toast',
    () async {
      final target = fakeReaderJournalRecord(
        id: 'journal-2',
        name: '旅行',
        entryCount: 12,
      );
      final repo = FakeReaderRepository(
        journals: [
          fakeReaderJournalRecord(id: 'journal-1', name: '日常'),
          target,
        ],
      );
      final feedback = FakeReaderFeedback()..pickedJournal = target;
      final controller = ReaderController(
        data: _readerData(journalId: 'journal-1'),
        repository: repo,
      );

      await controller.moveToJournal(testL10n, feedback);

      expect(controller.journalId, 'journal-2');
      expect(repo.journalUpdates, [(id: 'entry-1', journalId: 'journal-2')]);
      expect(feedback.journalPrompts.single.currentJournalId, 'journal-1');
      expect(
        feedback.toasts.single.text,
        testL10n.readerToastMovedToJournal('旅行'),
      );
    },
  );

  test('toggleGalleryExpanded flips state and notifies listeners', () {
    final controller = ReaderController(
      data: _readerData(favorite: false),
      repository: FakeReaderRepository(),
    );
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    controller.toggleGalleryExpanded();

    expect(controller.galleryExpanded, isTrue);
    expect(notifications, 1);
  });

  test('action menu items keep reader prototype order and danger delete', () {
    final controller = ReaderController(
      data: _readerData(favorite: false),
      repository: FakeReaderRepository(),
    );

    final items = controller.actionMenuItems(testL10n);

    expect(items.map((item) => item.type), [
      ReaderActionMenuItemType.edit,
      ReaderActionMenuItemType.share,
      ReaderActionMenuItemType.moveToJournal,
      ReaderActionMenuItemType.favorite,
      ReaderActionMenuItemType.separator,
      ReaderActionMenuItemType.delete,
    ]);
    expect(items[3].label, testL10n.readerActionFavorite);
    expect(items.last.tone, DayzSheetTone.danger);
  });
}

ReaderViewData _readerData({bool favorite = true, String? journalId}) {
  return ReaderViewData(
    id: 'entry-1',
    dateTimeLocal: DateTime(2026, 5, 31, 21),
    title: '一页日记',
    bodyParagraphs: const ['一页日记'],
    journalId: journalId,
    favorite: favorite,
  );
}

class FakeReaderFeedback implements ReaderFeedback {
  final List<ReaderDeletePrompt> deletePrompts = <ReaderDeletePrompt>[];
  final List<ReaderJournalPrompt> journalPrompts = <ReaderJournalPrompt>[];
  final List<ReaderToastEvent> toasts = <ReaderToastEvent>[];
  bool deleteConfirmed = false;
  ReaderJournalRecord? pickedJournal;
  int closedReaderCount = 0;

  @override
  Future<bool> confirmDelete(ReaderDeletePrompt prompt) async {
    deletePrompts.add(prompt);
    return deleteConfirmed;
  }

  @override
  void closeReader() {
    closedReaderCount += 1;
  }

  @override
  Future<ReaderJournalRecord?> pickJournal(ReaderJournalPrompt prompt) async {
    journalPrompts.add(prompt);
    return pickedJournal;
  }

  @override
  void showToast(ReaderToastEvent event) {
    toasts.add(event);
  }
}
