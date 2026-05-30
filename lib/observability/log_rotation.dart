// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// 单个日志文件大小软上限 (1 MiB)
const int softMaxBytes = 1 * 1024 * 1024;

/// 备份日志文件保留的最大份数 (3 份：app.log.1, app.log.2, app.log.3)
const int maxFiles = 3;

/// 磁盘占用硬上限 (~3 MiB)
const int hardCapBytes = 3 * 1024 * 1024;

/// 日志队列容量限制
const int queueCapacity = 4096;

/// 轮转决策返回模型
class RotationDecision {
  /// 是否需要触发轮转
  final bool rotate;

  /// 需要删除的文件名列表
  final List<String> filesToDelete;

  RotationDecision({required this.rotate, required this.filesToDelete});
}

/// 轮转决策纯函数。
///
/// [currentFileBytes] 当前主日志文件 (app.log) 的大小。
/// [newLineBytes] 即将写入的下一行日志的大小（字节）。
/// [existingBackupFiles] 当前日志目录下存在的备份文件名称列表（如 ['app.log.1', 'app.log.2']）。
RotationDecision evaluateRotation(
  int currentFileBytes,
  int newLineBytes,
  List<String> existingBackupFiles,
) {
  final rotate = (currentFileBytes + newLineBytes) > softMaxBytes;
  final filesToDelete = <String>[];

  if (rotate) {
    // 轮转会使得所有备份文件索引 +1 (app.log -> .1 -> .2 -> .3 -> 丢弃)
    // 所以当前任何索引 >= maxFiles 的备份文件，在轮转后都会超出限制而被丢弃。
    for (final filename in existingBackupFiles) {
      final parts = filename.split('.');
      if (parts.length > 2) {
        final idx = int.tryParse(parts.last);
        if (idx != null && idx >= maxFiles) {
          filesToDelete.add(filename);
        }
      }
    }
  }

  return RotationDecision(rotate: rotate, filesToDelete: filesToDelete);
}
