#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Container run without USER env variable set so we need to set it manually
# in oder to make home-manager work properly
export USER=${USER:-$(whoami)}

# Create per-user profile as it may not have been created by default in
# container environment
if [[ ! -d /nix/var/nix/profiles/per-user/"$USER" ]]; then
	echo "Creating per-user profile..."
	sudo mkdir -p /nix/var/nix/profiles/per-user/"$USER"
fi

# As the per-user profile may have been created by root, we need to fix its
# permissions so that the user can access it
if [[ -d /nix/var/nix/profiles/per-user/"$USER" ]]; then
	echo "Fix per-user profiles permissions..."
	sudo chown "$USER" /nix/var/nix/profiles/per-user/"$USER"
fi

echo "Nix is set up."

# Install Home
if ! command -v home-manager >/dev/null; then
	echo "Home Manager is not installed. Installing using nixpkgs..."
	nix run github:NixOS/nixpkgs/release-23.05#home-manager -- switch \
		--flake github:shikanime/shikanime \
		-b backup-before-nix
else
	echo "Home Manager is installed. Installing using Home Manager..."
	home-manager switch \
		--flake github:shikanime/shikanime \
		-b backup-before-nix
fi

echo "Home installed."
