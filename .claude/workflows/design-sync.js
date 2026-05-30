// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

/**
 * Thin workflow shim for design-sync-automation.
 *
 * Deterministic logic intentionally lives in `bin/sync/*.dart`, because the
 * workflow runtime has no filesystem or child-process access. Agents with Bash
 * access should call the commands listed here and feed their outputs back into
 * the workflow report.
 */
export const phase1 = {
  route: 'dart bin/sync/route.dart <changed-files...>',
  scanHtml: 'dart bin/sync/detectors.dart scan-html <screen-html>',
};

export const phase2 = {
  plan: 'dart bin/sync/phase2_token.dart <changed-files...>',
  checkTokens: 'bash scripts/check_tokens_sync.sh',
  generateTokens: 'dart run bin/gen_tokens.dart',
  testTheme:
    'flutter test test/ui/theme/gen_tokens_test.dart test/ui/theme/dayz_theme_test.dart test/ui/theme/contrast_test.dart',
};
