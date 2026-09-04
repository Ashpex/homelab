{
  description = "Homelab Nixie installer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixie = {
      url = "path:../../nixie";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixie }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ../nixos/installer.nix
          nixie.nixosModules.nixie-agent
        ];
      };
    };
}
