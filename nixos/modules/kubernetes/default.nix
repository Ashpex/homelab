{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.homelab.kubernetes;
  advertiseAddress =
    if cfg.advertiseAddress != null then cfg.advertiseAddress else cfg.nodeIP;
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

    nodeIP = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Node IP address advertised by k3s.";
    };

    advertiseAddress = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Kubernetes API advertise address for k3s server nodes.";
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
    systemd.services.k3s.preStart = mkBefore ''
      install -d -m 0700 /etc/rancher/node
      if [ ! -s /etc/rancher/node/password ]; then
        rm -f /etc/rancher/node/password
        ${pkgs.openssl}/bin/openssl rand -hex 32 > /etc/rancher/node/password
        chmod 0600 /etc/rancher/node/password
      fi
      if [ -d /var/lib/rancher/k3s/agent ]; then
        if find /var/lib/rancher/k3s/agent -maxdepth 1 -type f -size 0 \
          \( -name '*.key' -o -name 'client-*.crt' -o -name 'serving-*.crt' \) | grep -q .; then
          find /var/lib/rancher/k3s/agent -maxdepth 1 -type f \
            \( -name '*.key' -o -name 'client-*.crt' -o -name 'serving-*.crt' \) -delete
        fi
      fi
      if [ -d /var/lib/rancher/k3s/server/tls/temporary-certs ]; then
        find /var/lib/rancher/k3s/server/tls/temporary-certs -maxdepth 1 -type f -size 0 \
          \( -name '*.key' -o -name '*.crt' \) -delete
      fi
    '';

    services.k3s = {
      enable = true;
      package = pkgs.k3s_1_35;
      role = cfg.role;
      tokenFile = cfg.tokenFile;
      extraFlags =
        [ "--data-dir=${cfg.dataDir}" ]
        ++ optionals (cfg.serverAddr != null) [ "--server=${cfg.serverAddr}" ]
        ++ optionals (cfg.nodeIP != null) [ "--node-ip=${cfg.nodeIP}" ]
        ++ optionals (cfg.role == "server" && advertiseAddress != null) [ "--advertise-address=${advertiseAddress}" ]
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
