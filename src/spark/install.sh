#!/bin/bash

set -e

VERSION="${VERSION:-"latest"}"

export SPARK_HOME=${SPARK_HOME:-"/usr/local/spark"}

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

find_version_list() {
    version_list=$1
    all_versions=$(curl -s https://archive.apache.org/dist/spark/ | grep -oP "spark-[0-9].[0-9].[0-9][-\w]*" | tr -d ' ' | sed 's/spark-//g' | sort -rV)
    declare -g ${version_list}="$(echo "${all_versions}" | grep -oP "^[0-9]+\.[0-9]+\.[0-9]+$")"
}

# Find requested version
if [ "${VERSION}" == "latest" ]; then
    find_version_list version_list
    requested_version="$(echo "${version_list}" | head -n 1)"
else
    requested_version="${VERSION}"
fi

# Download Spark
mkdir -p /usr/local/spark
curl -fsSL \
    https://archive.apache.org/dist/spark/spark-${requested_version}/spark-${requested_version}-bin-hadoop3.tgz \
    | tar xz -C /usr/local/spark
ln -s /usr/local/spark/spark-${requested_version}-bin-hadoop3 /usr/local/spark/current

# Create spark group, dir, and set sticky bit
if ! cat /etc/group | grep -e "^spark:" > /dev/null 2>&1; then
	groupadd -r spark
fi
usermod -a -G spark ${USERNAME}
umask 0002
chown -R "${USERNAME}:spark" ${SPARK_HOME}
chmod -R g+r+w "${SPARK_HOME}"
find "${SPARK_HOME}" -type d -print0 | xargs -0 -n 1 chmod g+s

# Install Python path
python_env="$(
cat <<-EOF
    #!/bin/bash

    set -e

    # Resolve Spark P4J
    py4j_zip=$(find ${SPARK_HOME}/python/lib -name "py4j-*-src.zip" -print -quit)
    export PYTHONPATH="\${SPARK_HOME}/python:\${py4j_zip}"
EOF
)"
if [ ! -e "/usr/local/share/spark-python-env.sh" ]; then
    echo "(*) Setting up entrypoint..."
    echo "${python_env}" >/usr/local/share/spark-python-env.sh
    chmod +x /usr/local/share/spark-python-env.sh
fi
