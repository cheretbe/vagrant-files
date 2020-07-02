# dec/21/2018 13:30:12 by RouterOS 6.43.7
# software id = BH3K-E97R
#
#
#
/interface ethernet
set [ find default-name=ether4 ] name=host_nat
set [ find default-name=ether5 ] name=host_only
set [ find default-name=ether3 ] name=lan
set [ find default-name=ether1 ] name=wan1_phys
set [ find default-name=ether2 ] name=wan2_phys
/interface pppoe-client
add add-default-route=yes default-route-distance=5 disabled=no interface=\
    wan1_phys name=wan1 password=password user=isp1_user
add add-default-route=yes default-route-distance=10 disabled=no interface=\
    wan2_phys name=wan2 password=password user=isp2_user
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip pool
add name=dhcp-pool ranges=172.25.0.100-172.25.0.254
/ip dhcp-server
add address-pool=dhcp-pool disabled=no interface=lan lease-time=3d name=\
    dhcp-lan
/ppp profile
add local-address=172.16.0.9 name=l2tp_pregol_profile remote-address=\
    172.16.0.10
/routing ospf area
add area-id=172.25.0.1 disabled=yes name=area1
/routing ospf instance
set [ find default=yes ] router-id=172.25.0.1
/tool user-manager customer
set admin access=\
    own-routers,own-users,own-profiles,own-limits,config-payment-gw
/interface l2tp-server server
set enabled=yes
/ip address
add address=172.25.0.1/24 interface=lan network=172.25.0.0
/ip cloud
set update-time=no
/ip dhcp-client
add add-default-route=no dhcp-options=hostname,clientid disabled=no \
    interface=host_nat use-peer-dns=no use-peer-ntp=no
add add-default-route=no dhcp-options=hostname,clientid disabled=no \
    interface=host_only use-peer-dns=no use-peer-ntp=no
/ip dhcp-server lease
add address=172.25.0.10 client-id=63:6c:69:65:6e:74 server=dhcp-lan
/ip dhcp-server network
add address=172.25.0.0/24 dns-server=172.25.0.1 gateway=172.25.0.1 netmask=24
/ip dns
set allow-remote-requests=yes servers=8.8.8.8
/ip firewall nat
add action=masquerade chain=srcnat src-address=172.25.0.0/24
/ppp secret
add name=pregol password=test profile=l2tp_pregol_profile service=l2tp
/routing ospf interface
add interface=lan network-type=broadcast passive=yes
/routing ospf network
add area=backbone network=172.16.0.8/30
add area=backbone network=172.25.0.0/24
/system identity
set name=vagrant_mt_router
/system script
add dont-require-permissions=no name=provision owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    global vmNICCount\
    \n:global hostNatMACaddr\
    \n:global hostOnlyMACaddr\
    \n\
    \n:if ([:len [/file find name=dummy_provision.2del]] > 0) do={ /file remov\
    e dummy_provision.2del }\
    \n\
    \n:local continue ([:len [/interface ethernet find]] != \$vmNICCount)\
    \n:local counter 0\
    \n:while (\$continue) do={\
    \n  :put \"Waiting for all interfaces to become available...\"\
    \n  :delay 5\
    \n  :set counter (\$counter + 1)\
    \n  :set continue ([:len [/interface ethernet find]] != \$vmNICCount)\
    \n  :if (\$counter=5) do={:set continue false}\
    \n}\
    \n\
    \n:if ([/interface ethernet get [find mac-address=\"\$hostNatMACaddr\"] na\
    me] != \"host_nat\") do={\
    \n  :put \"Setting '\$hostNatMACaddr' interface name to 'host_nat'\"\
    \n  /interface ethernet set [find mac-address=\"\$hostNatMACaddr\"] name=\
    \"host_nat\"\
    \n}\
    \n\
    \n:if ([/interface ethernet get [find mac-address=\"\$hostOnlyMACaddr\"] n\
    ame] != \"host_only\") do={\
    \n  :put \"Setting '\$hostOnlyMACaddr' interface name to 'host_only'\"\
    \n  /interface ethernet set [find mac-address=\"\$hostOnlyMACaddr\"] name=\
    \"host_only\"\
    \n}\
    \n\
    \n:if ([:len [/ip dhcp-client find interface=\"host_only\"]] = 0) do={\
    \n  :put \"Enabling DHCP on 'host_only' interface\"\
    \n  /ip dhcp-client add disabled=no interface=\"host_only\" add-default-ro\
    ute=no use-peer-dns=no use-peer-ntp=no\
    \n}"
add dont-require-permissions=no name=enable_smb owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    if (![/ip smb get enabled]) do={\
    \n  :put \"Enabling SMB\"\
    \n  /ip smb set enabled=yes\
    \n}\
    \n\
    \n:if ([:len [/ip smb user find name=\"vagrant\"]] = 0) do={\
    \n  :put \"Adding user 'vagrant'\"\
    \n  /ip smb user add read-only=no name=\"vagrant\" password=\"vagrant\"\
    \n}\
    \n\
    \n:if ([:len [/ip smb share find name=\"vagrant\"]] = 0) do={\
    \n  :put \"Adding 'vagrant' share\"\
    \n  /ip smb share add name=\"vagrant\" directory=\"/\"\
    \n}"
add dont-require-permissions=no name=mt_router_provision owner=vagrant \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    source=":global isp1MACaddr\
    \n:global isp2MACaddr\
    \n:global lanMACaddr\
    \n\
    \n:if ([/interface ethernet get [find mac-address=\"\$lanMACaddr\"] name] \
    != \"lan\") do={\
    \n  :put \"Setting '\$lanMACaddr' interface name to 'lan'\"\
    \n  /interface ethernet set [find mac-address=\"\$lanMACaddr\"] name=\"lan\
    \"\
    \n}\
    \n\
    \n:if ([/interface ethernet get [find mac-address=\"\$isp1MACaddr\"] name]\
    \_!= \"wan1_phys\") do={\
    \n  :put \"Setting '\$isp1MACaddr' interface name to 'wan1_phys'\"\
    \n  /interface ethernet set [find mac-address=\"\$isp1MACaddr\"] name=\"wa\
    n1_phys\"\
    \n}\
    \n\
    \n:if ([/interface ethernet get [find mac-address=\"\$isp2MACaddr\"] name]\
    \_!= \"wan2_phys\") do={\
    \n  :put \"Setting '\$isp2MACaddr' interface name to 'wan2_phys'\"\
    \n  /interface ethernet set [find mac-address=\"\$isp2MACaddr\"] name=\"wa\
    n2_phys\"\
    \n}\
    \n\
    \n:if ([:len [/ip address find interface=\"lan\"]] = 0) do={\
    \n  :put \"Adding IP 172.25.0.1 on interface 'lan'\"\
    \n  /ip address add address=\"172.25.0.1/24\" interface=\"lan\" network=\"\
    172.25.0.0\"\
    \n}\
    \n\
    \n:if ([:len [/interface pppoe-client find name=\"wan1\"]] = 0) do={\
    \n  :put \"Adding PPPoE interface 'wan1'\"\
    \n  /interface pppoe-client\
    \n  add add-default-route=yes disabled=no default-route-distance=5 interfa\
    ce=wan1_phys name=wan1 password=password user=isp1_user\
    \n}\
    \n\
    \n:if ([:len [/interface pppoe-client find name=\"wan2\"]] = 0) do={\
    \n  :put \"Adding PPPoE interface 'wan2'\"\
    \n  /interface pppoe-client\
    \n  add add-default-route=yes disabled=no default-route-distance=10 interf\
    ace=wan2_phys name=wan2 password=password user=isp2_user\
    \n}\
    \n\
    \n:put \"Setting identity to 'vagrant_mt_router'\"\
    \n/system identity set name=\"vagrant_mt_router\"\
    \n\
    \n# NAT\
    \n:if ([:len [/ip firewall nat find action=masquerade src-address=\"172.25\
    .0.0/24\"]] = 0) do={\
    \n  :put \"Adding NAT rule for LAN\"\
    \n  /ip firewall nat\
    \n  add action=masquerade chain=srcnat src-address=\"172.25.0.0/24\"\
    \n}\
    \n\
    \n# DHCP server\
    \n:if ([:len [/ip pool find name=\"dhcp-pool\"]] = 0) do={\
    \n  :put \"Adding DHCP IP pool range\"\
    \n  /ip pool add name=\"dhcp-pool\" ranges=172.25.0.100-172.25.0.254\
    \n}\
    \n:if ([:len [/ip dhcp-server find name=\"dhcp-lan\"]] = 0) do={\
    \n  :put \"Adding DHCP server\"\
    \n  /ip dhcp-server\
    \n  add address-pool=dhcp-pool disabled=no interface=\"lan\" lease-time=3d\
    \_name=\"dhcp-lan\"\
    \n}\
    \n:if ([:len [/ip dhcp-server network find address=\"172.25.0.0/24\"]] = 0\
    ) do={\
    \n  :put \"Adding DCHP network\"\
    \n  /ip dhcp-server network\
    \n  add address=172.25.0.0/24 dns-server=172.25.0.1 gateway=172.25.0.1 net\
    mask=24\
    \n}\
    \n:if ([:len [/ip dhcp-server lease find client-id=\"63:6c:69:65:6e:74\"]]\
    \_= 0) do={\
    \n  :put \"Adding static DHCP lease for client\"\
    \n  /ip dhcp-server lease\
    \n  add address=172.25.0.10 client-id=63:6c:69:65:6e:74 server=dhcp-lan\
    \n}\
    \n\
    \n# DNS\
    \nif ([/ip dns get servers]= \"\") do={\
    \n  :put \"Enabling DNS\"\
    \n  /ip dns set allow-remote-requests=yes servers=\"8.8.8.8\"\
    \n}"
/tool user-manager database
set db-path=user-manager
