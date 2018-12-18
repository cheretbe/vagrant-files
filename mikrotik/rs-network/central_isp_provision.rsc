:global interIspMACaddr
:global lanMACaddr

:if ([/system identity get name] != "central_isp") do={
  :put "Setting identity to 'central_isp'"
  /system identity set name="central_isp"
}

:if ([/interface ethernet get [find mac-address="$interIspMACaddr"] name] != "inter_isp") do={
  :put "Setting '$interIspMACaddr' interface name to 'inter_isp'"
  /interface ethernet set [find mac-address="$interIspMACaddr"] name="inter_isp"
}

:if ([/interface ethernet get [find mac-address="$lanMACaddr"] name] != "lan") do={
  :put "Setting '$lanMACaddr' interface name to 'lan'"
  /interface ethernet set [find mac-address="$lanMACaddr"] name="lan"
}

:if ([:len [/ip address find interface="inter_isp"]] = 0) do={
  :put "Adding IP 172.24.0.20/24 on interface 'inter_isp'"
  /ip address add address="172.24.0.20/24" interface="inter_isp"
}

do {
  if ([/routing ospf interface get [find interface="inter_isp"] hello-interval] !=1) do={
    :put "Setting OSPF hello-interval to 1 on interface 'inter_isp'"
    /routing ospf interface add hello-interval=1s interface=inter_isp
  } 
} on-error={}

#/routing ospf interface add hello-interval=1s interface=inter_isp
#/routing ospf instance set 0 router-id=172.24.0.10
#/routing ospf area add area-id=0.0.0.1 name=inter_isp
#/routing ospf network add network=172.24.0.0/24 area=inter_isp
