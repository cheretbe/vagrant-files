:global centralIspMACaddr
:global centralLanMACaddr

:if ([/system identity get name] != "central_router") do={
  :put "Setting identity to 'central_router'"
  /system identity set name="central_router"
}

:if ([/interface ethernet get [find mac-address="$centralIspMACaddr"] name] != "wan_phys") do={
  :put "Setting '$centralIspMACaddr' interface name to 'wan_phys'"
  /interface ethernet set [find mac-address="$centralIspMACaddr"] name="wan_phys"
}

:if ([/interface ethernet get [find mac-address="$centralLanMACaddr"] name] != "lan") do={
  :put "Setting '$centralLanMACaddr' interface name to 'lan'"
  /interface ethernet set [find mac-address="$centralLanMACaddr"] name="lan"
}

:if ([:len [/ip address find interface="wan_phys"]] = 0) do={
  :put "Adding IP 192.168.100.2/24 on interface 'wan_phys'"
  /ip address add address="192.168.100.2/24" interface="wan_phys"
}

:if ([:len [/ip address find interface="lan"]] = 0) do={
  :put "Adding IP 192.168.156.1/27 on interface 'lan'"
  /ip address add address="192.168.156.1/27" interface="lan"
}

:if ([:len [/interface l2tp-client find name="wan"]] = 0) do={
  :put "Adding L2TP connection to 192.168.100.1"
  /interface l2tp-client add name=wan add-default-route=yes allow=mschap2 \
    connect-to=192.168.100.1 disabled=no user=central password=central
}

:if ([:len [/ip firewall nat find action=masquerade and out-interface="wan"]] = 0) do={
  :put "Adding NAT rule for 192.168.156.0/27"
  /ip firewall nat add action=masquerade chain=srcnat \
    out-interface="wan" src-address=192.168.156.0/27
}

#:if ([:len [/ip route find gateway="192.168.53.1" and dst-address="0.0.0.0/0"]] = 0) do={
#  :put "Adding default route via 192.168.53.1"
#  /ip route add gateway=192.168.53.1
#}
