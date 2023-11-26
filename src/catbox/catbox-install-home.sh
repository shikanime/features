#!/bin/bash

set -e

# Container run without USER env variable set so we need to set it manually
# in oder to make home-manager work properly
export USER="${USER:-$(whoami)}"

# Install Nix flake in profile if specified
echo "Installing Home..."
nix run home-manager -- switch \
	--flake github:shikanime/shikanime \
	-b backup-before-nix \
	--refresh
