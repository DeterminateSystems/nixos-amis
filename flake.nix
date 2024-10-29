{
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0.1.95.tar.gz";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0.1.*.tar.gz";
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/0.1.5.tar.gz";
    nixos-amis.url = "github:NixOS/amis";
  };

  outputs = { self, ... }@inputs:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];

      forAllSystems = f: inputs.nixpkgs.lib.genAttrs supportedSystems (system: f {
        inherit system;
        pkgs = import inputs.nixpkgs {
          inherit system;
        };
        lib = inputs.nixpkgs.lib;
      });
    in
    {
      nixosConfigurations = forAllSystems ({ system, pkgs, lib, ... }: lib.nixosSystem {
        inherit system;
        modules = [
          "${inputs.nixpkgs}/nixos/maintainers/scripts/ec2/amazon-image.nix"
          inputs.determinate.nixosModules.default
          {
            environment.systemPackages = [
              inputs.fh.packages.${system}.default
            ];
          }
          {
            systemd.services.amazon-init.path = [
              "/run/wrappers"
              "/run/current-system/sw"
            ];
          }
        ];
      });

      diskImages = forAllSystems ({ system, ... }: {
        aws = self.nixosConfigurations.${system}.config.system.build.amazonImage;
      });

      devShells = forAllSystems ({ pkgs, system, ... }: {
        default = pkgs.mkShell {
          packages = [
            inputs.nixos-amis.packages.${system}.upload-ami
          ];
        };
      });

      apps = forAllSystems ({ system, ... }: {
        smoke-test = inputs.nixos-amis.apps.${system}.smoke-test;
      });

      schemas = inputs.flake-schemas.schemas // {
        diskImages = {
          version = 1;
          doc = ''
            The `diskImages` flake output contains derivations that build disk images for various execution environments.
          '';
          inventory = inputs.flake-schemas.lib.derivationsInventory "Disk image" false;
        };
      };
    };
}
