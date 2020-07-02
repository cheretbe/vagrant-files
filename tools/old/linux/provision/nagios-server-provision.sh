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

# TODO: NSCA server
# https://support.nagios.com/kb/article/nsca-server-centos-6-5-and-nagios-core-4-0-x.html
# ../nagios-test-lab-centos/server-provision.old.2del 

if [ ${distro} == "centos" ]; then
  apache_service_name="httpd"
  apache_user_name="apache"
else
  apache_service_name="apache2"
  apache_user_name="www-data"
fi


echo "Fetching versions"
nagios_version=($(curl -s "https://www.nagios.org/checkforupdates/?product=nagioscore"| grep -Eo "is [0-9]{1}\.[0-9]{1}\.[0-9]{1}"))
nagios_version=${nagios_version[1]}
# nagios_version="4.3.3"
printf "Current Nagios version: %s\n" ${nagios_version}
plugins_version=($(curl -s "https://www.nagios.org/downloads/nagios-plugins/"| grep -Eo "Plugins [0-9]{1}\.[0-9]{1}\.[0-9]{1}"))
plugins_version=${plugins_version[1]}
# plugins_version="2.2.0"
printf "Current plugins version: %s\n" ${plugins_version}

install_nagios_core=1
if [ -e "/usr/local/nagios/bin/nagios" ]; then
  core_upgrade_mode=1
  local_nagios_version=($(/usr/local/nagios/bin/nagios --version | grep -Eo "Nagios Core [0-9]{1}\.[0-9]{1}\.[0-9]{1}"))
  local_nagios_version=${local_nagios_version[2]}
  printf "Local Nagios version: %s\n" ${local_nagios_version}
  if [ ${local_nagios_version} == ${nagios_version} ]; then
    echo "Latest Nagios version is already installed"
    install_nagios_core=0
  else
    printf "Upgrading installation from version %s to %s\n" ${local_nagios_version} ${nagios_version}
  fi
else
  core_upgrade_mode=0
fi

# printf "install_nagios_core: %s; core_upgrade_mode: %s\n" ${install_nagios_core} ${core_upgrade_mode}
if [ ${install_nagios_core} -ne 0 ]; then

  if [ ${distro} == "centos" ]; then
   yum install -y gcc glibc glibc-common wget unzip httpd php gd gd-devel
  else
    apt-get update
    apt-get install -y autoconf gcc libc6 make wget unzip apache2 php libapache2-mod-php7.0 libgd2-xpm-dev
  fi

  mkdir -p ~/temp/source
  cd ~/temp/source

  echo "Downloading nagios-${nagios_version}.tar.gz"
  wget -nv -O nagios-${nagios_version}.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-${nagios_version}.tar.gz
  tar xvf nagios-${nagios_version}.tar.gz

  if [ ${core_upgrade_mode} -ne 1 ]; then
    useradd nagios
    usermod -a -G nagios ${apache_user_name}
  fi

  cd nagioscore-nagios-${nagios_version}
  ./configure
  make all

  if [ ${core_upgrade_mode} -eq 1 ]; then
    service ${apache_service_name} stop
    service nagios stop
  fi

  make install
  make install-commandmode

  if [ ${core_upgrade_mode} -ne 1 ]; then
    make install-init
    make install-config
    make install-webconf

    if [ ${distro} == "centos" ]; then
      systemctl enable nagios.service
      systemctl enable httpd.service
    else
      update-rc.d nagios defaults
      service apache2 stop
      a2enmod rewrite
      a2enmod cgi
    fi

    htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin vagrant
  fi

  service ${apache_service_name} start
  service nagios start
fi #install_nagios_core

install_plugins=1
if [ -e "/usr/local/nagios/libexec/check_dummy" ]; then
  local_plugins_version=($(/usr/local/nagios/libexec/check_dummy -V | grep -Eo "nagios-plugins [0-9]{1}\.[0-9]{1}\.[0-9]{1}"))
  local_plugins_version=${local_plugins_version[1]}
  printf "Local plugins version: %s\n" ${local_plugins_version}
  if [ ${local_plugins_version} == ${plugins_version} ]; then
    echo "Latest plugins version is already installed"
    install_plugins=0
  else
    printf "Upgrading plugins from version %s to %s\n" ${local_plugins_version} ${plugins_version}
  fi
fi

if [ ${install_plugins} -ne 0 ]; then
  if [ ${distro} == "centos" ]; then
   yum install -y gcc glibc glibc-common make gettext automake autoconf wget openssl-devel net-snmp net-snmp-utils epel-release perl-Net-SNMP
  else
    apt-get update
    apt-get -y install autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext
  fi

  echo "Downloading release-${plugins_version}.tar.gz"
  wget -nv -O plugins-${plugins_version}.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-${plugins_version}.tar.gz
  tar xvf plugins-${plugins_version}.tar.gz

  cd nagios-plugins-release-${plugins_version}
  ./tools/setup
  ./configure
  make
  service nagios stop
  make install
  service nagios start
fi #install_plugins