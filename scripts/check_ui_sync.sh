#!/bin/bash

# This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
# If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/check_ui_sync.sh [--registry PATH] [--repo PATH] [--head REF]

Checks specs/active/design-sync-automation/screens.yaml for screens whose
pinned design commit is behind HEAD and whose source screen changed.

Exit codes:
  0  all pinned screens are current, or only unpinned placeholders exist
  1  one or more screens need sync
  2  invalid input or git failure
USAGE
}

REGISTRY="specs/active/design-sync-automation/screens.yaml"
REPO="."
HEAD_REF="HEAD"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --registry)
      REGISTRY="${2:-}"
      shift 2
      ;;
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --head)
      HEAD_REF="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ ! -f "$REGISTRY" ]; then
  echo "screens registry not found: $REGISTRY" >&2
  exit 2
fi

if ! git -C "$REPO" rev-parse --verify "$HEAD_REF^{commit}" >/dev/null 2>&1; then
  echo "invalid head ref: $HEAD_REF" >&2
  exit 2
fi

screen_ids=()
pinned_refs=()

current_id=""
current_pinned=""

flush_entry() {
  if [ -n "$current_id" ]; then
    screen_ids+=("$current_id")
    pinned_refs+=("$current_pinned")
  fi
  current_id=""
  current_pinned=""
}

while IFS= read -r raw_line || [ -n "$raw_line" ]; do
  line="${raw_line%%#*}"
  line="${line%"${line##*[![:space:]]}"}"
  trimmed="${line#"${line%%[![:space:]]*}"}"

  if [[ "$trimmed" =~ ^-\ id:[[:space:]]*(.+)$ ]]; then
    flush_entry
    current_id="${BASH_REMATCH[1]}"
    current_id="${current_id%\"}"
    current_id="${current_id#\"}"
  elif [[ "$trimmed" =~ ^id:[[:space:]]*(.+)$ ]]; then
    current_id="${BASH_REMATCH[1]}"
    current_id="${current_id%\"}"
    current_id="${current_id#\"}"
  elif [[ "$trimmed" =~ ^pinned:[[:space:]]*(.*)$ ]]; then
    current_pinned="${BASH_REMATCH[1]}"
    current_pinned="${current_pinned%\"}"
    current_pinned="${current_pinned#\"}"
  fi
done < "$REGISTRY"
flush_entry

if [ "${#screen_ids[@]}" -eq 0 ]; then
  echo "no screens found in registry: $REGISTRY" >&2
  exit 2
fi

needs_sync=()

for i in "${!screen_ids[@]}"; do
  id="${screen_ids[$i]}"
  pinned="${pinned_refs[$i]}"
  source_path="ui-design/current/pages/screens/$id.html"

  if [ -z "$pinned" ] || [ "$pinned" = "null" ] || [[ "$pinned" = TODO* ]]; then
    continue
  fi

  if ! git -C "$REPO" rev-parse --verify "$pinned^{commit}" >/dev/null 2>&1; then
    echo "invalid pinned ref for $id: $pinned" >&2
    exit 2
  fi

  if [ "$(git -C "$REPO" rev-parse "$pinned^{commit}")" = "$(git -C "$REPO" rev-parse "$HEAD_REF^{commit}")" ]; then
    continue
  fi

  if git -C "$REPO" diff --quiet "$pinned" "$HEAD_REF" -- "$source_path"; then
    continue
  fi

  needs_sync+=("$id $pinned..$HEAD_REF $source_path")
done

if [ "${#needs_sync[@]}" -eq 0 ]; then
  echo "UI design sync check passed."
  exit 0
fi

echo "UI design screens pending sync:"
printf '  %s\n' "${needs_sync[@]}"
exit 1
