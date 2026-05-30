// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:dayz/ui/shell/shell_drawer.dart';

/// Active navigation and selected journal state of the app shell.
///
/// Author: @Ray
class ShellState extends ChangeNotifier {
  List<JournalSummary> _journals = const [];
  String? _currentJournalId;

  ShellState({
    List<JournalSummary> initialJournals = const [],
    String? initialJournalId,
  })  : _journals = initialJournals,
        _currentJournalId = initialJournalId;

  /// The list of journals shown in the drawer.
  List<JournalSummary> get journals => _journals;

  /// The active journal ID selection. Null represents 'All Journals'.
  String? get currentJournalId => _currentJournalId;

  /// Switch the active journal selection and notify listeners.
  void selectJournal(String? id) {
    if (_currentJournalId == id) return;
    _currentJournalId = id;
    notifyListeners();
  }

  /// Update the journals list and notify listeners.
  void setJournals(List<JournalSummary> list) {
    _journals = List.unmodifiable(list);
    notifyListeners();
  }

  /// Add a single journal to the memory state and notify listeners.
  void addJournal(JournalSummary journal) {
    final newList = List<JournalSummary>.from(_journals)..add(journal);
    _journals = List.unmodifiable(newList);
    notifyListeners();
  }
}
