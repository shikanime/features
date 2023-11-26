#!/bin/bash

set -e

# Container run without USER env variable set so we need to set it manually
# in oder to make home-manager work properly
export USER="${USER:-$(whoami)}"

# Install Nix flake in profile if specified
if [ ! -z "${FLAKEURI}" ] && [ "${FLAKEURI}" != "none" ]; then
    echo "Installing flake ${FLAKEURI} in profile..."
	nix run home-manager -- switch \
		--flake ${FLAKEURI} \
		-b backup-before-nix \
		--refresh
fi
