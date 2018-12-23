* central_isp
    * inter_isp: 172.24.0.20/24
    * central_isp: 192.168.53.1 (L2TP tunnel over 192.168.100.0/24)

* pregol_isp
    * inter_isp: 172.24.0.21/24
    * pregol_isp: 192.168.54.1/24
* pregol_router
    * wan: 192.168.54.2/24
    * lan: 192.168.156.33/27
    * tunnels
        * 172.16.0.9/30 (mt_router wan1) <--> 172.16.0.10/30 (pregol_router)
        * 172.16.0.13/30 (mt_router wan2) <--> 172.16.0.14/30 (pregol_router)

GUR IPsec connection is in tunnel mode, so no OSPF routing is possible
(see "Tunnel vs. Transport" section in https://mum.mikrotik.com/presentations/HR13/kirnak.pdf)