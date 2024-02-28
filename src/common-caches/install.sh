#!/bin/bash

set -e

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

# Find user home directory
if [ "${USERNAME}" = "root" ]; then
	user_home="/root"
else
	user_home="/home/${USERNAME}"
fi

# Create cache folders with correct privs in case a volume is mounted here
cache_folders=(".cache" ".cache/pip" ".cache/npm" ".cache/mix" ".cache/nix" ".cache/huggingface")
for folder in "${cache_folders[@]}"; do
	mkdir -p "${user_home}/${folder}"
	chown -R "${USERNAME}:${USERNAME}" "${user_home}/${folder}"
	chmod -R u+rwx "${user_home}/${folder}"
done

echo "Done!"
