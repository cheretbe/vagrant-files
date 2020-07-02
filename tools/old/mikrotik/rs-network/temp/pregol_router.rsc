# dec/21/2018 13:30:47 by RouterOS 6.43.7
# software id = AL9M-XKJD
#
#
#
/interface ethernet
set [ find default-name=ether1 ] name=host_nat
set [ find default-name=ether2 ] name=host_only
set [ find default-name=ether4 ] name=lan
set [ find default-name=ether3 ] name=wan
/interface l2tp-client
add connect-to=192.168.51.9 disabled=no name=l2tp-out1 password=test user=\
    pregol
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/routing ospf area
add area-id=192.168.156.33 disabled=yes name=area1
/routing ospf instance
set [ find default=yes ] router-id=192.168.156.33
/tool user-manager customer
set admin access=\
    own-routers,own-users,own-profiles,own-limits,config-payment-gw
/ip address
add address=192.168.53.2/24 interface=wan network=192.168.53.0
add address=192.168.156.33/27 interface=lan network=192.168.156.32
/ip cloud
set update-time=no
/ip dhcp-client
add add-default-route=no dhcp-options=hostname,clientid disabled=no \
    interface=host_nat use-peer-dns=no use-peer-ntp=no
add add-default-route=no dhcp-options=hostname,clientid disabled=no \
    interface=host_only use-peer-dns=no use-peer-ntp=no
/ip firewall nat
add action=masquerade chain=srcnat out-interface=wan src-address=\
    192.168.156.32/27
/ip route
add distance=1 gateway=192.168.53.1
/routing ospf interface
add interface=lan network-type=broadcast passive=yes
/routing ospf network
add area=backbone network=172.16.0.8/30
add area=backbone network=192.168.156.32/27
/system identity
set name=pregol_router
/system logging
add disabled=yes topics=ospf
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
add dont-require-permissions=no name=pregol_router_provision owner=vagrant \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    source=":global pregolIspMACaddr\
    \n:global pregolLanMACaddr\
    \n\
    \n:if ([/system identity get name] != \"pregol_router\") do={\
    \n  :put \"Setting identity to 'pregol_router'\"\
    \n  /system identity set name=\"pregol_router\"\
    \n}\
    \n\
    \n:if ([/interface ethernet get [find mac-address=\"\$pregolIspMACaddr\"] \
    name] != \"wan\") do={\
    \n  :put \"Setting '\$pregolIspMACaddr' interface name to 'wan'\"\
    \n  /interface ethernet set [find mac-address=\"\$pregolIspMACaddr\"] name\
    =\"wan\"\
    \n}\
    \n\
    \n:if ([/interface ethernet get [find mac-address=\"\$pregolLanMACaddr\"] \
    name] != \"lan\") do={\
    \n  :put \"Setting '\$pregolLanMACaddr' interface name to 'lan'\"\
    \n  /interface ethernet set [find mac-address=\"\$pregolLanMACaddr\"] name\
    =\"lan\"\
    \n}\
    \n\
    \n:if ([:len [/ip address find interface=\"wan\"]] = 0) do={\
    \n  :put \"Adding IP 192.168.53.2/24 on interface 'wan'\"\
    \n  /ip address add address=\"192.168.53.2/24\" interface=\"wan\"\
    \n}\
    \n\
    \n:if ([:len [/ip address find interface=\"lan\"]] = 0) do={\
    \n  :put \"Adding IP 192.168.156.33/27 on interface 'lan'\"\
    \n  /ip address add address=\"192.168.156.33/27\" interface=\"lan\"\
    \n}\
    \n\
    \n:if ([:len [/ip firewall nat find action=masquerade and out-interface=\"\
    wan\"]] = 0) do={\
    \n  :put \"Adding NAT rule for 192.168.156.32/27\"\
    \n  /ip firewall nat add action=masquerade chain=srcnat \\\
    \n    out-interface=\"wan\" src-address=192.168.156.32/27\
    \n}\
    \n\
    \n:if ([:len [/ip route find gateway=\"192.168.53.1\" and dst-address=\"0.\
    0.0.0/0\"]] = 0) do={\
    \n  :put \"Adding default route via 192.168.53.1\"\
    \n  /ip route add gateway=192.168.53.1\
    \n}"
/tool user-manager database
set db-path=user-manager
