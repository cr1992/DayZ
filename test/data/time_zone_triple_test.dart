// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/data/time_zone_triple.dart';

void main() {
  setUpAll(initTimezoneData);

  test('computes local date across day boundary', () {
    final triple = TimeZoneTriple.compute(
      DateTime.utc(2026, 5, 30, 22),
      'Asia/Shanghai',
    );

    expect(triple, (year: 2026, month: 5, day: 31));
  });

  test('accepts UTC alias', () {
    final triple = TimeZoneTriple.compute(DateTime.utc(2026, 5, 30, 22), 'UTC');

    expect(triple, (year: 2026, month: 5, day: 30));
  });

  test('throws TZException for invalid time zone name', () {
    expect(
      () => TimeZoneTriple.compute(DateTime.utc(2026, 5, 30, 22), 'Not/AZone'),
      throwsA(isA<TZException>()),
    );
  });
}
