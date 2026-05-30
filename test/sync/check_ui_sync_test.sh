#!/bin/bash

# This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
# If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

git -C "$TMP_DIR" init -q
git -C "$TMP_DIR" config user.email "test@example.invalid"
git -C "$TMP_DIR" config user.name "Test"
mkdir -p "$TMP_DIR/ui-design/current/pages/screens" "$TMP_DIR/specs/active/design-sync-automation"

cat > "$TMP_DIR/ui-design/current/pages/screens/timeline.html" <<'HTML'
<main class="timeline">v1</main>
HTML
git -C "$TMP_DIR" add .
git -C "$TMP_DIR" commit -q -m "initial design"
BASE=$(git -C "$TMP_DIR" rev-parse HEAD)

cat > "$TMP_DIR/specs/active/design-sync-automation/screens.yaml" <<YAML
screens:
  - id: timeline
    pinned: $BASE
    lane: active
    map: test/ui/timeline/element-map.yaml
YAML
git -C "$TMP_DIR" add .
git -C "$TMP_DIR" commit -q -m "pin timeline"
PINNED_HEAD=$(git -C "$TMP_DIR" rev-parse HEAD)

OUTPUT=$(bash "$ROOT_DIR/scripts/check_ui_sync.sh" \
  --repo "$TMP_DIR" \
  --registry "$TMP_DIR/specs/active/design-sync-automation/screens.yaml" \
  --head "$PINNED_HEAD")
STATUS=$?
if [ "$STATUS" -ne 0 ]; then
  echo "FAIL: pinned=HEAD case should pass, got $STATUS"
  echo "$OUTPUT"
  exit 1
fi

cat > "$TMP_DIR/ui-design/current/pages/screens/timeline.html" <<'HTML'
<main class="timeline">v2</main>
HTML
git -C "$TMP_DIR" add .
git -C "$TMP_DIR" commit -q -m "update timeline design"
UPDATED_HEAD=$(git -C "$TMP_DIR" rev-parse HEAD)

set +e
OUTPUT=$(bash "$ROOT_DIR/scripts/check_ui_sync.sh" \
  --repo "$TMP_DIR" \
  --registry "$TMP_DIR/specs/active/design-sync-automation/screens.yaml" \
  --head "$UPDATED_HEAD" 2>&1)
STATUS=$?
set -e
if [ "$STATUS" -ne 1 ]; then
  echo "FAIL: stale pinned case should exit 1, got $STATUS"
  echo "$OUTPUT"
  exit 1
fi
if [[ "$OUTPUT" != *"timeline"* ]] || [[ "$OUTPUT" != *"ui-design/current/pages/screens/timeline.html"* ]]; then
  echo "FAIL: stale pinned output should mention timeline source path"
  echo "$OUTPUT"
  exit 1
fi

echo "check_ui_sync.sh tests passed."
