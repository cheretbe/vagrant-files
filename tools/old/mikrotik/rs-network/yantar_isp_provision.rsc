:global interIspMACaddr
:global yantarIspMACaddr

:if ([/system identity get name] != "yantar_isp") do={
  :put "Setting identity to 'yantar_isp'"
  /system identity set name="yantar_isp"
}

:if ([/interface ethernet get [find mac-address="$interIspMACaddr"] name] != "inter_isp") do={
  :put "Setting '$interIspMACaddr' interface name to 'inter_isp'"
  /interface ethernet set [find mac-address="$interIspMACaddr"] name="inter_isp"
}

:if ([/interface ethernet get [find mac-address="$yantarIspMACaddr"] name] != "yantar_isp") do={
  :put "Setting '$yantarIspMACaddr' interface name to 'yantar_isp'"
  /interface ethernet set [find mac-address="$yantarIspMACaddr"] name="yantar_isp"
}

:if ([:len [/ip address find interface="inter_isp"]] = 0) do={
  :put "Adding IP 172.24.0.23/24 on interface 'inter_isp'"
  /ip address add address="172.24.0.23/24" interface="inter_isp"
}

:if ([:len [/ip address find interface="yantar_isp"]] = 0) do={
  :put "Adding IP 192.168.56.1/24 on interface 'yantar_isp'"
  /ip address add address="192.168.56.1/24" interface="yantar_isp"
}

:if ([/routing ospf instance get [find name="default"] router-id] != "172.24.0.23") do={
  /routing ospf instance set [find name="default"] router-id=172.24.0.23
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

:if ([:len [/ip firewall nat find action=masquerade and out-interface="inter_isp"]] = 0) do={
  :put "Adding NAT rule for 192.168.56.0/24"
  /ip firewall nat add action=masquerade chain=srcnat \
    out-interface="inter_isp" src-address=192.168.56.0/24
}