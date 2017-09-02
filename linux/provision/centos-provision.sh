#!/bin/bash

set -euo pipefail

# Disable SELinux
if [ $(getenforce) != "Disabled" ]; then
  echo "Disabling SELinux"
  setenforce 0
  sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config
fi

yum update -y
yum install -y epel-release
yum install -y mc nano wget net-tools htop