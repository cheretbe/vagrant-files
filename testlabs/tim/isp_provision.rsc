:global vmNICMACs
:local wanMACaddr [:pick $vmNICMACs 2]

/system identity set name=isp

/interface ethernet set [find mac-address="$wanMACaddr"] name="wan"

:if ([:len [/ip address find interface="wan" and address="10.64.0.1/10"]] = 0) do={
  :put "Adding 10.64.0.1/10 on 'wan'"
  /ip address add address="10.64.0.1/10" interface="wan"
}

:if ([/ip dhcp-client get [find interface="host_nat"] add-default-route] != "yes") do={
  :put "Using default route on host's NAT interface"
  /ip dhcp-client set [find interface="host_nat"] add-default-route="yes"
}

:if ([:len [/ip firewall nat find action="masquerade" and src-address="10.64.0.0/10"]] = 0) do={
  :put "Adding NAT rule for 10.64.0.0/10"
  /ip firewall nat add action=masquerade chain=srcnat src-address=10.64.0.0/10
}
