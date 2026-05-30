// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:dayz/ui/util/dayz_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for reduce-motion duration gating.
///
/// Author: @Ray
void main() {
  testWidgets('returns zero when disableAnimations is true', (tester) async {
    late Duration actual;

    await tester.pumpWidget(
      MaterialApp(
        theme: DayzThemes.purpleLight,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              actual = dayzMotionDuration(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(actual, Duration.zero);
  });

  testWidgets('returns base duration when animations are enabled', (
    tester,
  ) async {
    const base = Duration(milliseconds: 480);
    late Duration actualBase;
    late Duration actualDefault;

    await tester.pumpWidget(
      MaterialApp(
        theme: DayzThemes.purpleLight,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Builder(
            builder: (context) {
              actualBase = dayzMotionDuration(context, base);
              actualDefault = dayzMotionDuration(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(actualBase, base);
    expect(actualDefault, DayzMotion.dur);
  });
}
