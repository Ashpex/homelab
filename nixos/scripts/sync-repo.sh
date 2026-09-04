#!/usr/bin/env bash
set -euo pipefail

repo_url="${HOMELAB_REPO_URL:-https://github.com/Ashpex/homelab.git}"
repo_dir="${HOMELAB_REPO_DIR:-/home/ashpex/homelab}"
branch="${HOMELAB_REPO_BRANCH:-master}"

if [ -d "$repo_dir/.git" ]; then
  git -C "$repo_dir" fetch --prune origin
  git -C "$repo_dir" checkout "$branch"
  git -C "$repo_dir" pull --ff-only origin "$branch"
else
  if [ -e "$repo_dir" ]; then
    mv "$repo_dir" "${repo_dir}.snapshot.$(date +%s)"
  fi
  git clone --branch "$branch" "$repo_url" "$repo_dir"
fi
