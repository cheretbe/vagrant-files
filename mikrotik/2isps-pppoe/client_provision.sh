#!/bin/bash

set -euo pipefail

for iface in $(ifconfig -a | cut -d ' ' -f1| tr ':' '\n' | awk NF)
do
  if_ip_addr=$(ifconfig ${iface} | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
  echo "${iface}: ${if_ip_addr}"
  if [ "${if_ip_addr:0:4}" == "10.0" ]; then
    nat_if_name=${iface}
  fi
  if [ "${if_ip_addr:0:4}" == "172." ]; then
    lan_if_name=${iface}
  fi
done

echo "NAT interface name: ${nat_if_name}"
echo "LAN interface name: ${lan_if_name}"

if ! grep -q 'send dhcp-client-identifier "client"' /etc/dhcp/dhclient.conf; then
	echo "Updating '/etc/dhcp/dhclient.conf'"
	cat <<-EOF >> /etc/dhcp/dhclient.conf

		interface "${nat_if_name}" {
			supersede domain-name-servers 172.25.0.1;
			supersede routers 172.25.0.1;
		}
		interface "${lan_if_name}" {
			send dhcp-client-identifier "client";
		}
	EOF
  echo "Restarting network"
  service networking restart
fi