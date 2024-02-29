#!/bin/bash

set -e

if [ "$(id -u)" -ne 0 ]; then
	echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
	exit 1
fi


# Run Tailscale installation script
curl -fsSL https://tailscale.com/install.sh | sh

echo "Done!"
