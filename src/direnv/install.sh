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

# Find user home
if [ "${USERNAME}" = "root" ]; then
	user_home="/root"
else
	# Find user home directory
	user_home="/home/${USERNAME}"
	if [ ! -d "${user_home}" ]; then
		mkdir -p "${user_home}"
		chown "${USERNAME}:${group_name}" "${user_home}"
	fi
fi

# Run Direnv installation script
curl -fsSL https://direnv.net/install.sh | bash

# Update a rc/profile file if it exists and string is not already present
update_rc_file() {
    # see if folder containing file exists
    local rc_file_folder="$(dirname "$1")"
    if [ ! -d "${rc_file_folder}" ]; then
        echo "${rc_file_folder} does not exist. Skipping update of $1."
    elif [ ! -e "$1" ] || [[ "$(cat "$1")" != *"$2"* ]]; then
        echo "$2" >> "$1"
    fi
}

# Instann Direnv hook
update_rc_file "$user_home/.bashrc" "eval \"\$(direnv hook bash)\""
update_rc_file "$user_home/.zshenv" "eval \"\$(direnv hook zsh)\""
update_rc_file "$user_home/.config/fish/config.fish" "direnv hook fish | source"

echo "Done!"
