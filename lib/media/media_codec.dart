// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'exceptions.dart';

class MediaCodec {
  static const int version = 1;
  static const int algorithmAes256Gcm = 1;
  static const int nonceLength = 12;
  static const int tagLength = 16;
  static const int headerLength = 20;

  static const List<int> magic = [0x44, 0x4d, 0x45, 0x44]; // DMED

  final AesGcm _algorithm;

  MediaCodec({AesGcm? algorithm})
    : _algorithm = algorithm ?? AesGcm.with256bits(nonceLength: nonceLength);

  Stream<List<int>> encrypt({
    required Stream<List<int>> plain,
    required Uint8List key,
  }) async* {
    _validateKey(key);
    final nonce = _algorithm.newNonce();
    final secretKey = SecretKey(Uint8List.fromList(key));

    yield _buildHeader(nonce);

    Mac? mac;
    yield* _algorithm.encryptStream(
      plain,
      secretKey: secretKey,
      nonce: nonce,
      onMac: (value) => mac = value,
    );

    final tag = mac;
    if (tag == null || tag.bytes.length != tagLength) {
      throw MediaCorruptedException();
    }
    yield Uint8List.fromList(tag.bytes);
  }

  Stream<List<int>> decrypt({
    required Stream<List<int>> cipher,
    required Uint8List key,
  }) async* {
    _validateKey(key);

    try {
      final cursor = _StreamCursor(cipher);
      final header = await cursor.readExactly(headerLength);
      final nonce = _parseNonce(header);
      final secretKey = SecretKey(Uint8List.fromList(key));
      final macCompleter = Completer<Mac>();
      final verifiedChunks = <Uint8List>[];

      await for (final chunk in _algorithm.decryptStream(
        _cipherTextWithoutTag(cursor, macCompleter),
        secretKey: secretKey,
        nonce: nonce,
        mac: macCompleter.future,
      )) {
        if (chunk.isNotEmpty) {
          verifiedChunks.add(Uint8List.fromList(chunk));
        }
      }

      for (final chunk in verifiedChunks) {
        yield chunk;
      }
    } on MediaCorruptedException {
      rethrow;
    } on SecretBoxAuthenticationError {
      throw MediaCorruptedException();
    } catch (_) {
      throw MediaCorruptedException();
    }
  }

  static Uint8List nonceFromEncryptedBytes(List<int> encrypted) {
    if (encrypted.length < headerLength) {
      throw MediaCorruptedException();
    }
    return _parseNonce(
      Uint8List.fromList(encrypted.take(headerLength).toList()),
    );
  }

  static Uint8List _buildHeader(List<int> nonce) {
    if (nonce.length != nonceLength) {
      throw ArgumentError.value(nonce.length, 'nonce.length');
    }
    final header = Uint8List(headerLength);
    header.setRange(0, 4, magic);
    header[4] = version;
    header[5] = algorithmAes256Gcm;
    header[6] = 0;
    header[7] = 0;
    header.setRange(8, headerLength, nonce);
    return header;
  }

  static Uint8List _parseNonce(Uint8List header) {
    if (header.length != headerLength ||
        header[0] != magic[0] ||
        header[1] != magic[1] ||
        header[2] != magic[2] ||
        header[3] != magic[3] ||
        header[4] != version ||
        header[5] != algorithmAes256Gcm) {
      throw MediaCorruptedException();
    }
    return Uint8List.sublistView(header, 8, headerLength);
  }

  static void _validateKey(Uint8List key) {
    if (key.length != 32) {
      throw ArgumentError.value(key.length, 'key.length', 'Expected 32 bytes');
    }
  }
}

Stream<List<int>> _cipherTextWithoutTag(
  _StreamCursor cursor,
  Completer<Mac> macCompleter,
) async* {
  var tail = Uint8List(0);
  try {
    await for (final chunk in cursor.remainingChunks()) {
      if (chunk.isEmpty) {
        continue;
      }
      final combined = Uint8List(tail.length + chunk.length);
      combined.setRange(0, tail.length, tail);
      combined.setRange(tail.length, combined.length, chunk);
      if (combined.length <= MediaCodec.tagLength) {
        tail = combined;
        continue;
      }

      final emitLength = combined.length - MediaCodec.tagLength;
      yield Uint8List.sublistView(combined, 0, emitLength);
      tail = Uint8List.sublistView(combined, emitLength);
    }

    if (tail.length != MediaCodec.tagLength) {
      throw MediaCorruptedException();
    }
    macCompleter.complete(Mac(Uint8List.fromList(tail)));
  } catch (error, stackTrace) {
    if (!macCompleter.isCompleted) {
      macCompleter.completeError(error, stackTrace);
    }
    rethrow;
  }
}

class _StreamCursor {
  final StreamIterator<List<int>> _iterator;

  Uint8List? _current;
  int _offset = 0;
  bool _done = false;

  _StreamCursor(Stream<List<int>> stream) : _iterator = StreamIterator(stream);

  Future<Uint8List> readExactly(int length) async {
    final builder = BytesBuilder(copy: false);
    var remaining = length;

    while (remaining > 0) {
      if (!await _ensureCurrent()) {
        throw MediaCorruptedException();
      }

      final current = _current!;
      final available = current.length - _offset;
      final take = available < remaining ? available : remaining;
      builder.add(Uint8List.sublistView(current, _offset, _offset + take));
      _offset += take;
      remaining -= take;
    }

    return builder.takeBytes();
  }

  Stream<Uint8List> remainingChunks() async* {
    while (await _ensureCurrent()) {
      final current = _current!;
      if (_offset < current.length) {
        yield Uint8List.sublistView(current, _offset);
        _offset = current.length;
      }
    }
  }

  Future<bool> _ensureCurrent() async {
    while (_current == null || _offset >= _current!.length) {
      if (_done) {
        return false;
      }
      if (!await _iterator.moveNext()) {
        _done = true;
        return false;
      }
      final next = _asUint8List(_iterator.current);
      if (next.isEmpty) {
        continue;
      }
      _current = next;
      _offset = 0;
      return true;
    }
    return true;
  }

  Uint8List _asUint8List(List<int> bytes) {
    if (bytes is Uint8List) {
      return bytes;
    }
    return Uint8List.fromList(bytes);
  }
}
