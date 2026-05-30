// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/observability/log_paths.dart';

void main() {
  group('LogPaths Tests', () {
    test('logsSubdir is correct', () {
      expect(logsSubdir, 'logs');
    });

    test('resolveLogsDir returns correct subdirectory path', () {
      final fakeAppSupport = Directory('/fake/app_support');
      final logsDir = resolveLogsDir(fakeAppSupport);
      expect(logsDir.path, startsWith(fakeAppSupport.path));
      expect(logsDir.path, endsWith('${Platform.pathSeparator}logs'));
    });

    test('resolveLogsDir handles trailing slashes correctly', () {
      final separator = Platform.pathSeparator;
      final fakeAppSupport = Directory('/fake/app_support$separator');
      final logsDir = resolveLogsDir(fakeAppSupport);
      expect(logsDir.path, '/fake/app_support${separator}logs');
    });
  });
}
