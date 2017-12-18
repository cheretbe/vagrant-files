#!/bin/bash

set -euo pipefail

apt-get update
apt-get -y dist-upgrade
apt-get -y install mc nano wget htop
apt-get -y autoremove