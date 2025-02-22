{
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/nixos/nixpkgs/0.1.*";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*.tar.gz";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0.1.*";
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/0.1.5";
    nixos-amis.url = "https://flakehub.com/f/NixOS/amis/0.1.*";
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
          ({ config, ... }: {

            system.nixos.tags = lib.mkForce [ ];
            environment.systemPackages = [
              inputs.fh.packages.${system}.default
              pkgs.git
            ];

            virtualisation.diskSize = lib.mkForce (4 * 1024);

            assertions =
              [{
                assertion = ((
                  builtins.match
                    "^[0-9][0-9]\.[0-9][0-9]\..*"
                    config.system.nixos.label
                ) != null);
                message = "nixos image label is incorrect";
              }];
          })
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
