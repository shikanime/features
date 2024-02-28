#!/bin/bash

set -e

VERSION="${VERSION:-"latest"}"

if [ "$(id -u)" -ne 0 ]; then
	echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
	exit 1
fi

# Run Alibaba Cloud CLI installation script
curl -fsSL https://raw.githubusercontent.com/aliyun/aliyun-cli/HEAD/install.sh | bash -s -- \
	-V "${VERSION}"

echo "Done!"
