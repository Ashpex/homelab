{ pkgs, ... }:

{
  imports = [
    ../kubernetes
    ../storage
  ];

  time.timeZone = "Asia/Ho_Chi_Minh";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  networking.useDHCP = true;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.tailscale.enable = true;

  users.users.ashpex = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKmkmdTLGl2RgiYVQ1qVtWR5njuvDMaeZeEMxu5QHBzC mail@ashpex.net"
    ];
  };

  environment.systemPackages = with pkgs; [
    curl
    dnsutils
    ethtool
    file
    git
    htop
    iperf3
    jq
    k9s
    kubectl
    lsof
    neovim
    nfs-utils
    pciutils
    ripgrep
    rsync
    smartmontools
    tcpdump
    tailscale
    tree
    unzip
    util-linux
    usbutils
    wget
  ];

  systemd.tmpfiles.rules = [
    "d /opt/homelab 0775 root wheel - -"
  ];

  systemd.services.homelab-repo-sync = {
    description = "Sync homelab repository checkout";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [
      coreutils
      git
    ];
    script = ''
      set -euo pipefail

      repo_url="https://github.com/Ashpex/homelab.git"
      repo_dir="/opt/homelab"

      if [ -d "$repo_dir/.git" ]; then
        git -C "$repo_dir" fetch --prune origin
        git -C "$repo_dir" reset --hard origin/master
      else
        if [ -e "$repo_dir" ]; then
          mv "$repo_dir" "/opt/homelab.snapshot.$(date +%s)"
        fi
        git clone "$repo_url" "$repo_dir"
      fi

      chgrp -R wheel "$repo_dir"
      chmod -R g+rwX "$repo_dir"
    '';
    serviceConfig = {
      Type = "oneshot";
    };
  };

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 1048576;
    "fs.inotify.max_user_instances" = 8192;
    "fs.inotify.max_queued_events" = 65536;
  };

  system.stateVersion = "25.05";
}
