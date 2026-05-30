// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// @Ray

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Gets the backup temp directory (using the system temporary directory).
Future<Directory> getBackupTempDirectory() async {
  final tempDir = await getTemporaryDirectory();
  final backupTemp = Directory(p.join(tempDir.path, 'dayz_backup'));
  if (!await backupTemp.exists()) {
    await backupTemp.create(recursive: true);
  }
  return backupTemp;
}

/// Gets the default backup output directory under app documents.
Future<Directory> getBackupOutputDirectory() async {
  final docsDir = await getApplicationDocumentsDirectory();
  final exportDir = Directory(p.join(docsDir.path, 'exports'));
  if (!await exportDir.exists()) {
    await exportDir.create(recursive: true);
  }
  return exportDir;
}
