# NixOS Nodes

Reproducible NixOS configs for homelab Kubernetes nodes.

## Layout

- `flake.nix`: builds host configs and the PXE netboot installer.
- `hosts/<name>`: per-machine config, disk layout, and hardware config.
- `profiles/`: reusable k3s roles.
- `modules/`: shared OS, Kubernetes, and storage settings.
- `scripts/install-node.sh`: installer script used by PXE and manual installs.

## Hosts

- `metal0`: NixOS k3s server/control-plane config.
- `metal1`: NixOS k3s worker.

Before installing a host, check its disk name with:

```sh
lsblk
```

Then update `hosts/<name>/disk.nix` if needed. The current example uses
`/dev/nvme0n1`.

## PXE Install

Run this from the Linux machine on the same LAN:

```sh
make pxe-nixos
```

Then PXE boot the target machine and pick the host, for example `metal1`.

The PXE installer will:

1. download this repo snapshot and the k3s node token,
2. run `disko`,
3. install NixOS,
4. reboot,
5. join the k3s cluster.

After the node is installed:

```sh
make pxe-clean
kubectl --context homelab-nas get nodes -o wide
```

## Manual Install

From a NixOS installer shell:

```sh
./nixos/scripts/install-node.sh \
  --host metal1 \
  --token-file /path/to/node-token
```

The token comes from the existing k3s server:

```sh
sudo cat /var/lib/rancher/k3s/server/node-token
```

This destroys existing data on the disk configured in `hosts/<name>/disk.nix`.

## Rebuild

After install, the repo snapshot lives at `/opt/homelab` on the node.

```sh
sudo nixos-rebuild switch --flake /opt/homelab/nixos#metal1
```

To add another node, copy `hosts/metal1` to a new host directory and adjust:

- `networking.hostName`
- disk device in `disk.nix`
- k3s labels or role profile
- inventory entry in `bootstrap/ansible/inventory/home.yml`
