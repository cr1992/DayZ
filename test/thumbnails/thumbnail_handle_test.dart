// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/thumbnails/cancel_token.dart';
import 'package:dayz/thumbnails/thumbnail_handle.dart';

void main() {
  group('ThumbnailHandle and Contract Tests', () {
    test('ThumbnailState values exact match', () {
      expect(ThumbnailState.values, equals([
        ThumbnailState.pending,
        ThumbnailState.ready,
        ThumbnailState.failed,
        ThumbnailState.cancelled,
      ]));
    });

    test('ThumbnailPriority values exact match', () {
      expect(ThumbnailPriority.values, equals([
        ThumbnailPriority.normal,
        ThumbnailPriority.low,
      ]));
    });

    test('ThumbnailResult fields roundtrip', () {
      final result = ThumbnailResult(relPath: 'thumbs/x.bin', w: 384, h: 256);
      expect(result.relPath, equals('thumbs/x.bin'));
      expect(result.w, equals(384));
      expect(result.h, equals(256));
    });

    test('ThumbnailHandle status transition - ready', () async {
      final cancelToken = CancelToken();
      final handle = ThumbnailHandle(cancelToken: cancelToken);
      expect(handle.state, equals(ThumbnailState.pending));

      final expectedResult = ThumbnailResult(relPath: 'thumbs/x.bin', w: 384, h: 256);
      handle.complete(expectedResult);

      expect(handle.state, equals(ThumbnailState.ready));
      final actualResult = await handle.future;
      expect(actualResult, equals(expectedResult));
    });

    test('ThumbnailHandle status transition - failed', () async {
      final cancelToken = CancelToken();
      final handle = ThumbnailHandle(cancelToken: cancelToken);
      expect(handle.state, equals(ThumbnailState.pending));

      final exception = Exception('Generation failed');
      handle.completeError(exception);

      expect(handle.state, equals(ThumbnailState.failed));
      expect(() => handle.future, throwsA(equals(exception)));
    });

    test('ThumbnailHandle status transition - cancelled', () async {
      final cancelToken = CancelToken();
      final handle = ThumbnailHandle(cancelToken: cancelToken);
      expect(handle.state, equals(ThumbnailState.pending));

      handle.cancel();

      expect(handle.state, equals(ThumbnailState.cancelled));
      expect(cancelToken.isCancelled, isTrue);
      expect(() => handle.future, throwsA(isA<Exception>()));
    });
  });
}
