// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';

/// 日志存放的子目录名称，供备份模块引用排除
const String logsSubdir = 'logs';

/// 根据传入的 ApplicationSupport 目录解析出实际日志存储的目录
Directory resolveLogsDir(Directory appSupport) {
  final separator = Platform.pathSeparator;
  var supportPath = appSupport.path;
  if (supportPath.endsWith(separator)) {
    supportPath = supportPath.substring(0, supportPath.length - 1);
  }
  return Directory('$supportPath$separator$logsSubdir');
}
