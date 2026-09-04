# NixOS Nodes

Reproducible NixOS configs for homelab Kubernetes nodes.

## Layout

- `flake.nix`: builds installed host configs.
- `hosts/<name>`: per-machine config, disk layout, and hardware config.
- `profiles/`: reusable k3s roles.
- `modules/`: shared OS, Kubernetes, and storage settings.
- `installer.nix`: temporary NixOS installer module used by `../nixie-installer`.
- `nixie-hosts.json`: Nixie host inventory keyed by flake output name.

## Hosts

- `metal0`: NixOS k3s server/control-plane config.
- `metal1`: NixOS k3s control-plane node.
- `metal2`: NixOS k3s control-plane node.

Before installing a host, check its disk name with:

```sh
lsblk
```

Then update `hosts/<name>/disk.nix` if needed. The current example uses
`/dev/nvme0n1`.

## Nixie Install

Run this from the Linux machine on the same LAN:

```sh
make pxe-nixos
```

This uses Nixie from `/Users/vybui/projects/nixie` to run an ephemeral PXE
server, boot the custom `installer` output, and install the host output that
matches the target machine's MAC address in `nixie-hosts.json`.

The Nixie installer will:

1. build the custom installer output,
2. serve it over PXE,
3. wake configured machines with Wake-on-LAN,
4. run `nixos-anywhere`,
5. reboot into the installed NixOS system,
6. update `nixie-hosts.json` with final identity data.

The SSH key defaults to:

```sh
~/.ssh/ashpex
```

Nixie uses that key as `root` in the temporary installer and as `ashpex` after
the installed system reboots. Override the key or deployment user if needed:

```sh
make pxe-nixos \
  NIXIE_INSTALL_SSH_KEY=~/.ssh/other-install-key \
  NIXIE_DEPLOYMENT_SSH_KEY=~/.ssh/other-deployment-key \
  NIXIE_DEPLOYMENT_SSH_USER=other-user
```

After the node is installed:

```sh
make pxe-clean
kubectl --context homelab get nodes -o wide
```

The `homelab.node/nas=true` label means the node owns the NAS storage role. It
does not make the Kubernetes node name `nas`; current nodes should use names
like `metal0`, `metal1`, `metal2`, and so on.

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

After install, keep the repo checkout at `/home/ashpex/homelab` on the node.
If the checkout is missing, clone it with:

```sh
nixos/scripts/sync-repo.sh
```

If `/opt/homelab` is still a legacy copied snapshot, replace it with a Git
checkout with:

```sh
nixos/scripts/sync-repo.sh
```

```sh
sudo nixos-rebuild switch --flake /home/ashpex/homelab/nixos#metal1
```

To add another node, copy `hosts/metal1` to a new host directory and adjust:

- `networking.hostName`
- disk device in `disk.nix`
- k3s labels or role profile
- inventory entry in `bootstrap/ansible/inventory/home.yml`
