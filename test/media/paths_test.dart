// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:dayz/media/paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'media_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('dayz_media_paths_test');
    mockApplicationDocumentsDirectory(tempDir);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('mediaRootDir creates <documents>/media', () async {
    final root = await mediaRootDir();
    expect(root.path, p.join(tempDir.path, 'media'));
    expect(await root.exists(), isTrue);
  });

  test(
    'relativize returns media-relative path and resolve reverses it',
    () async {
      final file = File(p.join(tempDir.path, 'media', 'abc.bin'));
      final relPath = await relativize(file.path);
      expect(relPath, 'media/abc.bin');
      expect(p.isAbsolute(relPath), isFalse);

      final resolved = await resolveRelPath(relPath);
      expect(resolved.path, file.path);
    },
  );

  test('relativize handles iOS and Android shaped document paths', () {
    final posix = p.Context(style: p.Style.posix);

    expect(
      relativizeWithDocumentsDir(
        '/var/mobile/Containers/Data/Application/app/Documents/media/a.bin',
        documentsPath: '/var/mobile/Containers/Data/Application/app/Documents',
        context: posix,
      ),
      'media/a.bin',
    );
    expect(
      relativizeWithDocumentsDir(
        '/data/data/com.dayz/app_flutter/media/b.bin',
        documentsPath: '/data/data/com.dayz/app_flutter',
        context: posix,
      ),
      'media/b.bin',
    );
  });

  test('path helpers reject traversal and outside documents paths', () {
    final posix = p.Context(style: p.Style.posix);

    expect(
      () => relativizeWithDocumentsDir(
        '/data/data/com.dayz/cache/a.bin',
        documentsPath: '/data/data/com.dayz/app_flutter',
        context: posix,
      ),
      throwsArgumentError,
    );
    expect(
      () => resolveRelPathWithDocumentsDir(
        '../cache/a.bin',
        documentsPath: '/data/data/com.dayz/app_flutter',
        context: posix,
      ),
      throwsArgumentError,
    );
  });
}
