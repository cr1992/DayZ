// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class TZException implements Exception {
  final String message;

  const TZException(this.message);

  @override
  String toString() => 'TZException: $message';
}

void initTimezoneData() {
  tz_data.initializeTimeZones();
}

class TimeZoneTriple {
  static ({int year, int month, int day}) compute(
    DateTime utcDt,
    String timeZoneName,
  ) {
    final normalizedTimeZoneName = timeZoneName == 'UTC'
        ? 'Etc/UTC'
        : timeZoneName;
    final tz.Location location;
    try {
      location = tz.getLocation(normalizedTimeZoneName);
    } on tz.LocationNotFoundException catch (error) {
      throw TZException(error.toString());
    }
    final local = tz.TZDateTime.from(utcDt.toUtc(), location);

    return (year: local.year, month: local.month, day: local.day);
  }
}
