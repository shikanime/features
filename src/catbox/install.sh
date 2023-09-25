#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

FLAKEURI="${FLAKEURI:-""}"
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Import common utils
. ./utils.sh

detect_user USERNAME

# Create per-user profile as it may not have been created by default in
# container environment
if [[ ! -d /nix/var/nix/profiles/per-user/"$USERNAME" ]]; then
    echo "Creating per-user profile..."
    sudo mkdir -p /nix/var/nix/profiles/per-user/"$USERNAME"
fi

# As the per-user profile may have been created by root, we need to fix its
# permissions so that the user can access it
if [[ -d /nix/var/nix/profiles/per-user/"$USERNAME" ]]; then
    echo "Fix per-user profiles permissions..."
    sudo chown "$USERNAME" /nix/var/nix/profiles/per-user/"$USERNAME"
fi

# Install Home
if ! command -v home-manager >/dev/null; then
    echo "Home Manager is not installed. Installing using nixpkgs..."
    nix run nixpkgs#home-manager -- switch \
        --flake $FLAKEURI \
        -b backup-before-nix
else
    echo "Home Manager is installed. Installing using Home Manager..."
    home-manager switch \
        --flake $FLAKEURI \
        -b backup-before-nix
fi

echo "Done!"
