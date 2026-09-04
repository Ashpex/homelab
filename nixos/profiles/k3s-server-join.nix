{ ... }:

{
  homelab.kubernetes = {
    enable = true;
    role = "server";
    serverAddr = "https://192.168.1.110:6443";
    tokenFile = "/etc/rancher/k3s/node-token";
    secretsEncryption = true;
    disableComponents = [
      "traefik"
    ];
    nodeLabels = [
      "homelab.node/role=server"
      "homelab.storage/ssd=true"
      "homelab.storage/nfs-client=true"
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
