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
# nagios_version="4.3.3"
printf "Current Nagios version: %s\n" ${nagios_version}

install_nagios_core=1
if [ -e "/usr/local/nagios/bin/nagios" ]; then
  core_upgrade_mode=1
  local_nagios_version=($(/usr/local/nagios/bin/nagios --version | grep -Eo "Nagios Core [0-9]{1}\.[0-9]{1}\.[0-9]{1}"))
  local_nagios_version=${local_nagios_version[2]}
  printf "Local version: %s\n" ${local_nagios_version}
  if [ ${local_nagios_version} == ${nagios_version} ]; then
    echo "Latest Nagios version is already installed"
    install_nagios_core=0
  else
    printf "Upgrading installation from version %s to %s\n" ${local_nagios_version} ${nagios_version}
  fi
else
  core_upgrade_mode=0
fi

printf "install_nagios_core: %s; core_upgrade_mode: %s\n" ${install_nagios_core} ${core_upgrade_mode}

if [ ${install_nagios_core} -ne 0 ]; then

  if [ ${distro} == "centos" ]; then
   yum install -y gcc glibc glibc-common wget unzip httpd php gd gd-devel
  else
    apt update
  fi

  mkdir -p ~/temp/source
  cd ~/temp/source

  echo "Downloading"
  wget -nv -O nagios-${nagios_version}.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-${nagios_version}.tar.gz
  tar xvf nagios-${nagios_version}.tar.gz

  if [ ${core_upgrade_mode} -ne 1 ]; then
    useradd nagios
    usermod -a -G nagios apache
  fi

  cd nagioscore-nagios-${nagios_version}
  ./configure
  make all

  if [ ${core_upgrade_mode} -eq 1 ]; then
    systemctl stop httpd.service
    systemctl stop nagios.service
  fi

  make install
  make install-commandmode

  if [ ${core_upgrade_mode} -ne 1 ]; then
    make install-init
    make install-config
    make install-webconf

    systemctl enable nagios.service
    systemctl enable httpd.service

    htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin vagrant
  fi

  systemctl start httpd.service
  systemctl start nagios.service
fi #install_nagios_core