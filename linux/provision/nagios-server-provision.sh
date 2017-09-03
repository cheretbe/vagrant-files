#!/bin/bash

set -euo pipefail

if [ -e "/etc/centos-release" ]; then
  distro="centos"
elif [ -e "/etc/debian_version" ]; then
  distro="debian"
  if grep -q Ubuntu /etc/os-release; then distro="ubuntu"; fi
else
  >&2 echo "Unsupported Linux distribution"
  exit 1
fi

echo ${distro}