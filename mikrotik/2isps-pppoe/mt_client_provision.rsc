:if ([/interface ethernet get [find default-name="ether3"] name] != "wan1_phys") do={
  :put "Setting 'ether3' interface name to 'wan1_phys'"
  /interface ethernet set [find default-name="ether3"] name="wan1_phys"
}

:if ([/interface ethernet get [find default-name="ether4"] name] != "wan2_phys") do={
  :put "Setting 'ether4' interface name to 'wan2_phys'"
  /interface ethernet set [find default-name="ether4"] name="wan2_phys"
}