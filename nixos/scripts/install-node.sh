#!/usr/bin/env bash
set -euo pipefail

NIX_CONFIG="${NIX_CONFIG:-experimental-features = nix-command flakes}"
export NIX_CONFIG

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  sudo_cmd=()
else
  sudo_cmd=(sudo)
fi

usage() {
  cat <<'EOF'
Usage:
  install-node.sh --host HOST --token-file PATH [--yes]

This script is intended to run from the NixOS installer.

It will:
  1. apply the host disko layout
  2. copy this repo into /mnt/opt/homelab
  3. install the k3s node token into the target system
  4. run nixos-install with the host flake output

WARNING: disko destroys existing data on the configured target disk.
EOF
}

host=""
token_file=""
assume_yes=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --host)
      host="${2:-}"
      shift 2
      ;;
    --token-file)
      token_file="${2:-}"
      shift 2
      ;;
    --yes)
      assume_yes=true
      shift
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

if [ -z "$host" ] || [ -z "$token_file" ]; then
  usage >&2
  exit 2
fi

if [ ! -f "$token_file" ]; then
  echo "Token file does not exist: $token_file" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nixos_dir="$(cd "$script_dir/.." && pwd)"
repo_root="$(cd "$nixos_dir/.." && pwd)"
target_repo="/mnt/opt/homelab"
target_flake="$target_repo/nixos#$host"

echo "Host: $host"
echo "Repo: $repo_root"
echo
echo "Detected block devices:"
lsblk
echo

if [ "$assume_yes" != true ]; then
  echo "This will repartition and format the disk configured for '$host'."
  printf "Type '%s' to continue: " "$host"
  read -r confirmation
  if [ "$confirmation" != "$host" ]; then
    echo "Aborted."
    exit 1
  fi
fi

"${sudo_cmd[@]}" env NIX_CONFIG="$NIX_CONFIG" nix run "$nixos_dir#disko" -- \
  --mode disko \
  --flake "$nixos_dir#$host"

"${sudo_cmd[@]}" install -d -m 0775 -g wheel "$target_repo"
tar --exclude='.git' -C "$repo_root" -cf - . | "${sudo_cmd[@]}" tar -C "$target_repo" -xf -
"${sudo_cmd[@]}" chgrp -R wheel "$target_repo"
"${sudo_cmd[@]}" chmod -R g+rwX "$target_repo"

"${sudo_cmd[@]}" install -d -m 0700 /mnt/etc/rancher/k3s
"${sudo_cmd[@]}" install -m 0600 "$token_file" /mnt/etc/rancher/k3s/node-token

"${sudo_cmd[@]}" env NIX_CONFIG="$NIX_CONFIG" nixos-install --flake "$target_flake"
