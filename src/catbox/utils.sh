# If in automatic mode, determine if a user already exists, if not use root
detect_user() {
    local user_variable_name=${1:-username}
    local possible_users=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    if [ "${!user_variable_name}" = "auto" ] || [ "${!user_variable_name}" = "automatic" ]; then
        declare -g ${user_variable_name}=""
        for current_user in ${possible_users[@]}; do
            if id -u "${current_user}" >/dev/null 2>&1; then
                declare -g ${user_variable_name}="${current_user}"
                break
            fi
        done
    fi
    if [ "${!user_variable_name}" = "" ] || [ "${!user_variable_name}" = "none" ] || ! id -u "${!user_variable_name}" >/dev/null 2>&1; then
        declare -g ${user_variable_name}=root
    fi
}
