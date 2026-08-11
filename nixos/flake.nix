{
  description = "Homelab NixOS Kubernetes node configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      hostNames = builtins.attrNames (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts)
      );

      mkNode = host:
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit host;
          };
          modules = [
            disko.nixosModules.disko
            ./modules/common
            ./hosts/${host}/disk.nix
            ./hosts/${host}/configuration.nix
          ];
        };

      netbootSystem = lib.nixosSystem {
        inherit system;
        modules = [
          ({ config, lib, modulesPath, pkgs, ... }:
          let
            autoInstall = pkgs.writeShellScript "homelab-auto-install" ''
              set -euo pipefail

              get_arg() {
                local name="$1"
                local arg
                for arg in $(cat /proc/cmdline); do
                  case "$arg" in
                    "$name="*) printf '%s\n' "''${arg#*=}"; return 0 ;;
                  esac
                done
                return 1
              }

              install_enabled="$(get_arg homelab.install || true)"
              if [ "$install_enabled" != "1" ]; then
                echo "homelab.install=1 not set; leaving installer idle"
                exit 0
              fi

              host="$(get_arg homelab.host)"
              base_url="$(get_arg homelab.baseUrl)"
              work_dir="/tmp/homelab-auto-install"
              repo_dir="$work_dir/repo"

              mkdir -p "$repo_dir"
              curl --fail --location --retry 10 --retry-delay 3 \
                "$base_url/install/$host/repo.tar" \
                --output "$work_dir/repo.tar"
              tar -C "$repo_dir" -xf "$work_dir/repo.tar"

              curl --fail --location --retry 10 --retry-delay 3 \
                "$base_url/install/$host/node-token" \
                --output "$work_dir/node-token"
              chmod 0600 "$work_dir/node-token"

              "$repo_dir/nixos/scripts/install-node.sh" \
                --host "$host" \
                --token-file "$work_dir/node-token" \
                --yes

              systemctl reboot
            '';
          in {
            imports = [
              (modulesPath + "/installer/netboot/netboot-minimal.nix")
            ];

            nix.settings.experimental-features = [ "nix-command" "flakes" ];

            systemd.services.homelab-auto-install = {
              description = "Homelab guarded auto installer";
              wantedBy = [ "multi-user.target" ];
              after = [ "network-online.target" ];
              wants = [ "network-online.target" ];
              path = with pkgs; [
                bash
                coreutils
                curl
                gnutar
                nix
                systemd
                util-linux
                config.system.build.nixos-install
              ];
              serviceConfig = {
                Type = "oneshot";
                ExecStart = autoInstall;
              };
            };

            environment.systemPackages = with pkgs; [
              curl
              git
              rsync
              gnutar
              vim
            ];
          })
        ];
      };
    in
    {
      packages.${system} = {
        netboot = nixpkgs.legacyPackages.${system}.runCommand "homelab-nixos-netboot" { } ''
          mkdir -p "$out"
          cp ${netbootSystem.config.system.build.kernel}/${netbootSystem.config.system.boot.loader.kernelFile} "$out/bzImage"
          cp ${netbootSystem.config.system.build.netbootRamdisk}/initrd "$out/initrd"
          printf '%s\n' \
            '#!ipxe' \
            'dhcp' \
            'kernel @@BASE_URL@@/bzImage init=${netbootSystem.config.system.build.toplevel}/init loglevel=4 @@INSTALL_ARGS@@' \
            'initrd @@BASE_URL@@/initrd' \
            'boot' \
            > "$out/boot.ipxe"
        '';
      };

      apps.${system} = {
        disko = disko.apps.${system}.default;
      };

      nixosConfigurations = lib.genAttrs hostNames mkNode;
    };
}
