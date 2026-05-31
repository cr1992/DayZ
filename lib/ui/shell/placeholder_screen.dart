// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';

typedef PlaceholderTitleBuilder = String Function(AppLocalizations l10n);

/// A placeholder screen used during UI routing setup.
///
/// Author: @Ray
class PlaceholderScreen extends StatelessWidget {
  final PlaceholderTitleBuilder titleBuilder;
  final bool showAppBar;

  const PlaceholderScreen({
    required this.titleBuilder,
    this.showAppBar = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final textTheme = context.dayzText;
    final l10n = AppLocalizations.of(context);
    final title = titleBuilder(l10n);

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: BackButton(color: colors.ink),
              title: Text(
                title,
                style: textTheme.h3.copyWith(color: colors.ink),
              ),
              centerTitle: true,
            )
          : null,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DayzSpacing.s4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!showAppBar)
                  Text(
                    title,
                    style: textTheme.h1.copyWith(color: colors.ink),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: DayzSpacing.s2),
                Text(
                  l10n.shellPlaceholderSuffix,
                  style: textTheme.body.copyWith(color: colors.ink2),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
