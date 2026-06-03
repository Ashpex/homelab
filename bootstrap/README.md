# Homelab IaC

## Layers

- `ansible/`: Ubuntu host bootstrap for K3s and local storage assumptions.
- `../flux`: Flux source object applied by Ansible.
- `../platform`: platform Helm charts and HelmRelease objects.
- `../apps`: app Helm charts and HelmRelease objects.
- `scripts/`: one-time bootstrap helpers.


## Bootstrap

1. Set the storage mount points in `ansible/inventory/home.yml`.
2. Confirm those mount points and app data paths exist on the host.
3. Configure K3s on the host:

```sh
cd bootstrap
make bootstrap-k3s
```

4. Install Flux source/helm controllers and apply the release objects:

```sh
cd bootstrap
make flux-bootstrap
```

This installs `source-controller` and `helm-controller`.

## Local Validation

```sh
cd bootstrap
make validate-cluster
```

This validates release YAML and renders local Helm charts. It does not contact a
Kubernetes cluster.
