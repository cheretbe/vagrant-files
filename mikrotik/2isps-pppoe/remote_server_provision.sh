#!/bin/bash

set -euo pipefail

if ! grep -q "route add -net 192.168.51.0/24" /etc/rc.local; then
  echo "Updating '/etc/rc.local' (static route to 192.168.51.0/24)"
  sed -i "s!^exit 0!/sbin/route add -net 192.168.51.0/24 gw 172.24.0.1!" /etc/rc.local
  echo "exit 0" >> /etc/rc.local
fi

if ! grep -q "route add -net 192.168.52.0/24" /etc/rc.local; then
  echo "Updating '/etc/rc.local' (static route to 192.168.52.0/24)"
  sed -i "s!^exit 0!/sbin/route add -net 192.168.52.0/24 gw 172.24.0.2!" /etc/rc.local
  echo "exit 0" >> /etc/rc.local
fi

if ! grep -q "192.168.51.0/24" <<< "$(ip route)"; then
  echo "Adding static route to 192.168.51.0/24"
  route add -net 192.168.51.0/24 gw 172.24.0.1
fi

if ! grep -q "192.168.52.0/24" <<< "$(ip route)"; then
  echo "Adding static route to 192.168.52.0/24"
  route add -net 192.168.52.0/24 gw 172.24.0.2
fi