{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.homelab.storage;
in
{
  options.homelab.storage = {
    longhorn = {
      enable = mkEnableOption "Longhorn host prerequisites";

      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/longhorn";
        description = "Longhorn data directory on this node.";
      };
    };

    nfsClient = {
      enable = mkEnableOption "NFS client prerequisites";
    };
  };

  config = mkMerge [
    (mkIf cfg.longhorn.enable {
      environment.systemPackages = with pkgs; [
        cryptsetup
        e2fsprogs
        nfs-utils
        openiscsi
        util-linux
      ];

      boot.kernelModules = [
        "iscsi_tcp"
        "dm_crypt"
      ];

      services.openiscsi = {
        enable = true;
        name = "iqn.2026-08.net.ashpex:${config.networking.hostName}";
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.longhorn.dataDir} 0755 root root -"
        "L+ /usr/bin/iscsiadm - - - - ${pkgs.openiscsi}/bin/iscsiadm"
        "L+ /usr/sbin/iscsiadm - - - - ${pkgs.openiscsi}/bin/iscsiadm"
      ];
    })

    (mkIf cfg.nfsClient.enable {
      environment.systemPackages = with pkgs; [
        nfs-utils
      ];

      boot.supportedFilesystems = [ "nfs" "nfs4" ];
    })
  ];
}
