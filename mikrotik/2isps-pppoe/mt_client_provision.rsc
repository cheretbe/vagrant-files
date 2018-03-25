:global isp1MACaddr
:global isp2MACaddr
:global lanMACaddr

:if ([/interface ethernet get [find mac-address="$lanMACaddr"] name] != "lan") do={
  :put "Setting '$lanMACaddr' interface name to 'lan'"
  /interface ethernet set [find mac-address="$lanMACaddr"] name="lan"
}

:if ([/interface ethernet get [find mac-address="$isp1MACaddr"] name] != "wan1_phys") do={
  :put "Setting '$isp1MACaddr' interface name to 'wan1_phys'"
  /interface ethernet set [find mac-address="$isp1MACaddr"] name="wan1_phys"
}

:if ([/interface ethernet get [find mac-address="$isp2MACaddr"] name] != "wan2_phys") do={
  :put "Setting '$isp2MACaddr' interface name to 'wan2_phys'"
  /interface ethernet set [find mac-address="$isp2MACaddr"] name="wan2_phys"
}

:if ([:len [/interface pppoe-client find name="wan1"]] = 0) do={
  :put "Adding PPPoE interface 'wan1'"
  /interface pppoe-client
  add add-default-route=yes disabled=no interface=wan1_phys name=wan1 password=password user=isp1_user
}

:if ([:len [/interface pppoe-client find name="wan2"]] = 0) do={
  :put "Adding PPPoE interface 'wan2'"
  /interface pppoe-client
  add add-default-route=yes disabled=yes default-route-distance=10 interface=wan2_phys name=wan2 password=password user=isp2_user
}

:put "Setting identity to 'mt_client'"
/system identity set name="mt_client"