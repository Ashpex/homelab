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

  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    jq
    nfs-utils
    util-linux
    vim
  ];

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 1048576;
    "fs.inotify.max_user_instances" = 8192;
    "fs.inotify.max_queued_events" = 65536;
  };

  system.stateVersion = "25.05";
}
