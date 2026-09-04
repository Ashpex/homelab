{
  description = "Homelab NixOS Kubernetes node configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      hostNames = builtins.attrNames (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts)
      );

      mkNode = host:
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit host;
          };
          modules = [
            disko.nixosModules.disko
            ./modules/common
            ./hosts/${host}/disk.nix
            ./hosts/${host}/configuration.nix
          ];
        };

      diskoPackage = disko.packages.${system}.disko or disko.packages.${system}.default;
    in
    {
      apps.${system} = {
        disko = {
          type = "app";
          program = "${diskoPackage}/bin/disko";
        };
      };

      nixosConfigurations = lib.genAttrs hostNames mkNode;
    };
}
