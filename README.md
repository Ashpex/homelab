# Homelab

K3s, Flux Helm controller, and Pulumi IaC for the home server.

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

`flux-bootstrap` installs Flux `source-controller` and `helm-controller`.

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
