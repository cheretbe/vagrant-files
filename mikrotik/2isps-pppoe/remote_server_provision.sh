#!/bin/bash

set -euo pipefail

if [ -z ${1+x} ]; then
  echo "Mandatory parameter is missing - 1: 'vagrant-inter_isp-intnet' NIC MAC address"
  exit 1
fi

for iface in $(ls /sys/class/net/); do
  mac_address=$(cat "/sys/class/net/${iface}/address")
  # Convert to upper case before comparing (^^)
  if [ "${mac_address^^}" == "${1}" ]; then
    inter_isp_iface=${iface}
  fi
done

echo "'vagrant-inter_isp-intnet' interface name: ${inter_isp_iface}"

if [ ! -e "/etc/network/interfaces.d/${inter_isp_iface}.cfg" ]; then
	echo "Creating '/etc/network/interfaces.d/${inter_isp_iface}.cfg'"
	cat <<-EOF > /etc/network/interfaces.d/${inter_isp_iface}.cfg
		auto ${inter_isp_iface}
		iface ${inter_isp_iface} inet static
		address 172.24.0.3
		netmask 255.255.255.0
		up /sbin/route add -net 192.168.51.0/24 gw 172.24.0.1 || true
		up /sbin/route add -net 192.168.52.0/24 gw 172.24.0.2 || true
	EOF
	echo "Restarting network"
	service networking restart
fi