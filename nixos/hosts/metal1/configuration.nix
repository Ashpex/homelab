{ ... }:

{
  imports = [
    ../../profiles/k3s-worker.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "metal1";
}
