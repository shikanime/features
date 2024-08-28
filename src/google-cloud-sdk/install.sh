#!/bin/bash

set -e

export CLOUDSDK_INSTALL_PATH="${CLOUDSDK_INSTALL_PATH:-"/usr/local"}"

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"

if [ "$(id -u)" -ne 0 ]; then
	echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
	exit 1
fi

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
	USERNAME=""
	POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
	for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
		if id -u "${CURRENT_USER}" >/dev/null 2>&1; then
			USERNAME="${CURRENT_USER}"
			break
		fi
	done
	if [ "${USERNAME}" = "" ]; then
		USERNAME=root
	fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} >/dev/null 2>&1; then
	USERNAME=root
fi

# Run Google Cloud CLI installation script
curl -fsSL https://sdk.cloud.google.com | bash -s -- \
	--disable-prompts \
	--install-dir="${CLOUDSDK_INSTALL_PATH}"

# Create gcloud group, dir, and set sticky bit
if ! cat /etc/group | grep -e "^gcloud:" > /dev/null 2>&1; then
	groupadd -r gcloud
fi
usermod -a -G gcloud ${USERNAME}
umask 0002
chown -R "${USERNAME}:gcloud" ${CLOUDSDK_INSTALL_PATH}
chmod -R g+r+w "${CLOUDSDK_INSTALL_PATH}"
find "${CLOUDSDK_INSTALL_PATH}" -type d -print0 | xargs -0 -n 1 chmod g+s

echo "Done!"
