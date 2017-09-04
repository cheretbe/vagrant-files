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

echo "Fetching versions"
nagios_version=($(curl -s "https://www.nagios.org/checkforupdates/?product=nagioscore"| grep -Eo "is [0-9]{1}\.[0-9]{1}\.[0-9]{1}"))
nagios_version=${nagios_version[1]}
printf "Current Nagios version: %s\n" ${nagios_version}


if [ -e "/usr/local/nagios/bin/nagios" ]; then
  upgrade_mode=1
  local_nagios_version=($(/usr/local/nagios/bin/nagios --version | grep -Eo "Nagios Core [0-9]{1}\.[0-9]{1}\.[0-9]{1}"))
  local_nagios_version=${local_nagios_version[2]}
  printf "Local version: %s\n" ${local_nagios_version}
  if [ ${local_nagios_version} == ${nagios_version} ]; then
    echo "Latest Nagios version is already installed"
    exit 0
  else
    printf "Upgrading installation from version %s to %s\n" ${local_nagios_version} ${nagios_version}
  fi
else
  upgrade_mode=0
fi

exit 0

echo ${upgrade_mode}
if [ ${distro} == "centos" ]; then
  echo "remove"
#  yum install -y gcc glibc glibc-common wget unzip httpd php gd gd-devel
else
  apt update
fi

mkdir -p ~/temp/source
cd ~/temp/source

echo "Downloading"
#wget -nv -O nagios-${nagios_version}.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-${nagios_version}.tar.gz
tar xvf nagios-${nagios_version}.tar.gz

useradd nagios
usermod -a -G nagios apache

cd nagioscore-nagios-${nagios_version}
./configure
make all
make install
make install-init
make install-commandmode
make install-config
make install-webconf

systemctl enable nagios.service
systemctl enable httpd.service

htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin vagrant

systemctl start httpd.service
systemctl start nagios.service