// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/drafts/debouncer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debouncer', () {
    testWidgets('连续 fire 只触发最后一次 payload', (tester) async {
      final calls = <String>[];
      final debouncer = Debouncer<String>(
        duration: const Duration(milliseconds: 1500),
        onFire: calls.add,
      );

      debouncer.fire('first');
      await tester.pump(const Duration(milliseconds: 500));
      debouncer.fire('second');
      await tester.pump(const Duration(milliseconds: 500));
      debouncer.fire('third');

      await tester.pump(const Duration(milliseconds: 1499));
      expect(calls, isEmpty);
      expect(debouncer.hasPending, isTrue);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(calls, ['third']);
      expect(debouncer.hasPending, isFalse);

      debouncer.dispose();
    });

    testWidgets('flushNow 立即触发并清空待处理 payload', (tester) async {
      final calls = <int>[];
      final debouncer = Debouncer<int>(
        duration: const Duration(milliseconds: 1500),
        onFire: calls.add,
      );

      debouncer.fire(42);
      await tester.pump(const Duration(milliseconds: 300));

      await debouncer.flushNow();

      expect(calls, [42]);
      expect(debouncer.hasPending, isFalse);

      await tester.pump(const Duration(milliseconds: 1500));
      expect(calls, [42]);

      debouncer.dispose();
    });

    testWidgets('cancel 清空待处理 payload 且不触发回调', (tester) async {
      final calls = <String>[];
      final debouncer = Debouncer<String>(
        duration: const Duration(milliseconds: 1500),
        onFire: calls.add,
      );

      debouncer.fire('draft');
      expect(debouncer.hasPending, isTrue);

      debouncer.cancel();
      expect(debouncer.hasPending, isFalse);

      await tester.pump(const Duration(milliseconds: 1500));
      expect(calls, isEmpty);
    });

    testWidgets('flushNow 等待异步回调完成', (tester) async {
      var completed = false;
      final debouncer = Debouncer<String>(
        duration: const Duration(milliseconds: 1500),
        onFire: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          completed = true;
        },
      );

      debouncer.fire('draft');
      final flush = debouncer.flushNow();

      await tester.pump();
      expect(completed, isFalse);

      await tester.pump(const Duration(milliseconds: 20));
      await flush;
      expect(completed, isTrue);
    });

    test('负 duration 拒绝构造', () {
      expect(
        () => Debouncer<void>(
          duration: const Duration(milliseconds: -1),
          onFire: (_) {},
        ),
        throwsArgumentError,
      );
    });
  });
}
