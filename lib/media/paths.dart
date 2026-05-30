// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String mediaDirectoryName = 'media';

Future<Directory> applicationDocumentsDir() {
  return getApplicationDocumentsDirectory();
}

Future<Directory> mediaRootDir({Directory? documentsDir}) async {
  final docs = documentsDir ?? await applicationDocumentsDir();
  final root = Directory(p.join(docs.path, mediaDirectoryName));
  if (!await root.exists()) {
    await root.create(recursive: true);
  }
  return root;
}

Future<String> relativize(String absPath, {Directory? documentsDir}) async {
  final docs = documentsDir ?? await applicationDocumentsDir();
  return relativizeWithDocumentsDir(absPath, documentsPath: docs.path);
}

String relativizeWithDocumentsDir(
  String absPath, {
  required String documentsPath,
  p.Context? context,
}) {
  final ctx = context ?? p.context;
  final docs = ctx.normalize(ctx.absolute(documentsPath));
  final abs = ctx.normalize(ctx.absolute(absPath));
  if (abs == docs || !ctx.isWithin(docs, abs)) {
    throw ArgumentError.value('outside documents', 'absPath');
  }

  final rel = ctx.relative(abs, from: docs);
  if (!_isSafeRelativePath(rel, context: ctx)) {
    throw ArgumentError.value('unsafe relative media path', 'absPath');
  }
  return rel.split(ctx.separator).join('/');
}

Future<File> resolveRelPath(String relPath, {Directory? documentsDir}) async {
  final docs = documentsDir ?? await applicationDocumentsDir();
  return resolveRelPathWithDocumentsDir(relPath, documentsPath: docs.path);
}

File resolveRelPathWithDocumentsDir(
  String relPath, {
  required String documentsPath,
  p.Context? context,
}) {
  final ctx = context ?? p.context;
  if (!_isSafeRelativePath(relPath, context: p.posix)) {
    throw ArgumentError.value('unsafe relative media path', 'relPath');
  }

  final docs = ctx.normalize(ctx.absolute(documentsPath));
  final nativeRel = relPath.split('/').join(ctx.separator);
  final abs = ctx.normalize(ctx.join(docs, nativeRel));
  if (!ctx.isWithin(docs, abs)) {
    throw ArgumentError.value('outside documents', 'relPath');
  }
  return File(abs);
}

bool _isSafeRelativePath(String value, {required p.Context context}) {
  if (value.isEmpty || context.isAbsolute(value) || value.contains(r'\')) {
    return false;
  }
  final parts = value.split(context.separator);
  return parts.every((part) => part.isNotEmpty && part != '.' && part != '..');
}
