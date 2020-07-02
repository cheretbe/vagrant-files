:global yantarIspMACaddr
:global yantarLanMACaddr

:if ([/system identity get name] != "yantar_router") do={
  :put "Setting identity to 'yantar_router'"
  /system identity set name="yantar_router"
}

:if ([/interface ethernet get [find mac-address="$yantarIspMACaddr"] name] != "wan") do={
  :put "Setting '$yantarIspMACaddr' interface name to 'wan'"
  /interface ethernet set [find mac-address="$yantarIspMACaddr"] name="wan"
}

:if ([/interface ethernet get [find mac-address="$yantarLanMACaddr"] name] != "lan") do={
  :put "Setting '$yantarLanMACaddr' interface name to 'lan'"
  /interface ethernet set [find mac-address="$yantarLanMACaddr"] name="lan"
}

:if ([:len [/ip address find interface="wan"]] = 0) do={
  :put "Adding IP 192.168.56.2/24 on interface 'wan'"
  /ip address add address="192.168.56.2/24" interface="wan"
}

:if ([:len [/ip address find interface="lan"]] = 0) do={
  :put "Adding IP 192.168.156.97/27 on interface 'lan'"
  /ip address add address="192.168.156.97/27" interface="lan"
}

:if ([:len [/ip firewall nat find action=masquerade and out-interface="wan"]] = 0) do={
  :put "Adding NAT rule for 192.168.156.96/27"
  /ip firewall nat add action=masquerade chain=srcnat \
    out-interface="wan" src-address=192.168.156.96/27
}

:if ([:len [/ip route find gateway="192.168.56.1" and dst-address="0.0.0.0/0"]] = 0) do={
  :put "Adding default route via 192.168.56.1"
  /ip route add gateway=192.168.56.1
}