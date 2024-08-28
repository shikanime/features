#!/bin/bash

set -e

VERSION="${VERSION:-"latest"}"

if [ "$(id -u)" -ne 0 ]; then
	echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
	exit 1
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
