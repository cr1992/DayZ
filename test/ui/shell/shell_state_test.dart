// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/ui/shell/shell_drawer.dart';
import 'package:dayz/ui/shell/shell_state.dart';

void main() {
  test('default properties', () {
    final state = ShellState();
    expect(state.currentJournalId, isNull);
    expect(state.journals, isEmpty);
  });

  test('selectJournal updates currentJournalId and notifies listeners', () {
    final state = ShellState();
    var notifyCount = 0;
    state.addListener(() => notifyCount++);

    state.selectJournal('j1');
    expect(state.currentJournalId, 'j1');
    expect(notifyCount, 1);

    // Re-selecting same journal should not notify
    state.selectJournal('j1');
    expect(notifyCount, 1);
  });

  test('setJournals updates list and notifies listeners', () {
    final state = ShellState();
    var notifyCount = 0;
    state.addListener(() => notifyCount++);

    final list = [
      const JournalSummary(id: 'j1', name: 'Work', count: 1),
    ];

    state.setJournals(list);
    expect(state.journals.length, 1);
    expect(state.journals.first.id, 'j1');
    expect(notifyCount, 1);
  });

  test('addJournal appends item and notifies listeners', () {
    final state = ShellState(initialJournals: [
      const JournalSummary(id: 'j1', name: 'Work', count: 1),
    ]);
    var notifyCount = 0;
    state.addListener(() => notifyCount++);

    state.addJournal(const JournalSummary(id: 'j2', name: 'Personal', count: 0));
    expect(state.journals.length, 2);
    expect(state.journals[1].id, 'j2');
    expect(notifyCount, 1);
  });
}
