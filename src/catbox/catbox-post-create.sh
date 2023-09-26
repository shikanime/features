#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Container run without USER env variable set so we need to set it manually
# in oder to make home-manager work properly
export USER=${USER:-$(whoami)}

# Install Home Manager configuration
echo "Installing home configuration..."
home-manager switch \
    --flake github:shikanime/shikanime \
    -b backup-before-nix
