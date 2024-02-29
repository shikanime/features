#!/bin/bash

set -e

if [ "$(id -u)" -ne 0 ]; then
	echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
	exit 1
fi


# Run Google Cloud CLI installation script
su ${USERNAME} -c "
curl -fsSL https://tailscale.com/install.sh | sh
"

echo "Done!"
