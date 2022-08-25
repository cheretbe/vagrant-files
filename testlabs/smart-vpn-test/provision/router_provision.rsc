:global vmNICMACs

/ip dhcp-client set [find interface="host_nat"] use-peer-dns=no add-default-route=yes \
  default-route-distance=10

:local intnetMACaddr [:pick $vmNICMACs 2]
:if ([/interface ethernet get [find mac-address="$intnetMACaddr"] name] != "intnet") do={
  :put "Setting '$intnetMACaddr' interface name to 'intnet'"
  /interface ethernet set [find mac-address="$intnetMACaddr"] name="intnet"
}

:if ([:len [/ip address find interface="intnet" and address="192.168.80.81/24"]] = 0) do={
  :put "Adding IP 192.168.80.81/24 on interface 'intnet'"
  /ip address add address=192.168.80.81/24 interface="intnet"
}

:if ([:len [/ip address find interface="vlan_101"]] = 0) do={
  :put "Adding VLAN interface with ID 101"
  /interface vlan add interface=intnet name=vlan_101 vlan-id=101
}

:if ([:len [/ip address find interface="vlan_101" and address="192.168.101.1/24"]] = 0) do={
  :put "Adding IP 192.168.101.1/24 on interface 'vlan_101'"
  /ip address add address=192.168.101.1/24 interface=vlan_101 network=192.168.101.0
}

:if ([:len [/ip firewall address-list find list="antilock-sources" and address="192.168.80.0/24"]] = 0) do={
  :put "Adding 192.168.80.0/24 to 'antilock-sources'"
  /ip firewall address-list add address=192.168.80.0/24 list=antilock-sources
}

:if ([:len [/ip firewall address-list find list="antilock-targets" and address="13.32.0.0/15"]] = 0) do={
  :put "Adding 13.32.0.0/15 to 'antilock-targets'"
  /ip firewall address-list add address=13.32.0.0/15 list=antilock-targets
}
:if ([:len [/ip firewall address-list find list="antilock-targets" and address="65.9.0.0/17"]] = 0) do={
  :put "Adding 65.9.0.0/17 to 'antilock-targets'"
  /ip firewall address-list add address=65.9.0.0/17 list=antilock-targets
}

:if ([:len [/ip firewall mangle find chain="prerouting" and dst-address-list="force-no-antilock"]] = 0) do={
  :put "Adding mangle rule for 'force-no-antilock'"
  /ip firewall mangle add action=accept chain=prerouting \
    dst-address-list=force-no-antilock passthrough=no
}

:if ([:len [/ip firewall mangle find chain="prerouting" and src-address-list="antilock-sources" and dst-address-list="antilock-targets"]] = 0) do={
  :put "Adding mangle rule for 'antilock-sources' + 'antilock-targets'"
  /ip firewall mangle add action=mark-connection chain=prerouting \
    src-address-list=antilock-sources dst-address-list=antilock-targets \
    new-connection-mark=vpn_conn_mark \
    passthrough=yes
}

:if ([:len [/ip firewall mangle find chain="prerouting" and connection-mark="vpn_conn_mark" and in-interface="intnet"]] = 0) do={
  :put "Adding mangle rule for 'vpn_conn_mark'"
  /ip firewall mangle add action=mark-routing chain=prerouting \
    connection-mark=vpn_conn_mark in-interface=intnet \
    new-routing-mark=vpn_routing_mark \
    passthrough=no
}

:if ([:len [/ip firewall mangle find chain="forward" and connection-mark="vpn_conn_mark" and new-mss="1360"]] = 0) do={
  :put "Adding mangle rule for MSS change"
  /ip firewall mangle add action=change-mss chain=forward \
    connection-mark=vpn_conn_mark new-mss=1360 protocol=tcp \
      tcp-flags=syn tcp-mss=!0-1375 \
      passthrough=yes
}

:if ([:len [/ip route find gateway="192.168.101.2" and routing-mark="vpn_routing_mark"]] = 0) do={
  :put "Add route via 192.168.101.2 to 'vpn_routing_mark' table"
  /ip route add distance=1 gateway=192.168.101.2 routing-mark=vpn_routing_mark
}

:if ([:len [/ip firewall nat find action="masquerade" and out-interface="vlan_101"]] = 0) do={
  put "Adding NAT rule for 'vlan_101' interface"
  /ip firewall nat add action=masquerade chain=srcnat out-interface=vlan_101
}

:if ([:len [/ip firewall nat find action="masquerade" and out-interface="host_nat"]] = 0) do={
  put "Adding NAT rule for 'host_nat' interface"
  /ip firewall nat add action=masquerade chain=srcnat out-interface=host_nat src-address=192.168.80.0/24
}

:put "Setting DNS server to 192.168.101.2"
/ip dns set allow-remote-requests=yes servers=192.168.101.2
