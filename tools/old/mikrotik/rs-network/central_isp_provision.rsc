:global interIspMACaddr
:global centralIspMACaddr

:if ([/system identity get name] != "central_isp") do={
  :put "Setting identity to 'central_isp'"
  /system identity set name="central_isp"
}

:if ([/interface ethernet get [find mac-address="$interIspMACaddr"] name] != "inter_isp") do={
  :put "Setting '$interIspMACaddr' interface name to 'inter_isp'"
  /interface ethernet set [find mac-address="$interIspMACaddr"] name="inter_isp"
}

:if ([/interface ethernet get [find mac-address="$centralIspMACaddr"] name] != "central_isp") do={
  :put "Setting '$centralIspMACaddr' interface name to 'central_isp'"
  /interface ethernet set [find mac-address="$centralIspMACaddr"] name="central_isp"
}

:if ([:len [/ip address find interface="inter_isp"]] = 0) do={
  :put "Adding IP 172.24.0.20/24 on interface 'inter_isp'"
  /ip address add address="172.24.0.20/24" interface="inter_isp"
}

:if ([:len [/ip address find interface="central_isp"]] = 0) do={
  :put "Adding IP 192.168.100.1/24 on interface 'central_isp'"
  /ip address add address="192.168.100.1/24" interface="central_isp"
}

:if ([/routing ospf instance get [find name="default"] router-id] != "172.24.0.20") do={
  /routing ospf instance set [find name="default"] router-id=172.24.0.20
}

:if ([:len [/routing ospf interface find interface="inter_isp"]] = 0) do={
  :put "Adding OSPF interface 'inter_isp' with hello-interval of 1s"
  /routing ospf interface add hello-interval=1s interface=inter_isp
}

:if ([:len [/routing ospf area find name="inter_isp"]] = 0) do={
  :put "Adding OSPF area with ID 0.0.0.1"
  /routing ospf area add area-id=0.0.0.1 name=inter_isp
}

:if ([:len [/routing ospf network find network="172.24.0.0/24"]] = 0) do={
  :put "Adding OSPF network 172.24.0.0/24"
  /routing ospf network add network=172.24.0.0/24 area=inter_isp
}

:if ([:len [/routing ospf network find network="192.168.53.0/24"]] = 0) do={
  :put "Adding OSPF network 192.168.53.0/24"
  /routing ospf network add network=192.168.53.0/24 area=inter_isp
}

:if (! [/interface l2tp-server server get enabled]) do={
  :put "Enabling L2TP server"
  /interface l2tp-server server set authentication=mschap2 enabled=yes
}

:if ([:len [/ppp secret find name="central"]] = 0) do={
  :put "Adding L2TP user 'central'"
  /ppp secret add name=central password=central local-address=192.168.53.1 \
    remote-address=192.168.53.2 service=l2tp
}