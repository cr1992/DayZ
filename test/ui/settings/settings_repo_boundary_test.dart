// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings UI and demo do not import data, drift, or security layers', () {
    final roots = [
      Directory('lib/ui/settings'),
      File('lib/demo/settings_screen_demo.dart'),
    ];

    final files = roots.expand((entity) {
      if (entity is Directory && entity.existsSync()) {
        return entity
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'));
      }
      if (entity is File && entity.existsSync()) {
        return [entity];
      }
      return const Iterable<File>.empty();
    });

    for (final file in files) {
      final imports = file
          .readAsLinesSync()
          .where((line) => line.trimLeft().startsWith('import '))
          .join('\n');

      expect(
        imports,
        isNot(
          anyOf(
            contains('package:drift'),
            contains('/data/'),
            contains('data/repositories/'),
            contains('/security/'),
          ),
        ),
        reason: '${file.path} must stay display-only and callback-driven.',
      );
    }
  });
}
