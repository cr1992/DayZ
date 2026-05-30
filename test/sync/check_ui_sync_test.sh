#!/bin/bash

# This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
# If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

REPO="$TMP_DIR/repo"
mkdir -p "$REPO/ui-design/current/pages/screens"
mkdir -p "$REPO/specs/active/design-sync-automation"

cd "$REPO"
git init -q
git config user.name "DayZ Test"
git config user.email "test@example.com"

echo "<main>v1</main>" > ui-design/current/pages/screens/timeline.html
cat > specs/active/design-sync-automation/screens.yaml <<'YAML'
screens:
  - id: timeline
    pinned: HEAD
    lane: active
    map: test/ui/timeline/element-map.yaml
YAML
git add .
git commit -q -m "initial design"
BASE="$(git rev-parse HEAD)"

cat > specs/active/design-sync-automation/screens.yaml <<YAML
screens:
  - id: timeline
    pinned: $BASE
    lane: active
    map: test/ui/timeline/element-map.yaml
YAML
echo "<main>v2</main>" > ui-design/current/pages/screens/timeline.html
git add .
git commit -q -m "change timeline"

set +e
OUTPUT="$(
  DAYZ_UI_SYNC_REPO="$REPO" \
  bash "$ROOT/scripts/check_ui_sync.sh" 2>&1
)"
STATUS=$?
set -e

if [ "$STATUS" -ne 1 ]; then
  echo "Expected pending-sync exit code 1, got $STATUS" >&2
  echo "$OUTPUT" >&2
  exit 1
fi

if [[ "$OUTPUT" != *"timeline"* ]]; then
  echo "Expected output to mention timeline, got:" >&2
  echo "$OUTPUT" >&2
  exit 1
fi

HEAD_SHA="$(git rev-parse HEAD)"
cat > specs/active/design-sync-automation/screens.yaml <<YAML
screens:
  - id: timeline
    pinned: $HEAD_SHA
    lane: active
    map: test/ui/timeline/element-map.yaml
YAML

DAYZ_UI_SYNC_REPO="$REPO" bash "$ROOT/scripts/check_ui_sync.sh" >/dev/null
