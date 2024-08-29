#!/bin/bash

set -e

COMPONENTS="${COMPONENTS:-"none"}"

export CLOUDSDK_INSTALL_DIR="${INSTALLPATH:-"/usr/local/google-cloud-sdk"}"

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"

if [ "$(id -u)" -ne 0 ]; then
	echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
	exit 1
fi

# Ensure CLOUDSDK_INSTALL_DIR ends with 'google-cloud-sdk'
if [[ ! "${CLOUDSDK_INSTALL_DIR}" =~ google-cloud-sdk$ ]]; then
	echo -e 'CLOUDSDK_INSTALL_DIR must end with "google-cloud-sdk".'
	exit 1
fi
CLOUDSDK_INSTALL_DIR=$(echo "${CLOUDSDK_INSTALL_DIR}" | sed 's/\/google-cloud-sdk$//')

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

# Run Google Cloud CLI installation scriptOVERRIDE_DEFAULT_VERSION
curl -fsSL https://sdk.cloud.google.com | bash -s -- \
	--disable-prompts

# Install list of components if specified.
if [ ! -z "${COMPONENTS}" ] && [ "${COMPONENTS}" != "none" ]; then
	su ${USERNAME} -c "gcloud components install \"${COMPONENTS}\""
fi

# Create gcloud group, dir, and set sticky bit
if ! cat /etc/group | grep -e "^gcloud:" > /dev/null 2>&1; then
	groupadd -r gcloud
fi
usermod -a -G gcloud ${USERNAME}
umask 0002
chown -R "${USERNAME}:gcloud" "${CLOUDSDK_INSTALL_DIR}/google-cloud-sdk"
chmod -R g+r+w "${CLOUDSDK_INSTALL_DIR}/google-cloud-sdk"
find "${CLOUDSDK_INSTALL_DIR}/google-cloud-sdk" -type d -print0 | xargs -0 -n 1 chmod g+s

echo "Done!"
