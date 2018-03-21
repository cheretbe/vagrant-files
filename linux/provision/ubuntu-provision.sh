#!/bin/bash

set -euo pipefail

# Fix for "dpkg-preconfigure: unable to re-open stdin: No such file or directory" error
# https://serverfault.com/questions/500764/dpkg-reconfigure-unable-to-re-open-stdin-no-file-or-directory/670688#670688
export DEBIAN_FRONTEND=noninteractive

apt-get -q update
apt-get -y -q dist-upgrade
apt-get -y -q install mc nano wget htop
apt-get -y -q autoremove