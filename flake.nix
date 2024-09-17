{
    inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
    inputs.determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/0.1.95.tar.gz";
    inputs.fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0.1.16.tar.gz";

    outputs = { self, nixpkgs, determinate, fh, ... }: {
        nixosConfigurations.x86_64-linux = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
                "${nixpkgs}/nixos/maintainers/scripts/ec2/amazon-image.nix"
                determinate.nixosModules.default
                ({ pkgs, ... }: {
                    environment.systemPackages = [
                        fh.packages."${pkgs.stdenv.system}".default
                    ];
                })
            ];
        };

        topLevels.x86_64-linux.aws = self.nixosConfigurations.x86_64-linux.config.system.build.toplevel;
        diskImages.x86_64-linux.aws = self.nixosConfigurations.x86_64-linux.config.system.build.amazonImage;
    };
}