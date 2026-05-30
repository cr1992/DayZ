// DayZ design sync workflow.
//
// This file is intentionally a thin orchestration sketch. Workflow sandboxes do
// not provide filesystem, Node.js, or child-process APIs, so deterministic
// logic lives in bin/sync/*.dart and scripts/*.sh. Agents with Bash execute
// those commands and return structured reports.

const PHASE1_COMMAND = 'dart run bin/sync/route.dart --from-git-diff ui-design/current';
const PHASE2_COMMAND = 'dart run bin/sync/phase2_token.dart';
const PIN_CHECK_COMMAND = 'bash scripts/check_ui_sync.sh';

async function runDesignSync({ agent, changedFiles = [] }) {
  const phase1 = await agent({
    name: 'design-sync-phase1',
    prompt: [
      'Run Phase 1 for DayZ design sync.',
      `Changed files: ${JSON.stringify(changedFiles)}`,
      `Use Bash to execute: ${PHASE1_COMMAND}`,
      'Return the routed screens, component routes, token flag, and material-change flags.',
    ].join('\n'),
  });

  if (phase1.tokensChanged) {
    await agent({
      name: 'design-sync-phase2-token',
      prompt: [
        'Run Phase 2 token regeneration for DayZ design sync.',
        `Use Bash to execute: ${PHASE2_COMMAND}`,
        'Expected contrast failures are advisory. New unlisted regressions block the run.',
      ].join('\n'),
    });
  }

  if (phase1.materialChanges && phase1.materialChanges.length > 0) {
    return {
      status: 'needs-sync-card',
      materialChanges: phase1.materialChanges,
      note: 'Phase 3/4 implementation is deferred until the first screen widget harness exists.',
    };
  }

  return {
    status: 'phase1-complete',
    routedScreens: phase1.screens || [],
    routedComponents: phase1.components || [],
  };
}

async function checkPinnedScreens({ agent }) {
  return agent({
    name: 'design-sync-pinned-check',
    prompt: [
      'Check whether DayZ design screens are behind their pinned design commits.',
      `Use Bash to execute: ${PIN_CHECK_COMMAND}`,
      'Report any pending screen IDs and source paths.',
    ].join('\n'),
  });
}

module.exports = {
  runDesignSync,
  checkPinnedScreens,
};
