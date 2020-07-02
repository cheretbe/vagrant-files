#!/bin/bash

set -euo pipefail

function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

conflicting_packages=( "virtualbox-guest-dkms" "virtualbox-guest-utils"
  "virtualbox-guest-x11"
)

packages_to_uninstall=()

for package_name in "${conflicting_packages[@]}"
do
  if [ $(dpkg-query -W -f='${Status}' ${package_name} 2>/dev/null | grep -c "ok installed") -ne 0 ]; then
    echo "'${package_name}' package will be removed"
    packages_to_uninstall+=(${package_name})
  fi
done

if [ ${#packages_to_uninstall[@]} -ne 0 ]; then
  apt-get -y -q purge ${packages_to_uninstall[@]}
fi

host_vbox_version=""
host_vbox_version=$(dmidecode -t 11 | grep "vboxVer" | awk -F": vboxVer_" '{print $2}')
if [ "${host_vbox_version}" == "" ]; then
  echo "Cannot detect VirtualBox version. Make sure this script runs in a VirtualBox VM"
  exit 1
fi

# host_vbox_version="5.2.6"

installation_needed=1
if [ -e "/usr/bin/VBoxControl" ]; then
  additions_version=$(/usr/bin/VBoxControl --nologo version | awk -F"r" '{print $1}')
  if version_gt ${host_vbox_version} ${additions_version}; then
    echo "Guest Additions need to be upgraded (${additions_version} ==> ${host_vbox_version})"
  else
    echo "Guest Additions do not need an upgrade (VB version: ${host_vbox_version}, Additions version: ${additions_version})"
    installation_needed=0
  fi
else
  echo "No Guest Additions installation has been found"
fi

if [ ${installation_needed} -eq 1 ]; then
  # Fix for "dpkg-preconfigure: unable to re-open stdin: No such file or directory" error
  # https://serverfault.com/questions/500764/dpkg-reconfigure-unable-to-re-open-stdin-no-file-or-directory/670688#670688
  export DEBIAN_FRONTEND=noninteractive

  apt-get -q update
  apt-get -q -y install dkms build-essential
  echo "Downloading 'http://download.virtualbox.org/virtualbox/${host_vbox_version}/VBoxGuestAdditions_${host_vbox_version}.iso'"
  wget -nv http://download.virtualbox.org/virtualbox/${host_vbox_version}/VBoxGuestAdditions_${host_vbox_version}.iso -O /tmp/VBoxGuestAdditions_${host_vbox_version}.iso
  mkdir -p /mnt/iso
  mount -o loop,ro /tmp/VBoxGuestAdditions_${host_vbox_version}.iso /mnt/iso

  # It seems that VBoxLinuxAdditions.run returns non-zero exit code even on
  # successful installation. As a workaround we don't check the exit code and
  # decide whether the installation has failed or not by kernel module presence.
  # https://stackoverflow.com/questions/25434139/vboxlinuxadditions-run-never-exits-with-0
  /mnt/iso/VBoxLinuxAdditions.run || true
  umount /mnt/iso
  rm -f /tmp/VBoxGuestAdditions_${host_vbox_version}.iso

  if [ -e /lib/modules/$(uname -r)/misc/vboxsf.ko ]; then
    echo "Guest Additions installation was successful"
  else
    echo "Guest Additions installation has failed"
    exit 1
  fi
fi