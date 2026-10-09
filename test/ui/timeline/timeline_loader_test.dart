// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/timeline/timeline_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../l10n/localized_test_app.dart';

/// Style parameters of `.tl-loader` (timeline.css): 12.5px muted caption,
/// `ink-4` once the oldest entry is reached, 15px ring while loading.
///
/// Author: @Ray
void main() {
  Text loaderText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(TimelineLoader.textKey));

  testWidgets('reached-end state is a 12.5px ink-4 caption', (tester) async {
    await tester.pumpWidget(
      localizedTestApp(
        child: const TimelineLoader(isLoading: false, reachedEnd: true),
      ),
    );

    final style = loaderText(tester).style!;
    expect(style.fontSize, TimelineLoader.fontSize);
    expect(style.color, DayzColors.purpleLight.ink4);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('loading state is ink-3 with a 15px ring', (tester) async {
    await tester.pumpWidget(
      localizedTestApp(
        child: const TimelineLoader(isLoading: true, reachedEnd: false),
      ),
    );

    final style = loaderText(tester).style!;
    expect(style.fontSize, TimelineLoader.fontSize);
    expect(style.color, DayzColors.purpleLight.ink3);
    final ring = tester.getSize(find.byType(CircularProgressIndicator));
    expect(ring, const Size.square(TimelineLoader.spinnerSize));
  });
}
