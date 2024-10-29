# Determinate Systems NixOS AMI

This repo houses the build logic for [Determinate Systems][detsys]' official [Amazon Machine Image (AMI)][ami] for [NixOS].
The AMI has these installed:

* [Determinate Nix][det-nix], which includes [Determinate Nixd][dnixd].
  This utility enables you to log in to [FlakeHub] from AWS using only this command:

  ```shell
  determinate-nixd login aws
  ```

* [fh], the CLI for [FlakeHub].
  You can use fh for things like [applying] NixOS configurations uploaded to [FlakeHub Cache][cache].
  Here's an example:

  ```shell
  determinate-nixd login aws
  fh apply nixos "my-org/my-flake/*#nixosConfigurations.my-nixos-configuration-output"
  ```

## Terraform

You can use our official AMI for NixOS in a [Terraform] configuration like this:

```hcl
data "aws_ami" "detsys_nixos" {
  owners      = ["detsys"]

  filter {
    name   = "name"
    values = ["determinate/nixos/24.05.*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
```

[ami]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html
[det-nix]: https://docs.determinate.systems/determinate-nix
[detsys]: https://determinate.systems
[dnixd]: https://docs.determinate.systems/determinate-nix#determinate-nixd
[fh]: https://docs.determinate.systems/flakehub/cli
[fh-apply]: https://docs.determinate.systems/flakehub/cli#apply
[nixos]: https://zero-to-nix.com/concepts/nixos
[terraform]: https://terraform.io
