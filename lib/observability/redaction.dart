// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'log_record.dart';

/// 将绝对路径转换为相对路径或占位符，避免在日志中泄露绝对路径。
///
/// * 已知绝对路径前缀（如 iOS Documents 或 Android app_flutter）会被去除，仅保留相对路径。
/// * 未知绝对路径会被替换为 `<REDACTED_ABS>` 占位符。
/// * 相对路径保持不变。
String redactAbsolutePath(String path) {
  if (!path.startsWith('/')) {
    return path;
  }

  // iOS 绝对路径检测
  final docIdx = path.indexOf('/Documents/');
  if (docIdx != -1) {
    return path.substring(docIdx + '/Documents/'.length);
  }

  // Android 绝对路径检测
  final appFlutterIdx = path.indexOf('/app_flutter/');
  if (appFlutterIdx != -1) {
    return path.substring(appFlutterIdx + '/app_flutter/'.length);
  }

  // 已知常见前缀但无 Documents/app_flutter 时的保守截取
  if (path.startsWith('/var/mobile/Containers/') ||
      path.startsWith('/data/data/') ||
      path.startsWith('/data/user/')) {
    final packageIdx = path.indexOf('/com.dayz/');
    if (packageIdx != -1) {
      final sub = path.substring(packageIdx + '/com.dayz/'.length);
      if (sub.startsWith('app_flutter/')) {
        return sub.substring('app_flutter/'.length);
      }
      return sub;
    }
  }

  return '<REDACTED_ABS>';
}

/// 辅助函数：替换文本中嵌入的所有绝对路径
String redactMessagePaths(String message) {
  final pathRegex = RegExp(r'''/[^\s:="\'\]\)]+''');
  return message.replaceAllMapped(pathRegex, (match) {
    final path = match.group(0)!;
    if (path == '/') return '/';
    return redactAbsolutePath(path);
  });
}

/// 检查是否为敏感键名
bool isSensitiveKey(String key) {
  final lower = key.toLowerCase();
  return lower.contains('key') ||
      lower.contains('password') ||
      lower.contains('secret') ||
      lower.contains('token') ||
      lower.contains('derived');
}

/// 日志脱敏中间件。
///
/// 职责是接收原始的 [LogRecord] 并产生一个完全脱敏后的 [LogRecord]。
/// 保证绝对路径、敏感密钥、日记正文不会以明文形式出现在输出的日志中。
class Redactor {
  static LogRecord redact(LogRecord record) {
    final redactedMessage =
        record.message != null ? redactMessage(record.message!) : null;

    final redactedFields = <String, Object?>{};
    record.fields.forEach((key, value) {
      if (isSensitiveKey(key)) {
        redactedFields[key] = '***';
      } else if (key == 'content_json' || key == 'content_plain') {
        final valStr = value?.toString() ?? '';
        redactedFields[key] = '<redacted:len=${valStr.length}>';
      } else if (value is String) {
        if (value.startsWith('/')) {
          redactedFields[key] = redactAbsolutePath(value);
        } else {
          redactedFields[key] = redactMessagePaths(value);
        }
      } else {
        redactedFields[key] = value;
      }
    });

    return LogRecord(
      level: record.level,
      event: record.event,
      ts: record.ts,
      message: redactedMessage,
      fields: redactedFields,
    );
  }

  /// 脱敏自由文本消息
  static String redactMessage(String message) {
    // 1. 替换敏感键值模式（如 secret=xxx 或 password: yyy）
    final sensitivePattern = RegExp(
      r'\b(key|password|secret|token|derived)(\s*[:=]\s*)([^\s,;]+)',
      caseSensitive: false,
    );
    var result = message.replaceAllMapped(sensitivePattern, (match) {
      return '${match.group(1)}${match.group(2)}***';
    });

    // 2. 替换可能存在的绝对路径
    result = redactMessagePaths(result);

    return result;
  }
}
