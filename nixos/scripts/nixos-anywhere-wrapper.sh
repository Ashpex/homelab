#!/usr/bin/env bash
set -euo pipefail

real_nixos_anywhere="${NIXIE_NIXOS_ANYWHERE:-}"

if [[ -z "$real_nixos_anywhere" ]]; then
  echo "NIXIE_NIXOS_ANYWHERE is not set" >&2
  exit 1
fi

args=()

if [[ -n "${NIXIE_EXTRA_FILES:-}" ]]; then
  if [[ ! -d "$NIXIE_EXTRA_FILES" ]]; then
    echo "NIXIE_EXTRA_FILES does not exist: $NIXIE_EXTRA_FILES" >&2
    echo "Run nixos/scripts/prepare-k3s-token first." >&2
    exit 1
  fi

  args+=(--extra-files "$NIXIE_EXTRA_FILES")
fi

exec "$real_nixos_anywhere" "${args[@]}" "$@"
