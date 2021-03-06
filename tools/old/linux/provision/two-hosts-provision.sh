#!/bin/bash

set -euo pipefail

if [ $(hostname -s) == "host1" ]; then
  other_host_name="host2"
  other_host_ip="192.168.199.11"
else
  other_host_name="host1"
  other_host_ip="192.168.199.10"
fi

if ! grep -q ${other_host_name} /etc/hosts; then
  printf "Adding %s (%s) to /etc/hosts" ${other_host_name} ${other_host_ip}
  printf "%s  %s\n" ${other_host_ip} ${other_host_name} >>/etc/hosts
fi