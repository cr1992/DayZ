// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// @Ray

/// Base exception for backup operations.
class BackupException implements Exception {
  final String message;
  const BackupException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when the backup password/key is incorrect.
class BadPassword implements Exception {
  final String message;
  const BadPassword([this.message = 'Incorrect backup password or key']);

  @override
  String toString() => 'BadPassword: $message';
}

/// Thrown when the manifest schema version is incompatible with current App.
class SchemaIncompatible implements Exception {
  final String message;
  const SchemaIncompatible([
    this.message = 'Backup schema version is incompatible',
  ]);

  @override
  String toString() => 'SchemaIncompatible: $message';
}

/// Thrown when manifest.json is missing or corrupted.
class ManifestCorrupted implements Exception {
  final String message;
  const ManifestCorrupted([
    this.message = 'Backup manifest is corrupted or missing',
  ]);

  @override
  String toString() => 'ManifestCorrupted: $message';
}

/// Thrown when confirmation to overwrite the database is rejected by the user.
class BackupCancelledException implements Exception {
  final String message;
  const BackupCancelledException([this.message = 'Backup operation cancelled']);

  @override
  String toString() => 'BackupCancelledException: $message';
}

/// Thrown when backup header or file format is invalid.
class InvalidBackupFormatException implements Exception {
  final String message;
  const InvalidBackupFormatException([
    this.message = 'Invalid backup format or bad magic',
  ]);

  @override
  String toString() => 'InvalidBackupFormatException: $message';
}
