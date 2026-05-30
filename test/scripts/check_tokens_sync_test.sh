#!/bin/bash

# This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
# If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Setup temporary directory for fixtures
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Create three identical files
echo "body { color: red; }" > "$TMP_DIR/ds.css"
echo "body { color: red; }" > "$TMP_DIR/pages.css"
echo "body { color: red; }" > "$TMP_DIR/pk.css"

# Case 1: All files are synchronized (should exit 0)
./scripts/check_tokens_sync.sh "$TMP_DIR/ds.css" "$TMP_DIR/pages.css" "$TMP_DIR/pk.css" > /dev/null 2>&1
STATUS=$?
if [ $STATUS -ne 0 ]; then
  echo "FAIL: Expected exit code 0 when synchronized, but got $STATUS"
  exit 1
fi

# Case 2: Pages differs (should exit 2)
echo "body { color: blue; }" > "$TMP_DIR/pages.css"
OUTPUT=$(./scripts/check_tokens_sync.sh "$TMP_DIR/ds.css" "$TMP_DIR/pages.css" "$TMP_DIR/pk.css" 2>&1)
STATUS=$?
if [ $STATUS -ne 2 ]; then
  echo "FAIL: Expected exit code 2 when pages differs, but got $STATUS"
  exit 1
fi
if [[ "$OUTPUT" != *"pages.css differs"* ]]; then
  echo "FAIL: Expected stderr to mention pages.css, but got: $OUTPUT"
  exit 1
fi

# Restore pages
echo "body { color: red; }" > "$TMP_DIR/pages.css"

# Case 3: Prototype-kit differs (should exit 3)
echo "body { color: green; }" > "$TMP_DIR/pk.css"
OUTPUT=$(./scripts/check_tokens_sync.sh "$TMP_DIR/ds.css" "$TMP_DIR/pages.css" "$TMP_DIR/pk.css" 2>&1)
STATUS=$?
if [ $STATUS -ne 3 ]; then
  echo "FAIL: Expected exit code 3 when prototype-kit differs, but got $STATUS"
  exit 1
fi
if [[ "$OUTPUT" != *"pk.css differs"* ]]; then
  echo "FAIL: Expected stderr to mention pk.css, but got: $OUTPUT"
  exit 1
fi

echo "All check_tokens_sync.sh tests passed successfully!"
exit 0
