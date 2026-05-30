// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

// @Ray

import 'dart:async';
import 'package:tar/tar.dart';

/// Stream-oriented TAR writer.
class TarStreamWriter {
  final StreamSink<TarEntry> _sink;

  TarStreamWriter(StreamSink<List<int>> outputSink)
    : _sink = tarWritingSink(outputSink);

  /// Adds a file entry to the TAR archive.
  /// If the size is known, specify it to optimize performance (prevent buffering).
  Future<void> addEntry(
    String name,
    Stream<List<int>> dataStream, {
    int? size,
  }) async {
    final header = TarHeader(
      name: name,
      mode: 420, // octal 644
      size: size ?? -1,
    );
    _sink.add(TarEntry(header, dataStream));
  }

  /// Adds a synchronous in-memory file entry.
  Future<void> addDataEntry(String name, List<int> data) async {
    final header = TarHeader(
      name: name,
      mode: 420, // octal 644
    );
    _sink.add(TarEntry.data(header, data));
  }

  /// Closes the TAR writer and flushes the remaining data.
  Future<void> close() async {
    await _sink.close();
  }
}

/// Stream-oriented TAR reader.
class TarStreamReader {
  final TarReader _reader;

  TarStreamReader(Stream<List<int>> inputStream)
    : _reader = TarReader(inputStream);

  /// Moves to the next entry in the TAR archive.
  /// Returns false if there are no more entries.
  Future<bool> moveNext() => _reader.moveNext();

  /// Gets the name of the current entry.
  String get name => _reader.current.name;

  /// Gets the size of the current entry in bytes.
  int get size => _reader.current.size;

  /// Gets the contents stream of the current entry.
  Stream<List<int>> get contents => _reader.current.contents;

  /// Closes the TAR reader.
  Future<void> cancel() async {
    await _reader.cancel();
  }
}
