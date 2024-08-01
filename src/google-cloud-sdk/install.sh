#!/bin/bash

set -e

if [ "$(id -u)" -ne 0 ]; then
	echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
	exit 1
fi

# Run Google Cloud CLI installation script
curl -fsSL https://sdk.cloud.google.com | bash -s -- \
	--disable-prompts \
	--install-dir="/usr/local/share" \

echo "Done!"
