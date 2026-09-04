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
    initialPassword = "changeme";
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

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 1048576;
    "fs.inotify.max_user_instances" = 8192;
    "fs.inotify.max_queued_events" = 65536;
  };

  system.stateVersion = "25.05";
}
