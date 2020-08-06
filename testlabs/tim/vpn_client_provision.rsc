:global vmNICMACs
:local lanMACaddr [:pick $vmNICMACs 2]

/system identity set name=vpn-client

/interface ethernet set [find mac-address="$lanMACaddr"] name="lan"

:if ([:len [/ip address find interface="lan" and address="192.168.1.10/24"]] = 0) do={
  /ip address add address="192.168.1.10/24" interface="lan"
}