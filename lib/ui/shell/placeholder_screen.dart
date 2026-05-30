// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:dayz/ui/strings/app_strings.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';

/// A placeholder screen used during UI routing setup.
///
/// Author: @Ray
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final bool showAppBar;

  const PlaceholderScreen({
    required this.title,
    this.showAppBar = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final textTheme = context.dayzText;

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
                  AppStrings.shellPlaceholderSuffix,
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
