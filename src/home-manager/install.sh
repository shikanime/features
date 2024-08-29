#!/bin/bash

set -e

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
MULTIUSER="${MULTIUSER:-"true"}"
FLAKEURI="${FLAKEURI:-"none"}"

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
	# Fix permissions
	if [ ! -d "${user_home}" ]; then
		mkdir -p "${user_home}"
		chown "${USERNAME}:${group_name}" "${user_home}"
	fi
	# Create per-user profile as it may not have been created by default in
	# container environment
	user_nix_profile="/nix/var/nix/profiles/per-user/${USERNAME}"
	if [[ ! -d "${user_nix_profile}" ]]; then
		echo "Creating per-user profile..."
		mkdir -p "${user_nix_profile}"
		chown "${USERNAME}:${group_name}" "${user_nix_profile}"
	fi
fi

# Create hook to install Home if specified
if [ ! -z "${FLAKEURI}" ] && [ "${FLAKEURI}" != "none" ]; then
	install_script="$(
		cat <<-EOF
			#!/bin/bash

			set -e

			# Container run without USER env variable set so we need to set it manually
			# in oder to make home-manager work properly
			export USER="\${USER:-\$(whoami)}"

			# Install Nix flake in profile if specified
			echo "Installing flake ${FLAKEURI} in profile..."
			nix run home-manager -- switch --flake "${FLAKEURI}" -b backup-before-nix --refresh
		EOF
	)"
	if [ ! -e "/usr/local/share/catbox-install-home.sh" ]; then
		echo "(*) Setting up entrypoint..."
		echo "${install_script}" >/usr/local/share/catbox-install-home.sh
		chmod +x /usr/local/share/catbox-install-home.sh
	fi
fi

echo "Done!"
