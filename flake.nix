{
  inputs = {
    nixpkgs.url = "github:DeterminateSystems/nixpkgs?ref=colemickens/ec2";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0.1.95.tar.gz";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0.1.*.tar.gz";
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/0.1.5.tar.gz";
    nixos-amis.url = "github:NixOS/amis";
  };

  outputs = { self, ... }@inputs:
    let
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      allSystems = linuxSystems ++ [ "x86_64-darwin" "aarch64-darwin" ];

      forSystems = systems: f: inputs.nixpkgs.lib.genAttrs systems (system: f {
        inherit system;
        pkgs = import inputs.nixpkgs {
          inherit system;
        };
        lib = inputs.nixpkgs.lib;
      });

      forLinuxSystems = forSystems linuxSystems;
      forAllSystems = forSystems allSystems;
    in
    {
      # Update this, and the changelog *and* usage examples in the README, for breaking changes to the AMIs
      epoch = builtins.toString 1;

      nixosConfigurations = forLinuxSystems ({ system, pkgs, lib, ... }: lib.nixosSystem {
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

      diskImages = forLinuxSystems ({ system, ... }: {
        aws = self.nixosConfigurations.${system}.config.system.build.amazonImage;
      });

      devShells = forAllSystems ({ system, pkgs, lib, ... }: {
        default = pkgs.mkShell {
          packages = [
            pkgs.lychee
            pkgs.nixpkgs-fmt
          ] ++ lib.optionals (builtins.elem system linuxSystems) [
            inputs.nixos-amis.packages.${system}.upload-ami
          ];
        };
      });

      apps = forLinuxSystems ({ system, ... }: {
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
