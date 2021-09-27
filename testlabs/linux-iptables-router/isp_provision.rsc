:global vmNICMACs
:local ispNetMACaddr [:pick $vmNICMACs 2]

:if ([/system identity get name] != "isp") do={
  :put "Setting identity to 'isp'"
  /system identity set name=isp
}

/ip dhcp-client set [find interface="host_nat"] use-peer-dns=yes add-default-route=yes

:if ([/interface ethernet get [find mac-address="$ispNetMACaddr"] name] != "isp_net") do={
  :put "Setting '$ispNetMACaddr' interface name to 'isp_net'"
  /interface ethernet set [find mac-address="$ispNetMACaddr"] name="isp_net"
}

:if ([:len [/ip address find interface="isp_net" and address="192.168.78.1/24"]] = 0) do={
  :put "Adding IP 192.168.78.1/24 on interface 'isp_net'"
  /ip address add address="192.168.78.1/24" interface="isp_net"
}

:if ([:len [/ip firewall nat find action=masquerade and src-address="192.168.78.0/24"]] = 0) do={
  :put "Adding NAT rule for 192.168.78.0/24"
  /ip firewall nat add action=masquerade chain=srcnat ipsec-policy=out,none \
    out-interface=host_nat src-address=192.168.78.0/24
}

/ip dns set allow-remote-requests=yes
