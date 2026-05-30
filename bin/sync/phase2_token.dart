// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';
import 'dart:io';

const String contrastXfailMachineTruthPath =
    'test/ui/theme/contrast_xfail.yaml';

enum Phase2Decision { pass, advisory, block }

enum Phase2IssueSeverity { advisory, block }

enum Phase2Step { checkTokensSync, genTokens, themeRegression }

extension Phase2StepLabel on Phase2Step {
  String get label {
    switch (this) {
      case Phase2Step.checkTokensSync:
        return 'check_tokens_sync';
      case Phase2Step.genTokens:
        return 'gen_tokens';
      case Phase2Step.themeRegression:
        return 'theme_regression';
    }
  }
}

final class Phase2StepResult {
  const Phase2StepResult({
    required this.step,
    required this.succeeded,
    this.summary = '',
    this.diagnostics = const [],
  });

  const Phase2StepResult.passed(
    Phase2Step step, {
    String summary = '',
    List<String> diagnostics = const [],
  }) : this(
         step: step,
         succeeded: true,
         summary: summary,
         diagnostics: diagnostics,
       );

  const Phase2StepResult.failed(
    Phase2Step step, {
    required String summary,
    List<String> diagnostics = const [],
  }) : this(
         step: step,
         succeeded: false,
         summary: summary,
         diagnostics: diagnostics,
       );

  final Phase2Step step;
  final bool succeeded;
  final String summary;
  final List<String> diagnostics;
}

final class ContrastKey {
  const ContrastKey({
    required this.theme,
    required this.foreground,
    required this.background,
  });

  final String theme;
  final String foreground;
  final String background;

  String get id => '$theme:$foreground:$background';

  @override
  bool operator ==(Object other) {
    return other is ContrastKey &&
        theme == other.theme &&
        foreground == other.foreground &&
        background == other.background;
  }

  @override
  int get hashCode => Object.hash(theme, foreground, background);

  @override
  String toString() => id;
}

final class ContrastFailure {
  const ContrastFailure({
    required this.theme,
    required this.foreground,
    required this.background,
    this.actualRatio,
    this.requiredRatio,
    this.details = '',
  });

  ContrastKey get key =>
      ContrastKey(theme: theme, foreground: foreground, background: background);

  final String theme;
  final String foreground;
  final String background;
  final double? actualRatio;
  final double? requiredRatio;
  final String details;
}

final class ContrastXfailCase {
  const ContrastXfailCase({
    required this.theme,
    required this.foreground,
    required this.background,
    required this.reason,
  });

  ContrastKey get key =>
      ContrastKey(theme: theme, foreground: foreground, background: background);

  final String theme;
  final String foreground;
  final String background;
  final String reason;
}

final class ContrastXfailRegistry {
  const ContrastXfailRegistry._({
    required this.sourcePath,
    required Map<ContrastKey, ContrastXfailCase> xfailCases,
  }) : _cases = xfailCases;

  factory ContrastXfailRegistry.fromYaml(
    String yamlContent, {
    String sourcePath = contrastXfailMachineTruthPath,
  }) {
    if (sourcePath != contrastXfailMachineTruthPath) {
      throw ArgumentError.value(
        sourcePath,
        'sourcePath',
        'contrast xfail machine truth must remain '
            '$contrastXfailMachineTruthPath',
      );
    }

    final parsed = <ContrastKey, ContrastXfailCase>{};
    final records = _parseTopLevelYamlRecords(yamlContent);
    for (final record in records) {
      final theme = record['theme'];
      final foreground = record['foreground'];
      final background = record['background'];
      if (theme == null || foreground == null || background == null) {
        throw FormatException(
          'contrast xfail entry must include theme, foreground, background: '
          '$record',
        );
      }

      final xfail = ContrastXfailCase(
        theme: theme,
        foreground: foreground,
        background: background,
        reason: record['reason'] ?? '',
      );
      if (parsed.containsKey(xfail.key)) {
        throw FormatException('duplicate contrast xfail entry: ${xfail.key}');
      }
      parsed[xfail.key] = xfail;
    }

    return ContrastXfailRegistry._(
      sourcePath: sourcePath,
      xfailCases: Map.unmodifiable(parsed),
    );
  }

  final String sourcePath;
  final Map<ContrastKey, ContrastXfailCase> _cases;

  List<ContrastXfailCase> get cases => List.unmodifiable(_cases.values);

  ContrastXfailCase? match(ContrastFailure failure) => _cases[failure.key];

  bool contains(ContrastFailure failure) => match(failure) != null;
}

final class ThemeRegressionResult {
  const ThemeRegressionResult({
    this.harnessSucceeded = true,
    this.summary = '',
    this.nonContrastFailures = const [],
    this.contrastFailures = const [],
  });

  const ThemeRegressionResult.passed() : this(harnessSucceeded: true);

  const ThemeRegressionResult.harnessFailed({
    required String summary,
    List<String> diagnostics = const [],
  }) : this(
         harnessSucceeded: false,
         summary: summary,
         nonContrastFailures: diagnostics,
       );

  final bool harnessSucceeded;
  final String summary;
  final List<String> nonContrastFailures;
  final List<ContrastFailure> contrastFailures;
}

final class Phase2Issue {
  const Phase2Issue({
    required this.severity,
    required this.step,
    required this.message,
    this.contrastFailure,
    this.matchedXfail,
  });

  final Phase2IssueSeverity severity;
  final Phase2Step step;
  final String message;
  final ContrastFailure? contrastFailure;
  final ContrastXfailCase? matchedXfail;
}

final class Phase2TokenResult {
  const Phase2TokenResult({
    required this.decision,
    required this.blockers,
    required this.advisories,
    this.stoppedAt,
  });

  final Phase2Decision decision;
  final List<Phase2Issue> blockers;
  final List<Phase2Issue> advisories;
  final Phase2Step? stoppedAt;

  bool get shouldContinue => decision != Phase2Decision.block;

  bool get hasAdvisories => advisories.isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'decision': decision.name,
    'stoppedAt': stoppedAt?.label,
    'blockers': blockers.map((issue) => issue.toJson()).toList(),
    'advisories': advisories.map((issue) => issue.toJson()).toList(),
  };
}

void main(List<String> args) {
  if (args.contains('-h') || args.contains('--help')) {
    stdout.writeln(
      'Usage: dart run bin/sync/phase2_token.dart [phase2-report.json]',
    );
    stdout.writeln(
      'Evaluates Phase 2 step results and contrast failures. '
      'The xfail allowlist source is fixed at $contrastXfailMachineTruthPath.',
    );
    return;
  }

  final positionalArgs = args.where((arg) => !arg.startsWith('-')).toList();
  final reportPath = positionalArgs.isEmpty ? null : positionalArgs.first;
  final report = reportPath == null
      ? const <String, Object?>{}
      : jsonDecode(File(reportPath).readAsStringSync()) as Map<String, Object?>;

  final xfailFile = File(contrastXfailMachineTruthPath);
  if (!xfailFile.existsSync()) {
    stderr.writeln('Missing contrast xfail allowlist: $xfailFile');
    exitCode = 2;
    return;
  }

  final result = evaluatePhase2Token(
    checkTokensSync: _stepResultFromReport(
      report,
      'checkTokensSync',
      Phase2Step.checkTokensSync,
    ),
    genTokens: _stepResultFromReport(report, 'genTokens', Phase2Step.genTokens),
    themeRegression: _themeRegressionFromReport(report['themeRegression']),
    contrastXfails: ContrastXfailRegistry.fromYaml(
      xfailFile.readAsStringSync(),
    ),
  );

  stdout.writeln(const JsonEncoder.withIndent('  ').convert(result.toJson()));
  if (result.decision == Phase2Decision.block) {
    exitCode = 1;
  }
}

Phase2TokenResult evaluatePhase2Token({
  required Phase2StepResult checkTokensSync,
  required Phase2StepResult genTokens,
  required ThemeRegressionResult themeRegression,
  required ContrastXfailRegistry contrastXfails,
}) {
  _expectStep(checkTokensSync, Phase2Step.checkTokensSync);
  _expectStep(genTokens, Phase2Step.genTokens);

  if (!checkTokensSync.succeeded) {
    return _blockedAt(
      Phase2Step.checkTokensSync,
      _stepFailureIssue(checkTokensSync),
    );
  }

  if (!genTokens.succeeded) {
    return _blockedAt(Phase2Step.genTokens, _stepFailureIssue(genTokens));
  }

  final blockers = <Phase2Issue>[];
  final advisories = <Phase2Issue>[];

  if (!themeRegression.harnessSucceeded) {
    blockers.add(
      Phase2Issue(
        severity: Phase2IssueSeverity.block,
        step: Phase2Step.themeRegression,
        message: themeRegression.summary.isEmpty
            ? 'theme regression harness failed'
            : themeRegression.summary,
      ),
    );
  }

  for (final failure in themeRegression.nonContrastFailures) {
    blockers.add(
      Phase2Issue(
        severity: Phase2IssueSeverity.block,
        step: Phase2Step.themeRegression,
        message: failure,
      ),
    );
  }

  for (final failure in themeRegression.contrastFailures) {
    final matchedXfail = contrastXfails.match(failure);
    if (matchedXfail == null) {
      blockers.add(
        Phase2Issue(
          severity: Phase2IssueSeverity.block,
          step: Phase2Step.themeRegression,
          message: _newContrastRegressionMessage(failure),
          contrastFailure: failure,
        ),
      );
      continue;
    }

    advisories.add(
      Phase2Issue(
        severity: Phase2IssueSeverity.advisory,
        step: Phase2Step.themeRegression,
        message: _xfailAdvisoryMessage(failure, matchedXfail),
        contrastFailure: failure,
        matchedXfail: matchedXfail,
      ),
    );
  }

  if (blockers.isNotEmpty) {
    return Phase2TokenResult(
      decision: Phase2Decision.block,
      blockers: List.unmodifiable(blockers),
      advisories: List.unmodifiable(advisories),
      stoppedAt: Phase2Step.themeRegression,
    );
  }

  if (advisories.isNotEmpty) {
    return Phase2TokenResult(
      decision: Phase2Decision.advisory,
      blockers: const [],
      advisories: List.unmodifiable(advisories),
    );
  }

  return const Phase2TokenResult(
    decision: Phase2Decision.pass,
    blockers: [],
    advisories: [],
  );
}

void _expectStep(Phase2StepResult result, Phase2Step expected) {
  if (result.step != expected) {
    throw ArgumentError.value(
      result.step,
      'result.step',
      'expected ${expected.label}',
    );
  }
}

Phase2TokenResult _blockedAt(Phase2Step step, Phase2Issue issue) {
  return Phase2TokenResult(
    decision: Phase2Decision.block,
    blockers: [issue],
    advisories: const [],
    stoppedAt: step,
  );
}

Phase2Issue _stepFailureIssue(Phase2StepResult result) {
  return Phase2Issue(
    severity: Phase2IssueSeverity.block,
    step: result.step,
    message: result.summary.isEmpty
        ? '${result.step.label} failed'
        : result.summary,
  );
}

Phase2StepResult _stepResultFromReport(
  Map<String, Object?> report,
  String key,
  Phase2Step step,
) {
  final raw = report[key];
  if (raw == null) {
    return Phase2StepResult.passed(step);
  }
  if (raw is! Map<String, Object?>) {
    throw FormatException('Phase 2 step report must be an object: $key');
  }

  final succeeded = raw['succeeded'];
  final summary = raw['summary']?.toString() ?? '';
  if (succeeded == false) {
    return Phase2StepResult.failed(step, summary: summary);
  }
  return Phase2StepResult.passed(step, summary: summary);
}

ThemeRegressionResult _themeRegressionFromReport(Object? raw) {
  if (raw == null) {
    return const ThemeRegressionResult.passed();
  }
  if (raw is! Map<String, Object?>) {
    throw const FormatException('themeRegression report must be an object');
  }

  final nonContrastFailures = <String>[
    for (final item in (raw['nonContrastFailures'] as List<Object?>? ?? []))
      item.toString(),
  ];
  final contrastFailures = <ContrastFailure>[
    for (final item in (raw['contrastFailures'] as List<Object?>? ?? []))
      _contrastFailureFromJson(item),
  ];

  final harnessSucceeded = raw['harnessSucceeded'];
  return ThemeRegressionResult(
    harnessSucceeded: harnessSucceeded is bool ? harnessSucceeded : true,
    summary: raw['summary']?.toString() ?? '',
    nonContrastFailures: nonContrastFailures,
    contrastFailures: contrastFailures,
  );
}

ContrastFailure _contrastFailureFromJson(Object? raw) {
  if (raw is! Map<String, Object?>) {
    throw const FormatException('contrast failure report must be an object');
  }
  return ContrastFailure(
    theme: raw['theme']?.toString() ?? '',
    foreground: raw['foreground']?.toString() ?? '',
    background: raw['background']?.toString() ?? '',
    actualRatio: _optionalDouble(raw['actualRatio']),
    requiredRatio: _optionalDouble(raw['requiredRatio']),
    details: raw['details']?.toString() ?? '',
  );
}

double? _optionalDouble(Object? raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw.toString());
}

extension on Phase2Issue {
  Map<String, Object?> toJson() => <String, Object?>{
    'severity': severity.name,
    'step': step.label,
    'message': message,
    'contrast': contrastFailure?.key.id,
    'matchedXfail': matchedXfail?.reason,
  };
}

String _newContrastRegressionMessage(ContrastFailure failure) {
  final ratio = _ratioSuffix(failure);
  return 'new contrast regression outside xfail allowlist: '
      '${failure.key}$ratio';
}

String _xfailAdvisoryMessage(
  ContrastFailure failure,
  ContrastXfailCase matchedXfail,
) {
  final ratio = _ratioSuffix(failure);
  final reason = matchedXfail.reason.isEmpty
      ? ''
      : '; reason: ${matchedXfail.reason}';
  return 'expected contrast failure allowed by '
      '$contrastXfailMachineTruthPath: ${failure.key}$ratio$reason';
}

String _ratioSuffix(ContrastFailure failure) {
  final actual = failure.actualRatio;
  final required = failure.requiredRatio;
  if (actual == null || required == null) {
    return '';
  }
  return ' (${actual.toStringAsFixed(2)} < ${required.toStringAsFixed(2)})';
}

List<Map<String, String>> _parseTopLevelYamlRecords(String content) {
  final records = <Map<String, String>>[];
  var current = <String, String>{};

  void saveCurrent() {
    if (current.isNotEmpty) {
      records.add(current);
      current = <String, String>{};
    }
  }

  for (final rawLine in content.split('\n')) {
    var line = _stripYamlComment(rawLine).trim();
    if (line.isEmpty) {
      continue;
    }

    if (line.startsWith('-')) {
      saveCurrent();
      line = line.substring(1).trim();
      if (line.isEmpty) {
        continue;
      }
    }

    final colon = line.indexOf(':');
    if (colon <= 0) {
      throw FormatException('unsupported contrast xfail yaml line: $rawLine');
    }

    final key = line.substring(0, colon).trim();
    final value = line.substring(colon + 1).trim();
    current[key] = _unquoteYamlScalar(value);
  }

  saveCurrent();
  return records;
}

String _stripYamlComment(String line) {
  var inSingleQuote = false;
  var inDoubleQuote = false;

  for (var index = 0; index < line.length; index += 1) {
    final char = line[index];
    if (char == "'" && !inDoubleQuote) {
      inSingleQuote = !inSingleQuote;
      continue;
    }
    if (char == '"' && !inSingleQuote) {
      inDoubleQuote = !inDoubleQuote;
      continue;
    }
    if (char == '#' && !inSingleQuote && !inDoubleQuote) {
      return line.substring(0, index);
    }
  }

  return line;
}

String _unquoteYamlScalar(String value) {
  if (value.length >= 2) {
    final first = value[0];
    final last = value[value.length - 1];
    if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
      return value.substring(1, value.length - 1);
    }
  }
  return value;
}
