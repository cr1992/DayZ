// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/data/ids.dart';

void main() {
  test('UUID v7 generation basic checks', () {
    final id = Ids.next();
    // 36 characters (32 hex + 4 hyphens)
    expect(id.length, equals(36));
    // Verify format: xxxxxxxx-xxxx-7xxx-xxxx-xxxxxxxxxxxx (v7 has '7' at version nibble)
    expect(id[14], equals('7'));
  });

  test('UUID v7 time ordering within same millisecond', () {
    // Generate many UUIDs sequentially in a tight loop (likely within same ms)
    final ids = List.generate(100, (_) => Ids.next());

    for (int i = 0; i < ids.length - 1; i++) {
      expect(
        ids[i].compareTo(ids[i + 1]),
        lessThan(0),
        reason:
            'UUID ${ids[i]} should be alphabetically smaller than ${ids[i + 1]}',
      );
    }
  });

  test('10000 UUID v7 generations have no duplicates', () {
    final idsSet = <String>{};
    const count = 10000;

    for (int i = 0; i < count; i++) {
      final id = Ids.next();
      idsSet.add(id);
    }

    expect(idsSet.length, equals(count));
  });
}
