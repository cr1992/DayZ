// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

enum LogLevel implements Comparable<LogLevel> {
  fine,
  info,
  warning,
  severe;

  @override
  int compareTo(LogLevel other) => index.compareTo(other.index);

  bool operator <(LogLevel other) => index < other.index;
  bool operator <=(LogLevel other) => index <= other.index;
  bool operator >(LogLevel other) => index > other.index;
  bool operator >=(LogLevel other) => index >= other.index;
}

LogLevel defaultLevelFor(bool releaseMode) {
  return releaseMode ? LogLevel.info : LogLevel.fine;
}
