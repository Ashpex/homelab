# Homelab

K3s, Flux Helm controller, and Pulumi IaC for the home server.

<img width="948" height="629" alt="Screenshot 2026-06-04 at 6 02 37 PM" src="https://github.com/user-attachments/assets/c998d0d0-6e74-4694-883a-5e7508cbbfa5" />


## Layout

- `bootstrap/`: host bootstrap and Flux bootstrap.
- `flux/`: Flux GitRepository source.
- `platform/`: platform Helm charts and HelmReleases.
- `apps/`: app Helm charts and HelmReleases.
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
