// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/ui/reader/reader_meta.dart';
import 'package:dayz/ui/reader/reader_view_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../l10n/localized_test_app.dart';

/// Reader metadata presentation tests.
///
/// Author: @Ray
void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('zh');
  });

  testWidgets('renders all metadata fields with localized labels', (
    tester,
  ) async {
    final data = ReaderViewData(
      id: 'entry-1',
      dateTimeLocal: DateTime(2026, 5, 31, 21, 18),
      title: 'A quiet night',
      bodyParagraphs: const ['Moon above the desk'],
      cover: const ReaderMediaViewData(id: 'cover-1', relPath: 'cover.bin'),
      weather: const ReaderWeatherViewData(
        code: 'cloudy',
        temperatureCelsius: 22,
      ),
      place: 'Shanghai',
      mood: 'Calm',
      tags: const [
        ReaderTagViewData(id: 'tag-work', name: 'Work'),
        ReaderTagViewData(id: 'tag-family', name: 'Family'),
      ],
      galleryImages: const [
        ReaderMediaViewData(id: 'image-1', relPath: 'image.bin'),
      ],
      journalId: 'journal-a',
      favorite: true,
    );
    final expectedDate = DateFormat.yMMMMd('en').format(data.dateTimeLocal);

    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('en'),
        child: ReaderMeta(data: data, locale: 'en'),
      ),
    );

    expect(find.text(expectedDate), findsOneWidget);
    expect(find.text('2026-05-31'), findsNothing);
    expect(find.text(testEnL10n.readerMetaDate), findsOneWidget);
    expect(find.text(testEnL10n.readerMetaWeather), findsOneWidget);
    expect(find.text(testEnL10n.readerMetaPlace), findsOneWidget);
    expect(find.text(testEnL10n.readerMetaMood), findsOneWidget);
    expect(find.text(testEnL10n.readerMetaTags), findsOneWidget);
    expect(find.text('cloudy 22°C'), findsOneWidget);
    expect(find.text('Shanghai'), findsOneWidget);
    expect(find.text('Calm'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);
    expect(
      find.bySemanticsLabel(testEnL10n.readerDateSemantic(expectedDate)),
      findsOneWidget,
    );
  });

  testWidgets('folds empty optional metadata fields out of the tree', (
    tester,
  ) async {
    final data = ReaderViewData(
      id: 'entry-2',
      dateTimeLocal: DateTime(2026, 6, 1, 7, 30),
      title: '',
      bodyParagraphs: const ['Only text'],
      journalId: 'journal-a',
      favorite: false,
    );

    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('zh'),
        child: ReaderMeta(data: data, locale: 'zh'),
      ),
    );

    expect(find.text(testL10n.readerMetaDate), findsOneWidget);
    expect(find.byKey(ReaderMeta.metaWrapKey), findsNothing);
    expect(find.byKey(ReaderMeta.tagsWrapKey), findsNothing);
    expect(find.text(testL10n.readerMetaWeather), findsNothing);
    expect(find.text(testL10n.readerMetaPlace), findsNothing);
    expect(find.text(testL10n.readerMetaMood), findsNothing);
    expect(find.text(testL10n.readerMetaTags), findsNothing);
  });
}
