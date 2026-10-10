// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/components.dart';
import 'package:dayz/ui/widgets/dayz_icon.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';

/// ui-kit-patch T1：`DayzIcons.chevronLeftPath` 渲染口径。
///
/// Author: @Ray
void main() {
  testWidgets('chevronLeftPath renders as the screen-source back arrow', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        child: Center(child: DayzIcon.path(DayzIcons.chevronLeftPath)),
      ),
    );

    final icon = tester.widget<DayzIcon>(find.byType(DayzIcon));
    expect(icon.markup, '<path d="m15 5-7 7 7 7"/>');
    expect(
      find.descendant(
        of: find.byType(DayzIcon),
        matching: find.byType(SvgPicture),
      ),
      findsOneWidget,
    );
  });
}
