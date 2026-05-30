// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shell code does not import persistence or repository layers', () {
    final dartFiles = Directory('lib/ui/shell')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final imports = file
          .readAsLinesSync()
          .where((line) => line.trimLeft().startsWith('import '))
          .join('\n');

      expect(
        imports,
        isNot(
          anyOf(
            contains('package:drift/'),
            contains('package:drift'),
            contains('/drift/'),
            contains('data/database.dart'),
            contains('data/repositories/'),
          ),
        ),
        reason: '${file.path} must stay behind repository/input callbacks.',
      );
    }
  });
}
