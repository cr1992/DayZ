// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter_test/flutter_test.dart';

import '../../bin/sync/phase2_token.dart';

void main() {
  const tokenFile = 'ui-design/current/design-system/assets/tokens.css';
  const passingSteps = <Phase2StepOutcome>[
    Phase2StepOutcome(step: Phase2Step.checkTokensSync, passed: true),
    Phase2StepOutcome(step: Phase2Step.generateTokens, passed: true),
    Phase2StepOutcome(step: Phase2Step.tokenDrift, passed: true),
    Phase2StepOutcome(step: Phase2Step.themeRegression, passed: true),
  ];

  group('Phase 2 token pipeline decision', () {
    test('skips when tokens.css is not changed', () {
      final report = evaluatePhase2Token(
        changedFiles: const <String>[
          'ui-design/current/pages/screens/timeline.html',
        ],
        stepOutcomes: passingSteps,
        contrastFailures: const <ContrastFailure>[],
        xfailAllowlist: const <ContrastXFailCase>[],
      );

      expect(report.status, Phase2TokenStatus.skipped);
      expect(report.commands, isEmpty);
    });

    test('blocks on check_tokens_sync source divergence', () {
      final report = evaluatePhase2Token(
        changedFiles: const <String>[tokenFile],
        stepOutcomes: const <Phase2StepOutcome>[
          Phase2StepOutcome(
            step: Phase2Step.checkTokensSync,
            passed: false,
            message: 'pages/assets/tokens.css differs',
          ),
          Phase2StepOutcome(step: Phase2Step.generateTokens, passed: true),
        ],
        contrastFailures: const <ContrastFailure>[],
        xfailAllowlist: const <ContrastXFailCase>[],
      );

      expect(report.status, Phase2TokenStatus.block);
      expect(report.blockedStep, Phase2Step.checkTokensSync);
      expect(report.shouldContinue, isFalse);
    });

    test('blocks on generated token drift', () {
      final report = evaluatePhase2Token(
        changedFiles: const <String>[tokenFile],
        stepOutcomes: const <Phase2StepOutcome>[
          Phase2StepOutcome(step: Phase2Step.checkTokensSync, passed: true),
          Phase2StepOutcome(step: Phase2Step.generateTokens, passed: true),
          Phase2StepOutcome(
            step: Phase2Step.tokenDrift,
            passed: false,
            message: 'dayz_tokens.g.dart changed after generation',
          ),
        ],
        contrastFailures: const <ContrastFailure>[],
        xfailAllowlist: const <ContrastXFailCase>[],
      );

      expect(report.status, Phase2TokenStatus.block);
      expect(report.blockedStep, Phase2Step.tokenDrift);
    });

    test('xfail contrast failures are advisory and do not wedge', () {
      final allowlist = parseContrastXFailYaml('''
- theme: sageLight
  foreground: onAccent
  background: accent
  reason: "known"
- theme: amberLight
  foreground: accent
  background: bg
  reason: "known"
- theme: purpleLight
  foreground: ink3
  background: surface
  reason: "known"
''');
      final report = evaluatePhase2Token(
        changedFiles: const <String>[tokenFile],
        stepOutcomes: passingSteps,
        contrastFailures: const <ContrastFailure>[
          ContrastFailure(
            theme: 'sageLight',
            foreground: 'onAccent',
            background: 'accent',
            ratio: 3.97,
            requiredRatio: 4.5,
          ),
          ContrastFailure(
            theme: 'amberLight',
            foreground: 'accent',
            background: 'bg',
            ratio: 2.43,
            requiredRatio: 3.0,
          ),
          ContrastFailure(
            theme: 'purpleLight',
            foreground: 'ink3',
            background: 'surface',
            ratio: 2.97,
            requiredRatio: 4.5,
          ),
        ],
        xfailAllowlist: allowlist,
      );

      expect(report.status, Phase2TokenStatus.advisory);
      expect(report.advisoryContrastFailures, hasLength(3));
      expect(report.blockingContrastFailures, isEmpty);
      expect(report.shouldContinue, isTrue);
    });

    test('allowlist-external contrast failure blocks', () {
      final allowlist = parseContrastXFailYaml('''
- theme: sageLight
  foreground: onAccent
  background: accent
  reason: "known"
''');
      final report = evaluatePhase2Token(
        changedFiles: const <String>[tokenFile],
        stepOutcomes: passingSteps,
        contrastFailures: const <ContrastFailure>[
          ContrastFailure(
            theme: 'purpleDark',
            foreground: 'ink',
            background: 'bg',
            ratio: 2.0,
            requiredRatio: 4.5,
          ),
        ],
        xfailAllowlist: allowlist,
      );

      expect(report.status, Phase2TokenStatus.block);
      expect(report.blockingContrastFailures.single.theme, 'purpleDark');
      expect(report.shouldContinue, isFalse);
    });

    test('emits deterministic command plan for token changes', () {
      final report = evaluatePhase2Token(
        changedFiles: const <String>[tokenFile],
        stepOutcomes: passingSteps,
        contrastFailures: const <ContrastFailure>[],
        xfailAllowlist: const <ContrastXFailCase>[],
      );

      expect(report.status, Phase2TokenStatus.pass);
      expect(report.commands, phase2TokenCommands);
    });
  });
}
