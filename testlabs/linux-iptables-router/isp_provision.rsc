:global vmNICMACs
:local ispNetMACaddr [:pick $vmNICMACs 2]

:if ([/system identity get name] != "isp") do={
  :put "Setting identity to 'isp'"
  /system identity set name=isp
}

/ip dhcp-client set [find interface="host_nat"] use-peer-dns=yes add-default-route=yes
