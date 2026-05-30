// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

abstract class MediaException implements Exception {
  final String message;

  const MediaException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class MediaCorruptedException extends MediaException {
  MediaCorruptedException([String? relPath])
    : super(
        'Media file is corrupted${relPath == null ? '' : ': ${_safePath(relPath)}'}',
      );
}

class MediaNotFoundException extends MediaException {
  MediaNotFoundException(String relPath)
    : super('Media file not found: ${_safePath(relPath)}');
}

class KeyMissingException extends MediaException {
  KeyMissingException([super.message = 'Device media key is not available']);
}

String _safePath(String path) {
  if (path.startsWith('/') || path.contains(r'\') || path.contains(':')) {
    return '<media>';
  }
  return path;
}
