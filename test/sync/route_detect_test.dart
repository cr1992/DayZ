// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';

import '../../bin/sync/detectors.dart';
import '../../bin/sync/route.dart';

void main() {
  group('Phase 1 routeDesignChanges', () {
    test(
      'routes token changes to Phase 2 and shared screen assets to screens',
      () {
        final result = routeDesignChanges(<String>[
          'ui-design/current/design-system/assets/tokens.css',
          'ui-design/current/pages/assets/screen.css',
        ]);

        expect(result.tokenChanged, isTrue);
        expect(result.screenIds, unorderedEquals(defaultDesignScreenIds));
        expect(result.uiKitComponentsChanged, isFalse);
      },
    );

    test('routes screen HTML, timeline-only assets, and DESIGN-REF', () {
      final result = routeDesignChanges(<String>[
        'ui-design/current/pages/screens/reader.html',
        'ui-design/current/pages/assets/timeline.js',
        'ui-design/current/docs/DESIGN-REF.md',
      ]);

      expect(result.tokenChanged, isFalse);
      expect(result.screenIds, unorderedEquals(<String>{'reader', 'timeline'}));
      expect(result.uiKitComponentsChanged, isTrue);
    });

    test('is deterministic for equivalent inputs', () {
      final input = <String>[
        './ui-design/current/pages/screens/timeline.html',
        r'ui-design\current\pages\assets\screen.js',
      ];

      expect(routeDesignChanges(input), routeDesignChanges(input));
    });

    test('extracts changed files from unified diff headers', () {
      const diff = '''
diff --git a/ui-design/current/pages/screens/timeline.html b/ui-design/current/pages/screens/timeline.html
index 1111111..2222222 100644
--- a/ui-design/current/pages/screens/timeline.html
+++ b/ui-design/current/pages/screens/timeline.html
diff --git a/ui-design/current/pages/assets/timeline.css b/ui-design/current/pages/assets/timeline.css
index 3333333..4444444 100644
--- a/ui-design/current/pages/assets/timeline.css
+++ b/ui-design/current/pages/assets/timeline.css
''';

      expect(changedFilesFromUnifiedDiff(diff), <String>[
        'ui-design/current/pages/screens/timeline.html',
        'ui-design/current/pages/assets/timeline.css',
      ]);
    });
  });

  group('R5 substantial change detectors', () {
    test('detects new classes and mapped classes missing geometry', () {
      const html = '''
<main class="screen wrapper">
  <article class="entry new-card" data-when="filled"></article>
</main>
''';
      final result = detectSubstantialChanges(
        extractedClasses: extractClassesFromHtml(html),
        registry: const <ElementMapEntry>[
          ElementMapEntry(cssClass: '.screen', geometry: 'fixed'),
          ElementMapEntry(cssClass: '.entry'),
        ],
        ignoredClasses: const <String>{'wrapper'},
      );

      expect(
        result.unmappedClasses,
        unorderedEquals(<String>{'entry', 'new-card'}),
      );
      expect(result.missingGeometryClasses, unorderedEquals(<String>{'entry'}));
      expect(result.hasSubstantialChange, isTrue);
    });

    test('pure ignored classes do not trigger unmapped changes', () {
      final result = detectSubstantialChanges(
        extractedClasses: const <String>{'decor', 'shell'},
        registry: const <ElementMapEntry>[
          ElementMapEntry(cssClass: '.shell', geometry: 'content'),
        ],
        ignoredClasses: const <String>{'decor'},
      );

      expect(result.unmappedClasses, isEmpty);
      expect(result.hasSubstantialChange, isFalse);
    });

    test('detects data-when value set changes', () {
      final result = detectSubstantialChanges(
        extractedClasses: const <String>{},
        registry: const <ElementMapEntry>[],
        beforeDataWhenValues: extractDataWhenValues(
          '<section data-when="filled"></section>',
        ),
        afterDataWhenValues: extractDataWhenValues(
          '<section data-when="filled"></section><section data-when="empty"></section>',
        ),
      );

      expect(result.newDataWhenValues, unorderedEquals(<String>{'empty'}));
      expect(result.removedDataWhenValues, isEmpty);
      expect(result.hasSubstantialChange, isTrue);
    });

    test('detects normalized DOM child order changes', () {
      final before = normalizedDomChildSequence(
        '<main><section class="a"></section><section class="b"></section></main>',
      );
      final after = normalizedDomChildSequence(
        '<main><section class="b"></section><section class="a"></section></main>',
      );

      final result = detectSubstantialChanges(
        extractedClasses: const <String>{},
        registry: const <ElementMapEntry>[],
        beforeDomSequence: before,
        afterDomSequence: after,
      );

      expect(result.domOrderChanged, isTrue);
      expect(result.hasSubstantialChange, isTrue);
    });

    test('parses minimal element-map yaml entries', () {
      const yaml = '''
- class: ".entry"
  key: "entryCard"
  geometry: content
  asserts: [order, contains, no-overflow]
- class: ".hero"
  key: "hero"
''';

      final entries = parseElementMapYaml(yaml);

      expect(entries, hasLength(2));
      expect(entries.first.normalizedClass, 'entry');
      expect(entries.first.geometry, 'content');
      expect(entries.last.normalizedClass, 'hero');
      expect(entries.last.hasValidGeometry, isFalse);
    });
  });
}
