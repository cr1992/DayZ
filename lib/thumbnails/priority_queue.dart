// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'thumbnail_handle.dart';

class PriorityQueueEntry<T> {
  final T value;
  final ThumbnailPriority priority;
  final int sequence;

  PriorityQueueEntry(this.value, this.priority, this.sequence);
}

class PriorityQueue<T> {
  final List<PriorityQueueEntry<T>> _entries = [];
  int _sequenceCounter = 0;

  int get length => _entries.length;

  void add(T element, ThumbnailPriority priority) {
    // 移除已有的同值元素
    remove(element);
    _entries.add(PriorityQueueEntry(element, priority, _sequenceCounter++));
    // 排序：优先按 priority 的 index 升序（normal=0, low=1），相同 priority 则按 sequence 升序
    _entries.sort((a, b) {
      if (a.priority != b.priority) {
        return a.priority.index.compareTo(b.priority.index);
      }
      return a.sequence.compareTo(b.sequence);
    });
  }

  T? pop() {
    if (_entries.isEmpty) return null;
    return _entries.removeAt(0).value;
  }

  void remove(T element) {
    _entries.removeWhere((entry) => entry.value == element);
  }
}
