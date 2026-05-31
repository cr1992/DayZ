// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';

typedef ReaderBodyBuilder =
    Widget Function(BuildContext context, List<String> paragraphs);

/// Read-only diary body rendered from plain text paragraphs.
///
/// Author: @Ray
class ReaderBody extends StatelessWidget {
  const ReaderBody({super.key, required this.paragraphs, this.bodyBuilder});

  final List<String> paragraphs;
  final ReaderBodyBuilder? bodyBuilder;

  @override
  Widget build(BuildContext context) {
    final customBody = bodyBuilder;
    if (customBody != null) {
      return customBody(context, paragraphs);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < paragraphs.length; index += 1)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == paragraphs.length - 1 ? 0 : DayzSpacing.s4,
            ),
            child: Text(paragraphs[index], style: context.dayzText.diary),
          ),
      ],
    );
  }
}
