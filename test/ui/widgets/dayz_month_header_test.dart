// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/widgets/dayz_month_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';

/// Geometry of `.tl-month`: the calendar icon is 16px and hugs the trailing
/// edge (`margin-left: auto`) instead of trailing the meta text.
///
/// Author: @Ray
void main() {
  testWidgets('calendar icon is 16px at the trailing edge', (tester) async {
    const width = 390.0;
    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('en'),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: DayzMonthHeader(
              month: DateTime(2026, 5),
              entryCount: 3,
              locale: 'en_US',
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final header = tester.getRect(find.byType(DayzMonthHeader));
    final icon = tester.getRect(find.byKey(DayzMonthHeader.calendarIconKey));

    expect(icon.width, DayzMonthHeader.calendarIconSize);
    // `.tl-month { padding-right: var(--sp-4) }`
    expect((header.right - 16 - icon.right).abs(), lessThan(1));
    // Meta text must not start at the far right: it follows the month label.
    final meta = tester.getRect(find.textContaining('2026'));
    expect(meta.left, lessThan(header.left + 120));
  });
}
