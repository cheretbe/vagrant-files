:global PregolIspMACaddr
#:global lanMACaddr

:if ([/system identity get name] != "pregol_router") do={
  :put "Setting identity to 'pregol_router'"
  /system identity set name="pregol_router"
}

:if ([/interface ethernet get [find mac-address="$PregolIspMACaddr"] name] != "wan") do={
  :put "Setting '$PregolIspMACaddr' interface name to 'wan'"
  /interface ethernet set [find mac-address="$interIspMACaddr"] name="wan"
}

:if ([:len [/ip address find interface="wan"]] = 0) do={
  :put "Adding IP 192.168.53.2/24 on interface 'wan'"
  /ip address add address="192.168.53.2/24" interface="wan"
}