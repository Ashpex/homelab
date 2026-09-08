# Homelab Bootstrap

## Layers

- `ansible/`: host bootstrap for K3s, storage assumptions, and NixOS rebuilds.
- `nixie-installer/`: temporary NixOS installer flake used by `make nixie`.
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

## NixOS Nodes

Run Nixie from the repo root:

```sh
make nixie
```

That target uses `bootstrap/nixie-installer` for the temporary PXE system and
`nixos/nixie-hosts.json` to map machine MAC addresses to host configs.

Existing NixOS nodes are rebuilt through Ansible:

```sh
make nixos-rebuild host=metal2
```

## Kubernetes VIP

kube-vip advertises `192.168.1.100` for the Kubernetes API and Traefik app
ingress. The platform chart lives in `../platform/kube-vip` and is applied by
Flux. K3s ServiceLB is disabled so kube-vip owns `LoadBalancer` Services.

Rollout order:

1. Run `make bootstrap-k3s` so `metal0` includes `192.168.1.100` in the K3s
   API certificate SANs.
2. Run `make nixos-rebuild host=metal1` and `make nixos-rebuild host=metal2`
   so the NixOS control-plane nodes include the same SAN.
3. Commit and push the platform change, then reconcile Flux.
4. Verify the VIP and Traefik service:

```sh
kubectl --context homelab -n kube-system get pods -l app.kubernetes.io/name=kube-vip -o wide
kubectl --context homelab -n traefik get svc traefik
curl -k https://192.168.1.100:6443/readyz
curl -k https://192.168.1.100/
```

## Local Validation

```sh
cd bootstrap
make validate-cluster
```

This validates release YAML and renders local Helm charts. It does not contact a
Kubernetes cluster.
