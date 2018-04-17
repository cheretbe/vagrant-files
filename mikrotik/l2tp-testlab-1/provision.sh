#!/bin/bash

set -euo pipefail

if [ -z ${1+x} ]; then
  echo "Mandatory parameter is missing - 1: bridged NIC MAC address"
  exit 1
fi

for iface in $(ls /sys/class/net/); do
  mac_address=$(cat "/sys/class/net/${iface}/address")
  # Convert to upper case before comparing (^^)
  if [ "${mac_address^^}" == "${1}" ]; then
    bridged_iface=${iface}
  fi
done

# TODO: Do we need this at all?
echo "Bridged interface name: ${bridged_iface}"

apt-get -q update
apt-get -q -y install xl2tpd

if [ ! -e "/etc/xl2tpd/xl2tpd.conf.bak" ]; then
	echo "Creating backup copy '/etc/xl2tpd/xl2tpd.conf.bak'"
	cp /etc/xl2tpd/xl2tpd.conf /etc/xl2tpd/xl2tpd.conf.bak
fi

echo "Writing '/etc/xl2tpd/xl2tpd.conf'"
cat <<EOF > /etc/xl2tpd/xl2tpd.conf
[global]
listen-addr = 192.168.99.10

[lns default]
; Allocate from this IP range
ip range = 192.168.100.10-192.168.100.20
local ip = 192.168.100.1
length bit = yes
require chap = yes
refuse pap = yes
require authentication = yes
; Report this as our hostname
name = l2tp-test
; PPP option file name, otherwise it may use /etc/ppp/options by default
pppoptfile = /etc/ppp/options.xl2tpd
EOF

echo "Writing '/etc/ppp/options.xl2tpd'"
cat <<EOF > /etc/ppp/options.xl2tpd
mru 1450
mtu 1450
lcp-echo-interval 3
lcp-echo-failure 8
nodeflate
noproxyarp
lock
nodefaultroute
EOF

if ! grep -q testuser /etc/ppp/chap-secrets; then
  echo "Updating '/etc/ppp/chap-secrets'"
  # client   server   secret   IP addresses
  printf '\n"%s"\t*\t"%s"\t%s\n' "testuser" "secret" "192.168.100.9" >> /etc/ppp/chap-secrets
fi

echo "Restarting l2tpd service"
service l2tpd restart