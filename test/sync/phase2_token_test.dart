// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../bin/sync/phase2_token.dart';

void main() {
  group('Phase 2 token regen integration', () {
    late ContrastXfailRegistry xfails;

    setUpAll(() {
      final fixture = File('test/sync/fixtures/contrast_xfail_fixture.yaml');
      xfails = ContrastXfailRegistry.fromYaml(fixture.readAsStringSync());
    });

    test(
      'keeps the production xfail path as the machine-truth semantic path',
      () {
        expect(
          contrastXfailMachineTruthPath,
          'test/ui/theme/contrast_xfail.yaml',
        );
        expect(xfails.sourcePath, contrastXfailMachineTruthPath);

        expect(
          () => ContrastXfailRegistry.fromYaml(
            '',
            sourcePath: 'test/sync/fixtures/contrast_xfail_fixture.yaml',
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      'blocks immediately when check_tokens_sync reports source divergence',
      () {
        final result = evaluatePhase2Token(
          checkTokensSync: const Phase2StepResult.failed(
            Phase2Step.checkTokensSync,
            summary: 'pages tokens differ from design-system tokens',
          ),
          genTokens: _genPassed,
          themeRegression: const ThemeRegressionResult.passed(),
          contrastXfails: xfails,
        );

        expect(result.decision, Phase2Decision.block);
        expect(result.shouldContinue, isFalse);
        expect(result.stoppedAt, Phase2Step.checkTokensSync);
        expect(result.blockers.single.message, contains('pages tokens differ'));
      },
    );

    test('blocks immediately when gen_tokens reports generated drift', () {
      final result = evaluatePhase2Token(
        checkTokensSync: _checkSyncPassed,
        genTokens: const Phase2StepResult.failed(
          Phase2Step.genTokens,
          summary: 'dayz_tokens.g.dart drifted after regeneration',
        ),
        themeRegression: const ThemeRegressionResult.passed(),
        contrastXfails: xfails,
      );

      expect(result.decision, Phase2Decision.block);
      expect(result.shouldContinue, isFalse);
      expect(result.stoppedAt, Phase2Step.genTokens);
      expect(result.blockers.single.message, contains('drifted'));
    });

    test('blocks non-contrast theme regression failures', () {
      final result = evaluatePhase2Token(
        checkTokensSync: _checkSyncPassed,
        genTokens: _genPassed,
        themeRegression: const ThemeRegressionResult(
          nonContrastFailures: [
            'DayzColors.lerp no longer returns deterministic midpoint',
          ],
        ),
        contrastXfails: xfails,
      );

      expect(result.decision, Phase2Decision.block);
      expect(result.stoppedAt, Phase2Step.themeRegression);
      expect(
        result.blockers.single.message,
        contains('deterministic midpoint'),
      );
    });

    test('treats registered xfail contrast failures as advisory only', () {
      final result = evaluatePhase2Token(
        checkTokensSync: _checkSyncPassed,
        genTokens: _genPassed,
        themeRegression: const ThemeRegressionResult(
          contrastFailures: [
            ContrastFailure(
              theme: 'sageLight',
              foreground: 'onAccent',
              background: 'accent',
              actualRatio: 3.97,
              requiredRatio: 4.5,
            ),
            ContrastFailure(
              theme: 'amberLight',
              foreground: 'accent',
              background: 'bg',
              actualRatio: 2.43,
              requiredRatio: 3.0,
            ),
            ContrastFailure(
              theme: 'purpleLight',
              foreground: 'ink3',
              background: 'bg',
              actualRatio: 2.77,
              requiredRatio: 4.5,
            ),
          ],
        ),
        contrastXfails: xfails,
      );

      expect(result.decision, Phase2Decision.advisory);
      expect(result.shouldContinue, isTrue);
      expect(result.blockers, isEmpty);
      expect(result.advisories, hasLength(3));
      expect(
        result.advisories.map((issue) => issue.contrastFailure!.key.id),
        containsAll([
          'sageLight:onAccent:accent',
          'amberLight:accent:bg',
          'purpleLight:ink3:bg',
        ]),
      );
      expect(
        result.advisories
            .singleWhere(
              (issue) =>
                  issue.contrastFailure!.key.id == 'sageLight:onAccent:accent',
            )
            .message,
        contains(contrastXfailMachineTruthPath),
      );
    });

    test('blocks new contrast failures outside the xfail allowlist', () {
      final result = evaluatePhase2Token(
        checkTokensSync: _checkSyncPassed,
        genTokens: _genPassed,
        themeRegression: const ThemeRegressionResult(
          contrastFailures: [
            ContrastFailure(
              theme: 'purpleLight',
              foreground: 'ink',
              background: 'bg',
              actualRatio: 4.1,
              requiredRatio: 4.5,
            ),
          ],
        ),
        contrastXfails: xfails,
      );

      expect(result.decision, Phase2Decision.block);
      expect(result.shouldContinue, isFalse);
      expect(result.stoppedAt, Phase2Step.themeRegression);
      expect(result.advisories, isEmpty);
      expect(
        result.blockers.single.message,
        contains('new contrast regression outside xfail allowlist'),
      );
      expect(
        result.blockers.single.contrastFailure!.key.id,
        'purpleLight:ink:bg',
      );
    });

    test(
      'keeps xfail advisories visible even when another contrast failure blocks',
      () {
        final result = evaluatePhase2Token(
          checkTokensSync: _checkSyncPassed,
          genTokens: _genPassed,
          themeRegression: const ThemeRegressionResult(
            contrastFailures: [
              ContrastFailure(
                theme: 'sageLight',
                foreground: 'onAccent',
                background: 'accent',
                actualRatio: 3.97,
                requiredRatio: 4.5,
              ),
              ContrastFailure(
                theme: 'sageLight',
                foreground: 'ink',
                background: 'surface',
                actualRatio: 4.2,
                requiredRatio: 4.5,
              ),
            ],
          ),
          contrastXfails: xfails,
        );

        expect(result.decision, Phase2Decision.block);
        expect(
          result.advisories.single.contrastFailure!.key.id,
          'sageLight:onAccent:accent',
        );
        expect(
          result.blockers.single.contrastFailure!.key.id,
          'sageLight:ink:surface',
        );
      },
    );
  });
}

const _checkSyncPassed = Phase2StepResult.passed(Phase2Step.checkTokensSync);

const _genPassed = Phase2StepResult.passed(Phase2Step.genTokens);
