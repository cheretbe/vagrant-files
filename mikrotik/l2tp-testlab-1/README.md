```shell
# Server
# Ethernet direct route (no NAT)
route add -net 192.168.101.0/24 gw 192.168.99.11
# L2TP direct route (no NAT)
route delete -net 192.168.101.0/24 gw 192.168.99.11
route add -net 192.168.101.0/24 gw 192.168.100.9
# NAT
route delete -net 192.168.101.0/24 gw 192.168.99.11
route delete -net 192.168.101.0/24 gw 192.168.100.9

# Client
route add -net 192.168.99.0/24 gw 192.168.101.11
route add -net 192.168.100.0/24 gw 192.168.101.11
```

NAT rules
```
/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether1
add action=masquerade chain=srcnat out-interface=l2tp-out1
add action=dst-nat chain=dstnat dst-port=5001 in-interface=!ether2 protocol=tcp \
    to-addresses=192.168.101.12
```