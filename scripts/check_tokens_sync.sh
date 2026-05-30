#!/bin/bash

# This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
# If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Define paths (override with arguments if provided)
DS_TOKENS="${1:-ui-design/current/design-system/assets/tokens.css}"
PAGES_TOKENS="${2:-ui-design/current/pages/assets/tokens.css}"
PK_TOKENS="${3:-ui-design/current/prototype-kit/assets/tokens.css}"

# Check if design-system tokens file exists
if [ ! -f "$DS_TOKENS" ]; then
  echo "Error: Design system tokens file not found: $DS_TOKENS" >&2
  exit 1
fi

# Check if pages tokens file exists
if [ ! -f "$PAGES_TOKENS" ]; then
  echo "Error: Pages tokens file not found: $PAGES_TOKENS" >&2
  exit 1
fi

# Check if prototype-kit tokens file exists
if [ ! -f "$PK_TOKENS" ]; then
  echo "Error: Prototype-kit tokens file not found: $PK_TOKENS" >&2
  exit 1
fi

# Compare design-system with pages
if ! diff -q "$DS_TOKENS" "$PAGES_TOKENS" >/dev/null 2>&1; then
  echo "Mismatch: $PAGES_TOKENS differs from $DS_TOKENS" >&2
  exit 2
fi

# Compare design-system with prototype-kit
if ! diff -q "$DS_TOKENS" "$PK_TOKENS" >/dev/null 2>&1; then
  echo "Mismatch: $PK_TOKENS differs from $DS_TOKENS" >&2
  exit 3
fi

echo "Tokens are synchronized."
exit 0
