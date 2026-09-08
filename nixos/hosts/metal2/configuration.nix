{ ... }:

{
  imports = [
    ../../profiles/k3s-server-join.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "metal2";
  networking.useDHCP = false;
  networking.nameservers = [
    "192.168.1.1"
    "1.1.1.1"
  ];

  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "en* eth*";
      address = [
        "192.168.1.112/24"
      ];
      routes = [
        { Gateway = "192.168.1.1"; }
      ];
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = true;
      };
    };
  };

  homelab.kubernetes.nodeIP = "192.168.1.112";
}
