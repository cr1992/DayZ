// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// ignore_for_file: prefer_initializing_formals

import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';

import '../shell/dayz_sheet.dart';
import '../shell/dayz_toast.dart';
import 'reader_view_data.dart';

abstract interface class ReaderFeedback {
  void showToast(ReaderToastEvent event);

  Future<bool> confirmDelete(ReaderDeletePrompt prompt);

  Future<ReaderJournalRecord?> pickJournal(ReaderJournalPrompt prompt);

  void closeReader();
}

class ReaderToastAction {
  const ReaderToastAction({required this.label, required this.onPressed});

  final String label;
  final Future<void> Function() onPressed;
}

class ReaderToastEvent {
  const ReaderToastEvent({required this.text, required this.tone, this.action});

  final String text;
  final DayzToastTone tone;
  final ReaderToastAction? action;
}

class ReaderDeletePrompt {
  const ReaderDeletePrompt({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;
}

class ReaderJournalPrompt {
  const ReaderJournalPrompt({
    required this.journals,
    required this.currentJournalId,
  });

  final List<ReaderJournalRecord> journals;
  final String? currentJournalId;
}

enum ReaderActionMenuItemType {
  edit,
  share,
  moveToJournal,
  favorite,
  separator,
  delete,
}

class ReaderActionMenuItem {
  const ReaderActionMenuItem({
    required this.type,
    required this.label,
    this.tone = DayzSheetTone.defaultTone,
  });

  const ReaderActionMenuItem.separator()
    : type = ReaderActionMenuItemType.separator,
      label = '',
      tone = DayzSheetTone.defaultTone;

  final ReaderActionMenuItemType type;
  final String label;
  final DayzSheetTone tone;
}

/// Reader screen state and action orchestration.
///
/// Author: @Ray
class ReaderController extends ChangeNotifier {
  ReaderController({
    required ReaderViewData data,
    required ReaderRepository repository,
  }) : _data = data,
       _repository = repository,
       _favorite = data.favorite,
       _journalId = data.journalId;

  final ReaderViewData _data;
  final ReaderRepository _repository;

  bool _favorite;
  String? _journalId;
  bool _galleryExpanded = false;

  ReaderViewData get data => _data;
  String get entryId => _data.id;
  bool get favorite => _favorite;
  String? get journalId => _journalId;
  bool get galleryExpanded => _galleryExpanded;

  Future<void> toggleFavorite(
    AppLocalizations l10n,
    ReaderFeedback feedback,
  ) async {
    final previous = _favorite;
    final next = !previous;
    _favorite = next;
    notifyListeners();

    try {
      await _repository.updateFavorite(entryId, next);
      feedback.showToast(
        ReaderToastEvent(
          text: next
              ? l10n.readerToastFavoriteAdded
              : l10n.readerToastFavoriteRemoved,
          tone: next ? DayzToastTone.fav : DayzToastTone.info,
        ),
      );
    } catch (_) {
      _favorite = previous;
      notifyListeners();
      feedback.showToast(
        ReaderToastEvent(
          text: l10n.readerToastActionFailed,
          tone: DayzToastTone.danger,
        ),
      );
    }
  }

  Future<void> delete(AppLocalizations l10n, ReaderFeedback feedback) async {
    final confirmed = await feedback.confirmDelete(
      ReaderDeletePrompt(
        title: l10n.readerDeleteTitle,
        message: l10n.readerDeleteMessage,
        confirmLabel: l10n.readerDeleteConfirm,
      ),
    );
    if (!confirmed) {
      return;
    }

    try {
      await _repository.softDelete(entryId);
      feedback.showToast(
        ReaderToastEvent(
          text: l10n.readerToastDeleted,
          tone: DayzToastTone.danger,
          action: ReaderToastAction(
            label: l10n.toastUndo,
            onPressed: () => _restore(l10n, feedback),
          ),
        ),
      );
      feedback.closeReader();
    } catch (_) {
      feedback.showToast(
        ReaderToastEvent(
          text: l10n.readerToastActionFailed,
          tone: DayzToastTone.danger,
        ),
      );
    }
  }

  Future<void> moveToJournal(
    AppLocalizations l10n,
    ReaderFeedback feedback,
  ) async {
    final journals = await _repository.listJournals();
    final target = await feedback.pickJournal(
      ReaderJournalPrompt(journals: journals, currentJournalId: _journalId),
    );
    if (target == null || target.id == _journalId) {
      return;
    }

    final previous = _journalId;
    _journalId = target.id;
    notifyListeners();
    try {
      await _repository.updateJournal(entryId, target.id);
      feedback.showToast(
        ReaderToastEvent(
          text: l10n.readerToastMovedToJournal(target.name),
          tone: DayzToastTone.ok,
        ),
      );
    } catch (_) {
      _journalId = previous;
      notifyListeners();
      feedback.showToast(
        ReaderToastEvent(
          text: l10n.readerToastActionFailed,
          tone: DayzToastTone.danger,
        ),
      );
    }
  }

  void share(AppLocalizations l10n, ReaderFeedback feedback) {
    feedback.showToast(
      ReaderToastEvent(
        text: l10n.readerToastSharePending,
        tone: DayzToastTone.info,
      ),
    );
  }

  void toggleGalleryExpanded() {
    _galleryExpanded = !_galleryExpanded;
    notifyListeners();
  }

  List<ReaderActionMenuItem> actionMenuItems(AppLocalizations l10n) {
    return [
      ReaderActionMenuItem(
        type: ReaderActionMenuItemType.edit,
        label: l10n.readerActionEdit,
      ),
      ReaderActionMenuItem(
        type: ReaderActionMenuItemType.share,
        label: l10n.readerActionShare,
      ),
      ReaderActionMenuItem(
        type: ReaderActionMenuItemType.moveToJournal,
        label: l10n.readerActionMoveToJournal,
      ),
      ReaderActionMenuItem(
        type: ReaderActionMenuItemType.favorite,
        label: _favorite
            ? l10n.readerActionUnfavorite
            : l10n.readerActionFavorite,
        tone: DayzSheetTone.favorite,
      ),
      const ReaderActionMenuItem.separator(),
      ReaderActionMenuItem(
        type: ReaderActionMenuItemType.delete,
        label: l10n.readerActionDelete,
        tone: DayzSheetTone.danger,
      ),
    ];
  }

  Future<void> _restore(AppLocalizations l10n, ReaderFeedback feedback) async {
    try {
      await _repository.restore(entryId);
      feedback.showToast(
        ReaderToastEvent(
          text: l10n.readerToastRestored,
          tone: DayzToastTone.ok,
        ),
      );
    } catch (_) {
      feedback.showToast(
        ReaderToastEvent(
          text: l10n.readerToastActionFailed,
          tone: DayzToastTone.danger,
        ),
      );
    }
  }
}
