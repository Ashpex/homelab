# Homelab Bootstrap

## Layers

- `ansible/`: host bootstrap for K3s, storage assumptions, and NixOS rebuilds.
- `../flux`: Flux source object applied by Ansible.
- `../platform`: platform Helm charts and HelmRelease objects.
- `../apps`: app Helm charts and HelmRelease objects.
- `scripts/`: one-time bootstrap helpers.


## Bootstrap

1. Set the storage mount points in `ansible/inventory/home.yml`.
2. Confirm those mount points and app data paths exist on the host.
3. Configure K3s, NFS media exports, and Longhorn prerequisites on the host:

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

`homelab.node/nas=true` is a Kubernetes label for the node that owns the NAS
storage role. It is not the Kubernetes node name; the current node name is
`metal0`.

## Local Validation

```sh
cd bootstrap
make validate-cluster
```

This validates release YAML and renders local Helm charts. It does not contact a
Kubernetes cluster.
