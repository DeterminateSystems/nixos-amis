#!/usr/bin/env bash

set -x
set -euo pipefail

git config --global user.email "bot@determinate.systems"
git config --global user.name "DetSys Bot"

(
    cd ..
    time \
        git clone https://github.com/DeterminateSystems/nixpkgs -b colemickens/ec2
    
    cd nixpkgs
    git remote add nixos https://github.com/nixos/nixpkgs
    git fetch nixos nixos-unstable
    git checkout colemickens/ec2
    git rebase nixos/nixos-unstable
)

nix flake check --override-input nixpkgs ../nixpkgs

(
    cd ../nixpkgs

    # This is absurd, but whatever:
    git remote set-url origin "https://${GH_TOKEN}@github.com/DeterminateSystems/nixpkgs.git"

    git push --force-with-lease
)

# hell, let's try it for this repo and see if somehow it helps update-flake-lock/git
git remote set-url origin "https://${GH_TOKEN}@github.com/DeterminateSystems/nixos-amis.git"
