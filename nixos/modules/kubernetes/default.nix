{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.homelab.kubernetes;
in
{
  options.homelab.kubernetes = {
    enable = mkEnableOption "Kubernetes node support";

    role = mkOption {
      type = types.enum [ "agent" "server" ];
      default = "agent";
      description = "k3s role for this node.";
    };

    serverAddr = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Existing k3s server URL for joining nodes.";
    };

    tokenFile = mkOption {
      type = types.str;
      default = "/etc/rancher/k3s/node-token";
      description = "Path containing the k3s join token.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/rancher/k3s";
      description = "k3s data directory.";
    };

    nodeLabels = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Labels applied by k3s when the node registers.";
    };

    disableComponents = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "k3s bundled components to disable on server nodes.";
    };

    clusterInit = mkOption {
      type = types.bool;
      default = false;
      description = "Initialize the first k3s server with embedded etcd.";
    };

    secretsEncryption = mkOption {
      type = types.bool;
      default = false;
      description = "Enable k3s secrets encryption on server nodes.";
    };

    disableHostFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Disable the NixOS host firewall for Kubernetes node traffic.";
    };
  };

  config = mkIf cfg.enable {
    services.k3s = {
      enable = true;
      package = pkgs.k3s_1_35;
      role = cfg.role;
      tokenFile = cfg.tokenFile;
      extraFlags =
        [ "--data-dir=${cfg.dataDir}" ]
        ++ optionals (cfg.serverAddr != null) [ "--server=${cfg.serverAddr}" ]
        ++ optionals (cfg.role == "server" && cfg.clusterInit) [ "--cluster-init" ]
        ++ optionals (cfg.role == "server" && cfg.secretsEncryption) [ "--secrets-encryption" ]
        ++ map (label: "--node-label=${label}") cfg.nodeLabels
        ++ map (component: "--disable=${component}") cfg.disableComponents;
    };

    networking.firewall = mkIf cfg.disableHostFirewall {
      enable = false;
    };
  };
}
