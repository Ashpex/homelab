# Homelab

K3s, Flux Helm controller, and Pulumi IaC for the home server.

Server dashboard: [hub.ashpex.net](https://hub.ashpex.net)

<img width="948" height="629" alt="Screenshot 2026-06-04 at 6 02 37 PM" src="https://github.com/user-attachments/assets/c998d0d0-6e74-4694-883a-5e7508cbbfa5" />


## Layout

- `bootstrap/`: host bootstrap and Flux bootstrap.
- `flux/`: Flux GitRepository source.
- `platform/`: platform Helm charts and HelmReleases.
- `apps/`: app Helm charts and HelmReleases.
- `nixos/`: NixOS host definitions for Kubernetes nodes.
- `pulumi/`: Pulumi Go project for Cloudflare, Tailscale, and global secrets.
- `docs/`: migration, secrets, and operations notes.

Configure host storage mount checks in `bootstrap/ansible/inventory/home.yml`.
App data paths are explicit in each app's `values.yaml`.

## Bootstrap

```sh
cd bootstrap
make bootstrap-k3s
make flux-bootstrap
```

## NixOS Nodes

Install NixOS nodes from the repo root with Nixie:

```sh
make nixie
```

The temporary PXE installer flake lives in `bootstrap/nixie-installer`; host
definitions and the Nixie MAC inventory live in `nixos/`.

Rebuild an existing NixOS node with:

```sh
make nixos-rebuild host=metal2
```

## Validation

```sh
cd bootstrap
make validate-host
make validate-cluster
```

Pulumi network validation:

```sh
cd pulumi
make test
```
