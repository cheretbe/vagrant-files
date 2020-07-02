* https://serverfault.com/questions/776049/how-to-simulate-dns-server-response-timeout
* https://wiki.linuxfoundation.org/networking/netem
* https://stackoverflow.com/questions/614795/simulate-delayed-and-dropped-packets-on-linux

`/etc/dhcp/dhclient.conf`
```
interface "enp0s3" {
  #supersede domain-name-servers 8.8.8.8, 8.8.4.4;
  supersede domain-name-servers 172.25.0.1;
  #supersede routers "";
  supersede routers 172.25.0.1;
}
```

```bash
route add default gw 172.25.0.1 enp0s8
```