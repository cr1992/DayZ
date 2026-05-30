// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';
import 'dart:io';

import 'route.dart';

enum Phase2Step { checkTokensSync, generateTokens, tokenDrift, themeRegression }

enum Phase2TokenStatus { skipped, pass, advisory, block }

class Phase2StepOutcome {
  const Phase2StepOutcome({
    required this.step,
    required this.passed,
    this.message = '',
  });

  final Phase2Step step;
  final bool passed;
  final String message;
}

class ContrastFailure {
  const ContrastFailure({
    required this.theme,
    required this.foreground,
    required this.background,
    required this.ratio,
    required this.requiredRatio,
  });

  final String theme;
  final String foreground;
  final String background;
  final double ratio;
  final double requiredRatio;

  String get key => contrastKey(theme, foreground, background);

  Map<String, Object> toJson() => <String, Object>{
    'theme': theme,
    'foreground': foreground,
    'background': background,
    'ratio': ratio,
    'requiredRatio': requiredRatio,
  };
}

class ContrastXFailCase {
  const ContrastXFailCase({
    required this.theme,
    required this.foreground,
    required this.background,
    this.reason = '',
  });

  final String theme;
  final String foreground;
  final String background;
  final String reason;

  String get key => contrastKey(theme, foreground, background);
}

class Phase2TokenReport {
  const Phase2TokenReport({
    required this.status,
    required this.commands,
    this.blockedStep,
    this.blockedMessage,
    this.advisoryContrastFailures = const <ContrastFailure>[],
    this.blockingContrastFailures = const <ContrastFailure>[],
  });

  final Phase2TokenStatus status;
  final List<String> commands;
  final Phase2Step? blockedStep;
  final String? blockedMessage;
  final List<ContrastFailure> advisoryContrastFailures;
  final List<ContrastFailure> blockingContrastFailures;

  bool get shouldContinue =>
      status == Phase2TokenStatus.pass || status == Phase2TokenStatus.advisory;

  Map<String, Object?> toJson() => <String, Object?>{
    'status': status.name,
    'commands': commands,
    'blockedStep': blockedStep?.name,
    'blockedMessage': blockedMessage,
    'advisoryContrastFailures': advisoryContrastFailures
        .map((failure) => failure.toJson())
        .toList(),
    'blockingContrastFailures': blockingContrastFailures
        .map((failure) => failure.toJson())
        .toList(),
  };
}

const phase2TokenCommands = <String>[
  'bash scripts/check_tokens_sync.sh',
  'dart run bin/gen_tokens.dart',
  'flutter test test/ui/theme/gen_tokens_test.dart test/ui/theme/dayz_theme_test.dart test/ui/theme/contrast_test.dart',
];

Phase2TokenReport evaluatePhase2Token({
  required Iterable<String> changedFiles,
  required Iterable<Phase2StepOutcome> stepOutcomes,
  required Iterable<ContrastFailure> contrastFailures,
  required Iterable<ContrastXFailCase> xfailAllowlist,
}) {
  final routed = routeDesignChanges(changedFiles);
  if (!routed.tokenChanged) {
    return const Phase2TokenReport(
      status: Phase2TokenStatus.skipped,
      commands: <String>[],
    );
  }

  for (final outcome in stepOutcomes) {
    if (!outcome.passed) {
      return Phase2TokenReport(
        status: Phase2TokenStatus.block,
        commands: phase2TokenCommands,
        blockedStep: outcome.step,
        blockedMessage: outcome.message,
      );
    }
  }

  final allowlistKeys = xfailAllowlist.map((entry) => entry.key).toSet();
  final advisory = <ContrastFailure>[];
  final blocking = <ContrastFailure>[];
  for (final failure in contrastFailures) {
    if (allowlistKeys.contains(failure.key)) {
      advisory.add(failure);
    } else {
      blocking.add(failure);
    }
  }

  if (blocking.isNotEmpty) {
    return Phase2TokenReport(
      status: Phase2TokenStatus.block,
      commands: phase2TokenCommands,
      blockingContrastFailures: blocking,
      advisoryContrastFailures: advisory,
    );
  }

  if (advisory.isNotEmpty) {
    return Phase2TokenReport(
      status: Phase2TokenStatus.advisory,
      commands: phase2TokenCommands,
      advisoryContrastFailures: advisory,
    );
  }

  return const Phase2TokenReport(
    status: Phase2TokenStatus.pass,
    commands: phase2TokenCommands,
  );
}

List<ContrastXFailCase> parseContrastXFailYaml(String content) {
  final cases = <ContrastXFailCase>[];
  String? theme;
  String? foreground;
  String? background;
  String? reason;

  void saveCurrent() {
    if (theme != null && foreground != null && background != null) {
      cases.add(
        ContrastXFailCase(
          theme: theme,
          foreground: foreground,
          background: background,
          reason: reason ?? '',
        ),
      );
    }
  }

  for (var line in const LineSplitter().convert(content)) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }

    if (line.startsWith('-')) {
      saveCurrent();
      theme = null;
      foreground = null;
      background = null;
      reason = null;
      line = line.substring(1).trim();
      if (line.isEmpty) {
        continue;
      }
    }

    final colon = line.indexOf(':');
    if (colon == -1) {
      continue;
    }
    final key = line.substring(0, colon).trim();
    final value = _unquote(line.substring(colon + 1).trim());

    switch (key) {
      case 'theme':
        theme = value;
      case 'foreground':
        foreground = value;
      case 'background':
        background = value;
      case 'reason':
        reason = value;
    }
  }
  saveCurrent();

  return cases;
}

String contrastKey(String theme, String foreground, String background) {
  return '$theme::$foreground::$background';
}

String _unquote(String value) {
  if (value.length >= 2) {
    final first = value.codeUnitAt(0);
    final last = value.codeUnitAt(value.length - 1);
    if ((first == 0x22 && last == 0x22) || (first == 0x27 && last == 0x27)) {
      return value.substring(1, value.length - 1);
    }
  }
  return value;
}

void main(List<String> args) {
  final report = evaluatePhase2Token(
    changedFiles: args,
    stepOutcomes: const <Phase2StepOutcome>[
      Phase2StepOutcome(step: Phase2Step.checkTokensSync, passed: true),
      Phase2StepOutcome(step: Phase2Step.generateTokens, passed: true),
      Phase2StepOutcome(step: Phase2Step.tokenDrift, passed: true),
      Phase2StepOutcome(step: Phase2Step.themeRegression, passed: true),
    ],
    contrastFailures: const <ContrastFailure>[],
    xfailAllowlist: const <ContrastXFailCase>[],
  );
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report.toJson()));
}
