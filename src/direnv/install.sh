#!/bin/bash

set -e

if [ "$(id -u)" -ne 0 ]; then
	echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
	exit 1
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
update_rc_file "$home_dir/.bashrc" "eval \"\$(direnv hook bash)\""
update_rc_file "$home_dir/.zshenv" "eval \"\$(direnv hook zsh)\""
update_rc_file "$home_dir/.config/fish/config.fish" "direnv hook fish | source"

echo "Done!"
