// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'log_record.dart';

/// 日志输出宿座抽象接口。
///
/// 实现方收到的 [LogRecord] 均已由门面经过脱敏处理。
/// [add] 方法绝不可抛出异常（内部降级处理）。
/// [flush] 与 [close] 返回 Future 供 `await` 异步落盘完成与资源释放。
/// 远期新增加密 Sink 实现此接口即为 D3 升级路径。
abstract class LogSink {
  void add(LogRecord redacted);
  Future<void> flush();
  Future<void> close();
}
