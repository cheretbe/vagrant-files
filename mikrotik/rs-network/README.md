* central_isp
    * inter_isp: 172.24.0.20/24
    * central_isp: 192.168.100.1/24
* central_router
    * wan_phys: 192.168.100.2/24
    * wan: 192.168.53.2 (L2TP tunnel to 192.168.100.1)
    * lan: 192.168.156.1/27
* pregol_isp
    * inter_isp: 172.24.0.21/24
    * pregol_isp: 192.168.54.1/24
* pregol_router
    * wan: 192.168.54.2/24
    * lan: 192.168.156.33/27
    * tunnels
        * 172.16.0.1 (mt_router wan1) <--> 172.16.0.3 (pregol_router)
        * 172.17.0.1 (mt_router wan2) <--> 172.17.0.3 (pregol_router)
* yantar_isp
    * inter_isp: 172.24.0.23/24
    * yantar_isp: 192.168.56.1/24
* yantar_router
    * wan: 192.168.56.2/24
    * lan: 192.168.156.97/27


GUR IPsec connection is in tunnel mode, so no OSPF routing is possible
(see "Tunnel vs. Transport" section in https://mum.mikrotik.com/presentations/HR13/kirnak.pdf)


Office
```
/interface l2tp-server server set authentication=mschap2 enabled=yes

/ppp secret add name=central_main local-address=172.16.0.1 remote-address=172.16.0.2 \
  service=l2tp
/ppp secret add name=central_backup local-address=172.17.0.1 remote-address=172.17.0.2 \
  service=l2tp
/ppp secret add name=pregol_main local-address=172.16.0.1 remote-address=172.16.0.3 \
  service=l2tp
/ppp secret add name=pregol_backup local-address=172.17.0.1 remote-address=172.17.0.3 \
  service=l2tp

/interface sstp-server server set authentication=mschap2 enabled=yes port=20443

/ppp secret
add local-address=172.17.0.1 name=yantar_backup remote-address=172.17.0.5 service=sstp
add local-address=172.16.0.1 name=yantar_main remote-address=172.16.0.5 service=l2tp

/routing ospf instance set [ find default=yes ] router-id=172.25.0.1
/routing ospf interface add interface=lan network-type=broadcast passive=yes
/routing ospf network add area=backbone network=172.16.0.0/24
/routing ospf network add area=backbone network=172.25.0.0/24
```

Central
```
/interface l2tp-client add name=office_main connect-to=192.168.51.9 disabled=no \
  user=central_main
/interface l2tp-client add name=office_backup connect-to=192.168.52.9 disabled=no \
  user=central_backup

/routing ospf instance set [ find default=yes ] router-id=192.168.156.1
/routing ospf interface add interface=lan network-type=broadcast passive=yes
/routing ospf network add area=backbone network=172.16.0.0/24
/routing ospf network add area=backbone network=192.168.156.0/27
```

Pregol
```
/interface l2tp-client add name=office_main connect-to=192.168.51.9 disabled=no \
  user=pregol_main

/routing ospf instance set [ find default=yes ] router-id=192.168.156.33
/routing ospf interface add interface=lan network-type=broadcast passive=yes
/routing ospf network add area=backbone network=172.16.0.0/24
/routing ospf network add area=backbone network=192.168.156.32/27
```