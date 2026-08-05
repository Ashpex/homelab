# NixOS Kubernetes Nodes

NixOS host definitions for Kubernetes nodes in this homelab.

The intent is to keep node operating-system configuration reproducible while
leaving Kubernetes workloads in `apps/` and `platform/`.

## Layout

- `flake.nix`: entrypoint for all NixOS node builds.
- `hosts/`: one directory per physical node.
- `modules/common`: baseline OS settings shared by every node.
- `modules/kubernetes`: k3s node roles and Kubernetes host prerequisites.
- `modules/storage`: Longhorn and NFS client prerequisites.

## First Worker Node

The initial M720q worker is defined at:

```sh
nixos/hosts/metal1/configuration.nix
```

Its disk layout is defined with `disko` at:

```sh
nixos/hosts/metal1/disk.nix
```

The default target disk is `/dev/nvme0n1`. Verify this in the installer with:

```sh
lsblk
```

Then partition, format, and mount the target disk:

```sh
./nixos/scripts/install-node.sh \
  --host metal1 \
  --token-file /path/to/node-token
```

This destroys existing data on the target disk.

The token can be read from the existing server:

```sh
sudo cat /var/lib/rancher/k3s/server/node-token
```

If you want to run the lower-level steps manually, use the pinned `disko` app
from this flake:

```sh
sudo nix run ./nixos#disko -- \
  --mode disko \
  --flake ./nixos#metal1

sudo install -d -m 0700 /mnt/etc/rancher/k3s
sudo install -m 0600 /path/to/node-token /mnt/etc/rancher/k3s/node-token

sudo install -d -m 0775 -g wheel /mnt/opt/homelab
sudo rsync -a --exclude .git ./ /mnt/opt/homelab/
sudo chgrp -R wheel /mnt/opt/homelab
sudo chmod -R g+rwX /mnt/opt/homelab

sudo nixos-install --flake /mnt/opt/homelab/nixos#metal1
```

Verify from an existing kubeconfig:

```sh
kubectl --context homelab-nas get nodes -o wide
```

## Adding More Nodes

1. Copy `hosts/metal1` to `hosts/<hostname>`.
2. Update `networking.hostName`, k3s labels, disk device, and any node-specific
   storage.
3. Run `./nixos/scripts/install-node.sh --host <hostname> --token-file <path>`.

After install, the node keeps this repo snapshot at `/opt/homelab`. Rebuild an
installed node with:

```sh
sudo nixos-rebuild switch --flake /opt/homelab/nixos#metal1
```

## Notes

- Keep secrets out of Git. Use `tokenFile` or a secrets manager, not inline k3s
  tokens.
- Worker nodes that consume NFS exports from `nas` should carry the
  `homelab.storage/nfs-client=true` node label.
- The `nas` storage/server node should carry `homelab.storage/nfs-server=true`.
