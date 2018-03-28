#!/bin/bash

set -euo pipefail

if [ -z ${1+x} ]; then
  echo "Mandatory parameter is missing - 1: Config file path"
  exit 1
fi

source ${1}

if [ -z ${2+x} ]; then
  echo "Mandatory parameter is missing - 2: NAT interface MAC address"
  exit 1
fi

if [ -z ${3+x} ]; then
  echo "Mandatory parameter is missing - 3: Client PPPoE interface MAC address"
  exit 1
fi

if [ -z ${4+x} ]; then
  echo "Mandatory parameter is missing - 4: 'vagrant-inter_isp-intnet' interface MAC address"
  exit 1
fi

for iface in $(ls /sys/class/net/); do
  mac_address=$(cat "/sys/class/net/${iface}/address")
  # Convert to upper case before comparing (^^)
  if [ "${mac_address^^}" == "${2}" ]; then
    host_nat_interface=${iface}
  fi
  if [ "${mac_address^^}" == "${3}" ]; then
    pppoe_interface=${iface}
  fi
  if [ "${mac_address^^}" == "${4}" ]; then
    inter_isp_interface=${iface}
  fi
done

echo "NAT interface name: ${host_nat_interface}"
echo "Client intnet interface name: ${pppoe_interface}"
echo "'vagrant-inter_isp-intnet' interface name: ${inter_isp_interface}"

apt-get -q update
apt-get -q -y install pppoe supervisor

echo "Writing '/etc/ppp/pppoe-server-options'"
cat << EOF > /etc/ppp/pppoe-server-options
auth
require-chap
lcp-echo-interval 10
lcp-echo-failure 2
# DNS servers that our pppoe server will serve to clients 
ms-dns ${pppoe_dns_1}
ms-dns ${pppoe_dns_2}
noipdefault
noipx
nodefaultroute
noproxyarp
# Netmask that clients will receive
netmask 255.255.255.255
logfile /var/log/pppoe.log
EOF

if ! grep -q ${pppoe_user_name} /etc/ppp/chap-secrets; then
  echo "Updating '/etc/ppp/chap-secrets'"
  # client   server   secret   IP addresses
  printf '\n"%s"\t*\t"%s"\t%s\n' ${pppoe_user_name} ${pppoe_password} ${pppoe_client_static_ip} >> /etc/ppp/chap-secrets
fi

echo "Writing '/opt/pppoe-server.sh'"
cat << EOF > /opt/pppoe-server.sh
#!/bin/bash

_term() {
  echo "Caught SIGTERM signal"
  echo "Stopping pppoe-server"
  killall pppoe-server 2>/dev/null
  echo "Disabling routing"
  echo 0 > /proc/sys/net/ipv4/ip_forward
  iptables --table nat --delete POSTROUTING -s ${pppoe_network} --out-interface ${host_nat_interface} -j MASQUERADE
  exit 0
}

trap _term SIGTERM
ifconfig ${pppoe_interface} 0.0.0.0 up
echo "Starting pppoe-server"
pppoe-server -I ${pppoe_interface} -L ${pppoe_ip} -R ${pppoe_dhcp_start}
echo "Enabling routing"
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables --table nat --append POSTROUTING -s ${pppoe_network} --out-interface ${host_nat_interface} -j MASQUERADE

while true
do
  sleep 1
done
EOF

chmod +x /opt/pppoe-server.sh

echo "Writing '/etc/supervisor/conf.d/pppoe-server.conf'"
cat << EOF > /etc/supervisor/conf.d/pppoe-server.conf
[program:pppoe-server]
command=bash -c /opt/pppoe-server.sh
autostart=true
stdout_logfile=/var/log/supervisor/pppoe-server.log
redirect_stderr=true
#stopasgroup=true
EOF

supervisorctl reread
supervisorctl update
# Restart pppoe-server in case /opt/pppoe-server.sh script has changed
supervisorctl restart pppoe-server

echo "Writing '/etc/network/interfaces.d/${inter_isp_interface}.cfg'"
cat << EOF > /etc/network/interfaces.d/${inter_isp_interface}.cfg
auto ${inter_isp_interface}
  iface ${inter_isp_interface} inet static
  address ${inter_isp_ip}
  netmask 255.255.255.0
  up /sbin/route add -net ${other_isp_net} gw ${other_isp_gw} || true
EOF
# Restart networking in case the config has changed
echo "Restarting network"
service networking restart