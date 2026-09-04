{ ... }:

{
  imports = [
    ../../profiles/k3s-server-join.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "metal1";

  homelab.kubernetes.nodeIP = "192.168.1.111";
}
