# Determinate Systems NixOS AMIs

## Overview

This repo houses the build logic for [Determinate Systems][detsys]' official [Amazon Machine Images (AMIs)][ami] for [NixOS].
Our AMIs are available for these systems:

System      | Nix system name
:-----------|:---------------
AMD64 Linux | `x86_64-linux`
ARM64 Linux | `aarch64-linux`

On both systems, the AMIs have these tools installed:

* [Determinate Nix][det-nix], Determinate Systems' validated and secure [Nix] distribution for enterprises.
  This includes [Determinate Nixd][dnixd], a utility that enables you to log in to [FlakeHub] from AWS using only this command (amongst other tasks):

  ```shell
  determinate-nixd login aws
  ```

  Once logged in, your AMI can access [FlakeHub Cache][cache] and [private flakes][private-flakes] for your organization.
  Note that there is no need to manage access tokens or keys, as Determinate Nixd uses [AWS Security Token Service][sts] for authentication.

* [fh], the CLI for [FlakeHub].
  You can use fh for things like [applying][fh-apply-nixos] NixOS configurations uploaded to [FlakeHub Cache][cache].
  Here's an example:

  ```shell
  determinate-nixd login aws
  fh apply nixos "my-org/my-flake/*#nixosConfigurations.my-nixos-configuration-output"
  ```

## Changelog

# epoch-1 (beta)
This is an initial, preview, beta version of Determinate AMIs.

## Terraform

You can use our official AMI for NixOS in a [Terraform] configuration like this:

```hcl
data "aws_ami" "detsys_nixos" {
  owners = ["535002876703"]

  filter {
    name   = "name"
    values = ["determinate/nixos/epoch-1/24.05.*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
```

To use the most recent AMI, add `most_recent = true` to your data declaration:

```hcl
data "aws_ami" "detsys_nixos" {
  most_recent = true

  most_recent = true
  owners      = ["535002876703"]

  filter {
    name   = "name"
    values = ["determinate/nixos/epoch-1/24.05.*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
```

[ami]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html
[fh-apply-nixos]: https://docs.determinate.systems/flakehub/cli#apply-nixos
[cache]: https://docs.determinate.systems/flakehub/cache
[det-nix]: https://docs.determinate.systems/determinate-nix
[detsys]: https://determinate.systems
[dnixd]: https://docs.determinate.systems/determinate-nix#determinate-nixd
[fh]: https://docs.determinate.systems/flakehub/cli
[fh-apply]: https://docs.determinate.systems/flakehub/cli#apply
[flakehub]: https://flakehub.com
[nix]: https://docs.determinate.systems/determinate-nix
[nixos]: https://zero-to-nix.com/concepts/nixos
[private-flakes]: https://docs.determinate.systems/flakehub/private-flakes
[sts]: https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html
[terraform]: https://terraform.io
