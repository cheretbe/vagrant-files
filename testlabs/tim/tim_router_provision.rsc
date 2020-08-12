:global vmNICMACs
:local lanMACaddr [:pick $vmNICMACs 2]
:local wanMACaddr [:pick $vmNICMACs 3]

/system identity set name=tim-router

/interface ethernet set [find mac-address="$lanMACaddr"] name="lan"
/interface ethernet set [find mac-address="$wanMACaddr"] name="wan"

:if ([:len [/ip address find interface="lan" and address="192.168.2.1/24"]] = 0) do={
  :put "Adding 192.168.2.1/24 on 'lan'"
  /ip address add address="192.168.2.1/24" interface="lan"
}

:if ([:len [/ip address find interface="wan" and address="10.64.0.3/10"]] = 0) do={
  :put "Adding 10.64.0.3/10 on 'wan'"
  /ip address add address="10.64.0.3/10" interface="wan"
}

:if ([:len [/ip firewall nat find action="masquerade" and src-address="192.168.2.0/24"]] = 0) do={
  :put "Adding NAT rule for 192.168.2.0/24"
  /ip firewall nat add action=masquerade chain=srcnat src-address=192.168.2.0/24
}

:if ([:len [/ip firewall nat find action="dst-nat" and to-addresses="192.168.2.10" and dst-port="5555"]] = 0) do={
  :put "Adding Dst-NAT rule for 192.168.2.10:5555"
  /ip firewall nat add action=dst-nat chain=dstnat dst-port=5555 in-interface=wan protocol=tcp to-addresses=192.168.2.10
}

:if ([:len [/ip route find gateway="10.64.0.1"]] = 0) do={
  :put "Adding default route via 10.64.0.1"
  /ip route add distance=1 gateway=10.64.0.1
}