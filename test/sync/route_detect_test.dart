// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../bin/sync/detectors.dart';
import '../../bin/sync/route.dart';

void main() {
  group('Phase 1 route', () {
    test('routes known changed files deterministically', () {
      final changes = <DesignDiffEntry>[
        const DesignDiffEntry(
          'ui-design/current/design-system/assets/tokens.css',
        ),
        const DesignDiffEntry('ui-design/current/pages/screens/reader.html'),
        const DesignDiffEntry('ui-design/current/pages/assets/screen.css'),
        const DesignDiffEntry('ui-design/current/pages/assets/screen.js'),
        const DesignDiffEntry('ui-design/current/pages/assets/timeline.css'),
        const DesignDiffEntry('ui-design/current/pages/assets/timeline.js'),
        const DesignDiffEntry('ui-design/current/pages/assets/app.js'),
        const DesignDiffEntry('ui-design/current/docs/CHANGELOG.md'),
        const DesignDiffEntry(
          'ui-design/current/docs/DESIGN-REF.md',
          changedSections: <String>{'3'},
        ),
      ];

      final first = routeDesignChanges(changes);
      final second = routeDesignChanges(changes.reversed);

      expect(first.requiresTokenRegen, isTrue);
      expect(first.screenIds, phase1DefaultScreenIds);
      expect(first.components, <String>[
        'design-changelog',
        'screen-registry',
        'ui-kit',
      ]);
      expect(second.toJson(), first.toJson());
    });

    test('routes a single screen html to that screen only', () {
      final result = routeChangedPaths(<String>[
        'ui-design/current/pages/screens/onthisday.html',
      ]);

      expect(result.requiresTokenRegen, isFalse);
      expect(result.screenIds, <String>['onthisday']);
      expect(result.components, isEmpty);
    });

    test('routes shared screen assets to all phase-1 screens', () {
      final result = routeChangedPaths(<String>[
        'ui-design/current/pages/assets/screen.js',
      ]);

      expect(result.screenIds, phase1DefaultScreenIds);
    });

    test('routes newly registered screen html by id', () {
      final result = routeChangedPaths(<String>[
        'ui-design/current/pages/screens/trash.html',
      ]);

      expect(result.requiresTokenRegen, isFalse);
      expect(result.screenIds, <String>['trash']);
      expect(result.components, isEmpty);
    });

    test('routes timeline assets only to timeline', () {
      final result = routeChangedPaths(<String>[
        'ui-design/current/pages/assets/timeline.css',
      ]);

      expect(result.screenIds, <String>['timeline']);
      expect(result.components, isEmpty);
    });

    test(
      'routes DESIGN-REF section 3 to ui-kit only when section is present',
      () {
        final section3 = routeDesignChanges(<DesignDiffEntry>[
          const DesignDiffEntry(
            'ui-design/current/docs/DESIGN-REF.md',
            changedSections: <String>{'3b'},
          ),
        ]);
        final section2 = routeDesignChanges(<DesignDiffEntry>[
          const DesignDiffEntry(
            'ui-design/current/docs/DESIGN-REF.md',
            changedSections: <String>{'2'},
          ),
        ]);

        expect(section3.components, <String>['ui-kit']);
        expect(section3.screenIds, isEmpty);
        expect(section2.components, isEmpty);
        expect(section2.screenIds, isEmpty);
      },
    );
  });

  group('R5 detectors', () {
    const registry = <ElementRegistryEntry>[
      ElementRegistryEntry(className: 'pg', geometry: GeometryKind.fixed),
      ElementRegistryEntry(
        className: 'timeline',
        geometry: GeometryKind.content,
      ),
      ElementRegistryEntry(className: 'entry', geometry: GeometryKind.content),
      ElementRegistryEntry(
        className: 'entry-title',
        geometry: GeometryKind.content,
      ),
      ElementRegistryEntry(
        className: 'entry-body',
        geometry: GeometryKind.content,
      ),
    ];

    test('unmapped uses all in-DOM classes, not only registered classes', () {
      final unmapped = detectUnmappedClassesFromDom(
        html: fixture('classes_new_class.html'),
        registry: registry,
      );

      expect(unmapped, <String>{'new-panel'});
    });

    test('missing geometry is equivalent to unmapped', () {
      final unmapped = detectUnmappedClassesFromDom(
        html: fixture('classes_base.html'),
        registry: const <ElementRegistryEntry>[
          ElementRegistryEntry(className: 'pg', geometry: GeometryKind.fixed),
          ElementRegistryEntry(
            className: 'timeline',
            geometry: GeometryKind.content,
          ),
          ElementRegistryEntry(className: 'entry'),
          ElementRegistryEntry(
            className: 'entry-title',
            geometry: GeometryKind.content,
          ),
        ],
      );

      expect(unmapped, <String>{'entry'});
    });

    test('pure ignored classes are not unmapped', () {
      final unmapped = detectUnmappedClassesFromDom(
        html: fixture('classes_ignore_only.html'),
        registry: registry,
        ignoreClasses: const <String>{'decor-layer'},
      );

      expect(unmapped, isEmpty);
    });

    test('data-when value-set diff detects added values', () {
      final diff = detectDataWhenDiff(
        beforeHtml: fixture('data_when_before.html'),
        afterHtml: fixture('data_when_after.html'),
      );

      expect(diff.added, <String>{'empty'});
      expect(diff.removed, isEmpty);
      expect(diff.isNotEmpty, isTrue);
    });

    test('normalized DOM child sequence diff detects reorder', () {
      final diff = detectDomChildSequenceDiff(
        beforeHtml: fixture('dom_before.html'),
        afterHtml: fixture('dom_after_reordered.html'),
      );

      expect(diff.isNotEmpty, isTrue);
      expect(diff.before, isNot(diff.after));
    });

    test('normalized DOM child sequence ignores cosmetic wrappers', () {
      final diff = detectDomChildSequenceDiff(
        beforeHtml: fixture('dom_before.html'),
        afterHtml: fixture('dom_after_cosmetic.html'),
        ignoreClasses: const <String>{'decor-layer'},
      );

      expect(diff.isEmpty, isTrue);
    });

    test('any non-empty detector marks a substantive change', () {
      final result = detectSubstantiveChanges(
        beforeHtml: fixture('data_when_before.html'),
        afterHtml: fixture('data_when_after.html'),
        registry: registry,
      );

      expect(result.unmappedClasses, isEmpty);
      expect(result.dataWhenDiff.added, <String>{'empty'});
      expect(result.domSequenceDiff.isEmpty, isTrue);
      expect(result.hasSubstantiveChanges, isTrue);
    });

    test('all empty detectors allow the change to continue', () {
      final result = detectSubstantiveChanges(
        beforeHtml: fixture('dom_before.html'),
        afterHtml: fixture('dom_after_cosmetic.html'),
        registry: registry,
        ignoreClasses: const <String>{'decor-layer'},
      );

      expect(result.unmappedClasses, isEmpty);
      expect(result.dataWhenDiff.isEmpty, isTrue);
      expect(result.domSequenceDiff.isEmpty, isTrue);
      expect(result.hasSubstantiveChanges, isFalse);
    });
  });
}

String fixture(String name) {
  return File('test/sync/fixtures/$name').readAsStringSync();
}
