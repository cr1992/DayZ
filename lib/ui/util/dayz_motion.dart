// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/widgets.dart';

import '../theme/dayz_tokens.g.dart';

/// Returns a motion duration that respects the platform reduce-motion setting.
///
/// Author: @Ray
Duration dayzMotionDuration(
  BuildContext context, [
  Duration base = DayzMotion.dur,
]) {
  return MediaQuery.of(context).disableAnimations ? Duration.zero : base;
}
