:if ([/interface ethernet get [find default-name="ether3"] name] != "wan1_phys") do={
  :put "Setting 'ether3' interface name to 'wan1_phys'"
  /interface ethernet set [find default-name="ether3"] name="wan1_phys"
}

:if ([/interface ethernet get [find default-name="ether4"] name] != "wan2_phys") do={
  :put "Setting 'ether4' interface name to 'wan2_phys'"
  /interface ethernet set [find default-name="ether4"] name="wan2_phys"
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