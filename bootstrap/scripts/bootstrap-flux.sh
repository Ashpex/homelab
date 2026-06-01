#!/usr/bin/env sh
set -eu

if ! command -v flux >/dev/null 2>&1; then
  echo "flux CLI is required. Install it first: https://fluxcd.io/flux/installation/" >&2
  exit 1
fi

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
repo_root=$(CDPATH= cd "${script_dir}/../.." && pwd)

flux install

kubectl apply -f "${repo_root}/flux/gitrepository.yaml"
kubectl apply -f "${repo_root}/flux/kustomization.yaml"
