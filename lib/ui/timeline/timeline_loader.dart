// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';

class TimelineLoader extends StatelessWidget {
  const TimelineLoader({
    super.key,
    required this.isLoading,
    required this.reachedEnd,
  });

  static const Key loaderKey = ValueKey<String>('timeline-loader');

  final bool isLoading;
  final bool reachedEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = reachedEnd ? l10n.reachedOldest : l10n.loadingEarlier;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DayzSpacing.s4,
        DayzSpacing.s2,
        DayzSpacing.s4,
        DayzSpacing.s10,
      ),
      child: Row(
        key: loaderKey,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading && !reachedEnd) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: DayzSpacing.s2),
          ],
          Text(text),
        ],
      ),
    );
  }
}
