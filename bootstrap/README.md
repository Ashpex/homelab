# Homelab Bootstrap

## Layers

- `ansible/`: host bootstrap for K3s, storage assumptions, and PXE-based NixOS installs.
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

## NixOS Node Bootstrap

Start the local PXE server for the guarded NixOS auto-installer:

```sh
cd bootstrap
make pxe-nixos
```

Run this from the Linux machine that should serve PXE. The playbook SSHes to
`metal0` at `192.168.1.110` to read the k3s token, then starts dnsmasq and
nginx locally on the Linux PXE machine. By default the PXE HTTP URL uses that
machine's detected LAN IP. Override it if Ansible picks the wrong interface:

```sh
ansible-playbook -i ansible/inventory/home.yml ansible/playbooks/pxe-nixos.yml \
  -e pxe_server_address=192.168.1.x
```

Then boot the node from network/PXE. The per-host PXE boot script passes:

```text
homelab.install=1 homelab.host=metal1 homelab.baseUrl=http://<pxe-server-ip>:8082
```

Nodes are defined in the `nixos_nodes` inventory group. If `pxe_mac` is set for
a node, iPXE selects the right host config automatically by MAC address. If
`pxe_mac` is empty, the boot script shows an iPXE menu so you can choose the
host manually.

The NixOS netboot image only auto-installs when `homelab.install=1` is present.
It downloads the host repo tarball and k3s node token from the local bootstrap
HTTP server, runs `disko`, runs `nixos-install`, and reboots.

After the reboot, verify the node joined:

```sh
kubectl --context homelab-nas wait node/metal1 --for=condition=Ready --timeout=10m
```

Then stop the local PXE services and remove temporary artifacts, including the
served k3s node token:

```sh
make pxe-clean
```

The PXE bootstrap target serves the k3s node token from the local bootstrap HTTP
server while PXE is running. The token is fetched live from `metal0` and is
not stored in Git. SOPS is still the better tool for long-lived repository
secrets, but it does not remove the need for a bootstrap secret source unless
the installer already has an age key.

## Local Validation

```sh
cd bootstrap
make validate-cluster
```

This validates release YAML and renders local Helm charts. It does not contact a
Kubernetes cluster.
