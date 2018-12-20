* pregol_isp
    * inter_isp: 172.24.0.21/24
    * pregol_isp: 192.168.53.1/24
* pregol_router
    * wan: 192.168.53.2/24
    * lan: 192.168.156.33/27
    * tunnels
        * 172.16.0.9/30 (mt_router wan1) <--> 172.16.0.10/30 (pregol_router)	
        * 172.16.0.13/30 (mt_router wan2) <--> 172.16.0.14/30 (pregol_router)
