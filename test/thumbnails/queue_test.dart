// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/thumbnails/cancel_token.dart';
import 'package:dayz/thumbnails/priority_queue.dart';
import 'package:dayz/thumbnails/thumbnail_handle.dart';

void main() {
  group('CancelToken Tests', () {
    test('initial state and cancellation trigger', () async {
      final token = CancelToken();
      expect(token.isCancelled, isFalse);

      var triggered = false;
      token.whenCancelled.then((_) {
        triggered = true;
      });

      token.cancel();
      expect(token.isCancelled, isTrue);

      await token.whenCancelled;
      expect(triggered, isTrue);
    });
  });

  group('PriorityQueue Tests', () {
    test('priority sorting and FIFO order for same priority', () {
      final queue = PriorityQueue<String>();

      queue.add('low_1', ThumbnailPriority.low);
      queue.add('normal_1', ThumbnailPriority.normal);
      queue.add('low_2', ThumbnailPriority.low);
      queue.add('normal_2', ThumbnailPriority.normal);

      expect(queue.length, equals(4));

      expect(queue.pop(), equals('normal_1'));
      expect(queue.pop(), equals('normal_2'));
      expect(queue.pop(), equals('low_1'));
      expect(queue.pop(), equals('low_2'));
      expect(queue.pop(), isNull);
    });

    test('remove elements', () {
      final queue = PriorityQueue<String>();

      queue.add('item1', ThumbnailPriority.normal);
      queue.add('item2', ThumbnailPriority.low);
      queue.add('item3', ThumbnailPriority.normal);

      expect(queue.length, equals(3));

      queue.remove('item3');
      expect(queue.length, equals(2));

      expect(queue.pop(), equals('item1'));
      expect(queue.pop(), equals('item2'));
      expect(queue.pop(), isNull);
    });

    test('re-adding same element updates its priority/order', () {
      final queue = PriorityQueue<String>();

      queue.add('item1', ThumbnailPriority.low);
      queue.add('item2', ThumbnailPriority.normal);
      // 重新添加 item1 并改为 normal
      queue.add('item1', ThumbnailPriority.normal);

      expect(queue.length, equals(2));
      // 由于 item1 被重新添加，它现在的 sequence 会更新为新 sequence
      // item2 之前是 normal（先添加），而 item1 后来也是 normal（后添加）
      // 所以应该先 pop item2，再 pop item1
      expect(queue.pop(), equals('item2'));
      expect(queue.pop(), equals('item1'));
    });
  });
}
