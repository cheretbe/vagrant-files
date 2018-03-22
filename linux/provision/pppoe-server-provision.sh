#!/bin/bash

set -euo pipefail

if [ -z ${1+x} ]; then
  echo "Config file parameter is missing"
  exit 1
fi

source ${1}

# The interface with default route is NAT interface
host_nat_interface=$(ip route | awk '/default/ { print $5 }')

# The interface with no IP address is intnet interface
for iface in $(ifconfig -a | cut -d ' ' -f1| tr ':' '\n' | awk NF)
do
  if ! grep -q "inet addr:" <<< "$(ifconfig ${iface})"; then
    pppoe_interface=${iface}
  fi
done

echo "NAT interface name: ${host_nat_interface}"
echo "Client intnet interface name: ${pppoe_interface}"

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
  printf '\n"%s"\t*\t"%s"\t*\n' ${pppoe_user_name} ${pppoe_password} >> /etc/ppp/chap-secrets
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
#/sbin/iptables -t nat -A POSTROUTING -o ${host_nat_interface} -j MASQUERADE
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

if ! grep -q "route add -net ${other_isp_net}" /etc/rc.local; then
  echo "Updating '/etc/rc.local'"
  sed -i "s!exit 0!/sbin/route add -net ${other_isp_net} gw ${other_isp_gw}!" /etc/rc.local
  echo "exit 0" >> /etc/rc.local
fi

if ! grep -q "${other_isp_net}" <<< "$(ip route)"; then
  echo "Adding static route to ${other_isp_net}"
  /sbin/route add -net ${other_isp_net} gw ${other_isp_gw}
fi
