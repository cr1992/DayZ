#!/bin/bash

# This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
# If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

set -euo pipefail

REPO="${DAYZ_UI_SYNC_REPO:-$(pwd)}"
SCREENS_YAML="${DAYZ_UI_SYNC_SCREENS_YAML:-specs/active/design-sync-automation/screens.yaml}"
DESIGN_ROOT="${DAYZ_UI_SYNC_DESIGN_ROOT:-ui-design/current}"
HEAD_REF="${DAYZ_UI_SYNC_HEAD:-HEAD}"

if [ ! -f "$REPO/$SCREENS_YAML" ]; then
  echo "Error: screens registry not found: $SCREENS_YAML" >&2
  exit 2
fi

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

unquote() {
  local value="$1"
  value="$(trim "$value")"
  value="${value%\"}"
  value="${value#\"}"
  value="${value%\'}"
  value="${value#\'}"
  printf '%s' "$value"
}

pending=()
current_id=""
current_pinned=""

check_screen() {
  local id="$1"
  local pinned="$2"

  if [ -z "$id" ]; then
    return
  fi

  if [ -z "$pinned" ] || [ "$pinned" = "TODO" ] || [ "$pinned" = "null" ]; then
    pending+=("$id (missing pinned)")
    return
  fi

  local head_sha
  head_sha="$(git -C "$REPO" rev-parse "$HEAD_REF")"
  local pinned_sha="$pinned"
  if [ "$pinned" = "HEAD" ]; then
    pinned_sha="$head_sha"
  else
    if ! pinned_sha="$(git -C "$REPO" rev-parse "$pinned^{commit}" 2>/dev/null)"; then
      pending+=("$id (invalid pinned: $pinned)")
      return
    fi
  fi

  if [ "$pinned_sha" = "$head_sha" ]; then
    return
  fi

  local screen_path="$DESIGN_ROOT/pages/screens/$id.html"
  if git -C "$REPO" diff --quiet "$pinned_sha..$HEAD_REF" -- "$screen_path"; then
    return
  fi

  pending+=("$id ($screen_path)")
}

while IFS= read -r line || [ -n "$line" ]; do
  stripped="$(trim "$line")"
  case "$stripped" in
    "- id:"*)
      check_screen "$current_id" "$current_pinned"
      current_id="$(unquote "${stripped#- id:}")"
      current_pinned=""
      ;;
    "id:"*)
      current_id="$(unquote "${stripped#id:}")"
      ;;
    "pinned:"*)
      current_pinned="$(unquote "${stripped#pinned:}")"
      ;;
  esac
done <"$REPO/$SCREENS_YAML"
check_screen "$current_id" "$current_pinned"

if [ "${#pending[@]}" -gt 0 ]; then
  echo "待同步屏幕："
  printf ' - %s\n' "${pending[@]}"
  exit 1
fi

echo "UI sync registry is up to date."
