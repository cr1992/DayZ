// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List testKey([int seed = 0]) {
  return Uint8List.fromList(List<int>.generate(32, (index) => seed + index));
}

Stream<List<int>> byteStream(List<int> bytes, {int chunkSize = 17}) async* {
  for (var offset = 0; offset < bytes.length; offset += chunkSize) {
    final end = offset + chunkSize > bytes.length
        ? bytes.length
        : offset + chunkSize;
    yield Uint8List.fromList(bytes.sublist(offset, end));
  }
}

Stream<List<int>> patternStream(
  int totalBytes, {
  int chunkSize = 64 * 1024,
}) async* {
  var emitted = 0;
  while (emitted < totalBytes) {
    final length = totalBytes - emitted > chunkSize
        ? chunkSize
        : totalBytes - emitted;
    final chunk = Uint8List(length);
    for (var i = 0; i < length; i++) {
      chunk[i] = (emitted + i) & 0xff;
    }
    emitted += length;
    yield chunk;
  }
}

Future<Uint8List> collectBytes(Stream<List<int>> stream) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in stream) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}

Future<Checksum> checksum(Stream<List<int>> stream) async {
  var length = 0;
  var sum = 0;
  var xor = 0;
  await for (final chunk in stream) {
    length += chunk.length;
    for (final byte in chunk) {
      sum = (sum + byte) & 0x3fffffff;
      xor ^= byte;
    }
  }
  return Checksum(length: length, sum: sum, xor: xor);
}

class Checksum {
  final int length;
  final int sum;
  final int xor;

  const Checksum({required this.length, required this.sum, required this.xor});

  @override
  bool operator ==(Object other) {
    return other is Checksum &&
        other.length == length &&
        other.sum == sum &&
        other.xor == xor;
  }

  @override
  int get hashCode => Object.hash(length, sum, xor);

  @override
  String toString() => 'Checksum(length: $length, sum: $sum, xor: $xor)';
}

void mockApplicationDocumentsDirectory(Directory directory) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (methodCall) async {
          if (methodCall.method == 'getApplicationDocumentsDirectory') {
            return directory.path;
          }
          return null;
        },
      );
}
