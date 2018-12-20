:global pregolIspMACaddr
:global pregolLanMACaddr

:if ([/system identity get name] != "pregol_router") do={
  :put "Setting identity to 'pregol_router'"
  /system identity set name="pregol_router"
}

:if ([/interface ethernet get [find mac-address="$pregolIspMACaddr"] name] != "wan") do={
  :put "Setting '$pregolIspMACaddr' interface name to 'wan'"
  /interface ethernet set [find mac-address="$pregolIspMACaddr"] name="wan"
}

:if ([/interface ethernet get [find mac-address="$pregolLanMACaddr"] name] != "lan") do={
  :put "Setting '$pregolLanMACaddr' interface name to 'lan'"
  /interface ethernet set [find mac-address="$pregolLanMACaddr"] name="lan"
}

:if ([:len [/ip address find interface="wan"]] = 0) do={
  :put "Adding IP 192.168.53.2/24 on interface 'wan'"
  /ip address add address="192.168.53.2/24" interface="wan"
}

:if ([:len [/ip address find interface="lan"]] = 0) do={
  :put "Adding IP 192.168.156.33/27 on interface 'lan'"
  /ip address add address="192.168.156.33/27" interface="lan"
}

:if ([:len [/ip firewall nat find action=masquerade and out-interface="wan"]] = 0) do={
  :put "Adding NAT rule for 192.168.156.32/27"
  /ip firewall nat add action=masquerade chain=srcnat \
    out-interface="wan" src-address=192.168.156.32/27
}

:if ([:len [/ip route find gateway="192.168.53.1" and dst-address="0.0.0.0/0"]] = 0) do={
  :put "Adding default route via 192.168.53.1"
  /ip route add gateway=192.168.53.1
}