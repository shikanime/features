#!/bin/bash

set -e

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
MULTIUSER="${MULTIUSER:-"true"}"
FEATURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} >/dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} >/dev/null 2>&1; then
    USERNAME=root
fi

# Fix permissions
if [ "${USERNAME}" = "root" ]; then
    user_home="/root"
else
    # Find user home directory
    user_home="/home/${USERNAME}"
    if [ ! -d "${user_home}" ]; then
        mkdir -p "${user_home}"
        chown ${USERNAME}:${group_name} "${user_home}"
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

# Install Home if specified
chmod +x,o+r ${FEATURE_DIR} ${FEATURE_DIR}/post-install-steps.sh
if [ "${MULTIUSER}" = "true" ]; then
    /usr/local/share/nix-entrypoint.sh
    su ${USERNAME} -c "
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        ${FEATURE_DIR}/post-install-steps.sh
    "
else
    su ${USERNAME} -c "
        . \$HOME/.nix-profile/etc/profile.d/nix.sh
        ${FEATURE_DIR}/post-install-steps.sh
    "
fi

echo "Done!"
