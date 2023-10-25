#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

USERNAME="${USERNAME:-"automatic"}"
USER_UID="${USERUID:-"automatic"}"
USER_GID="${USERGID:-"automatic"}"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# If in automatic mode, determine if a user already exists, if not use vscode
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    if [ "${_REMOTE_USER}" != "root" ]; then
        USERNAME="${_REMOTE_USER}"
    else
        USERNAME=""
        POSSIBLE_USERS=("devcontainer" "vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
        for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
            if id -u ${CURRENT_USER} >/dev/null 2>&1; then
                USERNAME=${CURRENT_USER}
                break
            fi
        done
        if [ "${USERNAME}" = "" ]; then
            USERNAME=vscode
        fi
    fi
elif [ "${USERNAME}" = "none" ]; then
    USERNAME=root
    USER_UID=0
    USER_GID=0
fi

# Create or update a non-root user to match UID/GID.
group_name="${USERNAME}"
if id -u ${USERNAME} >/dev/null 2>&1; then
    # User exists, update if needed
    if [ "${USER_GID}" != "automatic" ] && [ "$USER_GID" != "$(id -g $USERNAME)" ]; then
        group_name="$(id -gn $USERNAME)"
        groupmod --gid $USER_GID ${group_name}
        usermod --gid $USER_GID $USERNAME
    fi
    if [ "${USER_UID}" != "automatic" ] && [ "$USER_UID" != "$(id -u $USERNAME)" ]; then
        usermod --uid $USER_UID $USERNAME
    fi
else
    # Create user
    if [ "${USER_GID}" = "automatic" ]; then
        groupadd $USERNAME
    else
        groupadd --gid $USER_GID $USERNAME
    fi
    if [ "${USER_UID}" = "automatic" ]; then
        useradd -s /bin/bash --gid $USERNAME -m $USERNAME
    else
        useradd -s /bin/bash --uid $USER_UID --gid $USERNAME -m $USERNAME
    fi
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

# Install Home in user context
su ${USERNAME} -c "sh <<EOF
# Container run without USER env variable set so we need to set it manually
# in oder to make home-manager work properly
export USER=\${USER:-\$(whoami)}

# Install Home
if ! command -v home-manager >/dev/null; then
	echo "Home Manager is not installed. Installing using nixpkgs..."
	nix run github:NixOS/nixpkgs/release-23.05#home-manager -- switch \
		--flake git+ssh://git@github.com/infinity-blackhole/shikanime \
		-b backup-before-nix
else
	echo "Home Manager is installed. Installing using Home Manager..."
	home-manager switch \
		--flake git+ssh://git@github.com/infinity-blackhole/shikanime \
		-b backup-before-nix
fi
EOF
"

echo "Done!"
