{ ... }:

{
  homelab.kubernetes = {
    enable = true;
    role = "server";
    tokenFile = "/etc/rancher/k3s/node-token";
    disableComponents = [
      "traefik"
    ];
    nodeLabels = [
      "homelab.node/role=server"
      "homelab.node/nas=true"
      "homelab.storage/ssd=true"
      "node.longhorn.io/create-default-disk=true"
    ];
  };

  homelab.storage = {
    longhorn = {
      enable = true;
      dataDir = "/var/lib/longhorn";
    };
    nfsClient.enable = true;
  };
}
