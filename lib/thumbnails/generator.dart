// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:image/image.dart' as img;

import '../data/database.dart';
import '../data/repositories/media_repo.dart';
import '../media/media_codec.dart';
import 'thumbnail_handle.dart';

bool disableIsolateForTesting = false;

class ThumbnailGenerationException implements Exception {
  final String message;
  ThumbnailGenerationException(this.message);

  @override
  String toString() => 'ThumbnailGenerationException: $message';
}

class GeneratorTaskInput {
  final Uint8List encryptedSrcBytes;
  final Uint8List deviceMediaKey;

  GeneratorTaskInput({
    required this.encryptedSrcBytes,
    required this.deviceMediaKey,
  });
}

class GeneratorTaskResult {
  final Uint8List encryptedThumbBytes;
  final int width;
  final int height;

  GeneratorTaskResult({
    required this.encryptedThumbBytes,
    required this.width,
    required this.height,
  });
}

Future<Uint8List> decryptBytes(Uint8List cipher, Uint8List key) async {
  final codec = MediaCodec();
  final stream = codec.decrypt(
    cipher: Stream.fromIterable([cipher]),
    key: key,
  );
  final builder = BytesBuilder();
  await for (final chunk in stream) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}

Future<Uint8List> encryptBytes(Uint8List plain, Uint8List key) async {
  final codec = MediaCodec();
  final stream = codec.encrypt(
    plain: Stream.fromIterable([plain]),
    key: key,
  );
  final builder = BytesBuilder();
  await for (final chunk in stream) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}

Future<GeneratorTaskResult> generateInIsolate(GeneratorTaskInput input) async {
  Uint8List plainBytes;
  try {
    plainBytes = await decryptBytes(input.encryptedSrcBytes, input.deviceMediaKey);
  } catch (e) {
    throw ThumbnailGenerationException('Failed to decrypt source image: $e');
  }

  final decodedImage = img.decodeImage(plainBytes);
  if (decodedImage == null) {
    throw ThumbnailGenerationException('Failed to decode source image');
  }

  img.Image resizedImage;
  if (decodedImage.width > decodedImage.height) {
    if (decodedImage.width > 384) {
      resizedImage = img.copyResize(decodedImage, width: 384);
    } else {
      resizedImage = decodedImage;
    }
  } else {
    if (decodedImage.height > 384) {
      resizedImage = img.copyResize(decodedImage, height: 384);
    } else {
      resizedImage = decodedImage;
    }
  }

  Uint8List jpegBytes;
  try {
    jpegBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
  } catch (e) {
    throw ThumbnailGenerationException('Failed to encode thumbnail to JPEG: $e');
  }

  Uint8List encryptedThumbBytes;
  try {
    encryptedThumbBytes = await encryptBytes(jpegBytes, input.deviceMediaKey);
  } catch (e) {
    throw ThumbnailGenerationException('Failed to encrypt thumbnail: $e');
  }

  return GeneratorTaskResult(
    encryptedThumbBytes: encryptedThumbBytes,
    width: resizedImage.width,
    height: resizedImage.height,
  );
}

Future<ThumbnailResult> generateThumbnail({
  required String mediaId,
  required Uint8List encryptedSrcBytes,
  required Uint8List deviceMediaKey,
  required File targetFile,
  required MediaRepo mediaRepo,
  required MediaData originalMedia,
  required AppDatabase db,
}) async {
  final taskInput = GeneratorTaskInput(
    encryptedSrcBytes: encryptedSrcBytes,
    deviceMediaKey: deviceMediaKey,
  );

  final taskResult = disableIsolateForTesting
      ? await generateInIsolate(taskInput)
      : await Isolate.run(() => generateInIsolate(taskInput));

  final tmpFile = File('${targetFile.path}.tmp');
  final thumbsDir = targetFile.parent;
  if (!await thumbsDir.exists()) {
    await thumbsDir.create(recursive: true);
  }

  try {
    if (await tmpFile.exists()) {
      await tmpFile.delete();
    }
    await tmpFile.writeAsBytes(taskResult.encryptedThumbBytes);
    await tmpFile.rename(targetFile.path);
  } catch (e) {
    if (await tmpFile.exists()) {
      await tmpFile.delete();
    }
    throw ThumbnailGenerationException('Failed to write thumbnail files: $e');
  }

  try {
    final relativizedPath = 'thumbs/$mediaId.bin';
    final updatedMedia = await mediaRepo.updateThumb(
      mediaId,
      thumbPath: relativizedPath,
      w: taskResult.width,
      h: taskResult.height,
      srcUpdatedAt: originalMedia.updatedAt,
    );

    final fullyAlignedMedia = updatedMedia.copyWith(
      thumbSrcUpdatedAt: Value(updatedMedia.updatedAt),
    );
    await db.mediaDao.updateMedia(fullyAlignedMedia.toCompanion(false));

    return ThumbnailResult(
      relPath: relativizedPath,
      w: taskResult.width,
      h: taskResult.height,
    );
  } catch (dbError) {
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    throw ThumbnailGenerationException('Database transaction failed: $dbError');
  }
}
