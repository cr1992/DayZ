// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// @Ray

import 'dart:convert';

class ManifestMediaItem {
  final String id;
  final String mime;
  final int size;

  const ManifestMediaItem({
    required this.id,
    required this.mime,
    required this.size,
  });

  factory ManifestMediaItem.fromJson(Map<String, dynamic> json) {
    return ManifestMediaItem(
      id: json['id'] as String,
      mime: json['mime'] as String,
      size: json['size'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'mime': mime, 'size': size};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManifestMediaItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          mime == other.mime &&
          size == other.size;

  @override
  int get hashCode => id.hashCode ^ mime.hashCode ^ size.hashCode;
}

class Manifest {
  final int formatVersion;
  final String backupType;
  final int schemaVersion;
  final DateTime generatedAt;
  final String appVersion;
  final int entryCount;
  final int mediaCount;
  final List<ManifestMediaItem> mediaIndex;

  const Manifest({
    required this.formatVersion,
    required this.backupType,
    required this.schemaVersion,
    required this.generatedAt,
    required this.appVersion,
    required this.entryCount,
    required this.mediaCount,
    required this.mediaIndex,
  });

  factory Manifest.fromJson(Map<String, dynamic> json) {
    return Manifest(
      formatVersion: json['format_version'] as int,
      backupType: json['backup_type'] as String,
      schemaVersion: json['schema_version'] as int,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      appVersion: json['app_version'] as String,
      entryCount: json['entry_count'] as int,
      mediaCount: json['media_count'] as int,
      mediaIndex: (json['media_index'] as List<dynamic>)
          .map((e) => ManifestMediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'format_version': formatVersion,
      'backup_type': backupType,
      'schema_version': schemaVersion,
      'generated_at': generatedAt.toUtc().toIso8601String(),
      'app_version': appVersion,
      'entry_count': entryCount,
      'media_count': mediaCount,
      'media_index': mediaIndex.map((e) => e.toJson()).toList(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory Manifest.fromJsonString(String rawJson) {
    return Manifest.fromJson(jsonDecode(rawJson) as Map<String, dynamic>);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Manifest &&
          runtimeType == other.runtimeType &&
          formatVersion == other.formatVersion &&
          backupType == other.backupType &&
          schemaVersion == other.schemaVersion &&
          generatedAt.toUtc().millisecondsSinceEpoch ==
              other.generatedAt.toUtc().millisecondsSinceEpoch &&
          appVersion == other.appVersion &&
          entryCount == other.entryCount &&
          mediaCount == other.mediaCount &&
          _listEquals(mediaIndex, other.mediaIndex);

  @override
  int get hashCode =>
      formatVersion.hashCode ^
      backupType.hashCode ^
      schemaVersion.hashCode ^
      generatedAt.hashCode ^
      appVersion.hashCode ^
      entryCount.hashCode ^
      mediaCount.hashCode ^
      mediaIndex.hashCode;

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
