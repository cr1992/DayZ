// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'log_level.dart';

class LogRecord {
  final LogLevel level;
  final String event;
  final DateTime ts;
  final String? message;
  final Map<String, Object?> fields;

  LogRecord({
    required this.level,
    required this.event,
    required this.ts,
    this.message,
    required this.fields,
  });
}
