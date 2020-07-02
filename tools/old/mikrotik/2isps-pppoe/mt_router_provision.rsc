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

:if ([:len [/ip address find interface="lan"]] = 0) do={
  :put "Adding IP 172.25.0.1 on interface 'lan'"
  /ip address add address="172.25.0.1/24" interface="lan" network="172.25.0.0"
}

:if ([:len [/interface pppoe-client find name="wan1"]] = 0) do={
  :put "Adding PPPoE interface 'wan1'"
  /interface pppoe-client
  add add-default-route=yes disabled=no default-route-distance=5 interface=wan1_phys name=wan1 password=password user=isp1_user
}

:if ([:len [/interface pppoe-client find name="wan2"]] = 0) do={
  :put "Adding PPPoE interface 'wan2'"
  /interface pppoe-client
  add add-default-route=yes disabled=no default-route-distance=10 interface=wan2_phys name=wan2 password=password user=isp2_user
}

:put "Setting identity to 'vagrant_mt_router'"
/system identity set name="vagrant_mt_router"

# NAT
:if ([:len [/ip firewall nat find action=masquerade src-address="172.25.0.0/24"]] = 0) do={
  :put "Adding NAT rule for LAN"
  /ip firewall nat
  add action=masquerade chain=srcnat src-address="172.25.0.0/24"
}

# DHCP server
:if ([:len [/ip pool find name="dhcp-pool"]] = 0) do={
  :put "Adding DHCP IP pool range"
  /ip pool add name="dhcp-pool" ranges=172.25.0.100-172.25.0.254
}
:if ([:len [/ip dhcp-server find name="dhcp-lan"]] = 0) do={
  :put "Adding DHCP server"
  /ip dhcp-server
  add address-pool=dhcp-pool disabled=no interface="lan" lease-time=3d name="dhcp-lan"
}
:if ([:len [/ip dhcp-server network find address="172.25.0.0/24"]] = 0) do={
  :put "Adding DCHP network"
  /ip dhcp-server network
  add address=172.25.0.0/24 dns-server=172.25.0.1 gateway=172.25.0.1 netmask=24
}
:if ([:len [/ip dhcp-server lease find client-id="63:6c:69:65:6e:74"]] = 0) do={
  :put "Adding static DHCP lease for client"
  /ip dhcp-server lease
  add address=172.25.0.10 client-id=63:6c:69:65:6e:74 server=dhcp-lan
}

# DNS
if ([/ip dns get servers]= "") do={
  :put "Enabling DNS"
  /ip dns set allow-remote-requests=yes servers="8.8.8.8"
}

:if ([:len [/ip firewall mangle find action=mark-connection and new-connection-mark="wan1-input"]] = 0) do={
  /ip firewall mangle
  add action=mark-connection chain=input comment=\
      "Mark input connections from WAN1" in-interface=wan1 new-connection-mark=\
      wan1-input
  add action=mark-connection chain=input comment=\
      "Mark input connections from WAN2" in-interface=wan2 new-connection-mark=\
      wan2-input
  add action=mark-routing chain=output comment="Force outuput connections origin\
      ated from WAN1 to be routed through WAN1" connection-mark=wan1-input \
      new-routing-mark=wan1 passthrough=no
  add action=mark-routing chain=output comment="Force outuput connections origin\
      ated from WAN2 to be routed through WAN2" connection-mark=wan2-input \
      new-routing-mark=wan2 passthrough=no
  add action=mark-connection chain=forward comment=\
      "Mark connections forwarded from WAN1" connection-state=new in-interface=\
      wan1 new-connection-mark=wan1-pfw passthrough=no
  add action=mark-connection chain=forward comment=\
      "Mark connections forwarded from WAN2" connection-state=new in-interface=\
      wan2 new-connection-mark=wan2-pfw passthrough=no
  add action=mark-routing chain=prerouting comment=\
      "Force connections originated from WAN1 to be routed through WAN1" \
      connection-mark=wan1-pfw in-interface=lan new-routing-mark=wan1 \
      passthrough=no
  add action=mark-routing chain=prerouting comment=\
      "Force connections originated from WAN2 to be routed through WAN2" \
      connection-mark=wan2-pfw in-interface=lan new-routing-mark=wan2 \
      passthrough=no

  /ip route
    add comment=wan2 distance=30 gateway=wan2 routing-mark=wan2
    add comment=wan1 distance=30 gateway=wan1 routing-mark=wan1
  /ip route rule
    add action=lookup-only-in-table routing-mark=wan2 table=wan2
    add action=lookup-only-in-table routing-mark=wan1 table=wan1
}