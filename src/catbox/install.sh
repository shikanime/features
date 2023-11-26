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

# Fix permissions
if [ "${USERNAME}" = "root" ]; then
    user_home="/root"
else
    # Find user home directory
    user_home="/home/${USERNAME}"
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
if [ ! -e "/usr/local/share/catbox-install-home.sh" ]; then
    if [ "${MULTIUSER}" = "true" ]; then
        echo "(*) Setting up entrypoint..."
        cp -f catbox-install-home.sh /usr/local/share/
    else
        echo -e '#!/bin/bash\nexec "$@"' > /usr/local/share/catbox-install-home.sh
    fi
    chmod +x /usr/local/share/catbox-install-home.sh
fi

# Create cache folders with correct privs in case a volume is mounted here
cache_folders=(".cache/pip" ".cache/npm" ".cache/mix" ".cache/huggingface")
for folder in "${cache_folders[@]}"; do
    mkdir -p "${user_home}/${folder}"
    chown -R ${USERNAME} "${user_home}/${folder}"
    chmod -R u+wrx "${user_home}/${folder}"
done

echo "Done!"
