{ ... }:

{
  imports = [
    ../../profiles/k3s-server.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "metal0";
}
