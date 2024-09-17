{
  inputs.flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/0.1.5.tar.gz";
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
  inputs.determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0.1.95.tar.gz";
  inputs.fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0.1.16.tar.gz";

  outputs = { self, nixpkgs, determinate, fh, flake-schemas, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];

      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        inherit system;
        pkgs = nixpkgs.legacyPackages.${system};
        lib = nixpkgs.lib;
      });
    in
    {
      nixosConfigurations = forAllSystems
        ({ system, pkgs, lib, ... }: lib.nixosSystem {
          system = system;
          modules = [
            "${nixpkgs}/nixos/maintainers/scripts/ec2/amazon-image.nix"
            determinate.nixosModules.default
            {
              environment.systemPackages = [
                fh.packages."${system}".default
              ];
            }
          ];
        });

      diskImages = forAllSystems
        ({ system, ... }: {
          aws = self.nixosConfigurations.${system}.config.system.build.amazonImage;
        });

      schemas = flake-schemas.schemas // {
        diskImages = {
          version = 1;
          doc = ''
            The `diskImages` flake output contains derivations that build disk images for various execution environments.
          '';
          inventory = flake-schemas.lib.derivationsInventory "Disk image" false;
        };
      };
    };
}
