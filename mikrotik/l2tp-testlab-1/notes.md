* http://sudouser.com/ustanovka-i-nastrojka-l2tp-servera-xl2tpd-ili-l2tpd.html
* http://tkachenkosi.blogspot.ru/2011/08/l2tp-server.html
* https://linuxexplore.com/how-tos/l2tp-vpn-using-xl2tpd/


### PPPoE
```shell
service xl2tpd stop
systemctl disable xl2tpd
apt-get -y install pppoe

cat << EOF > /etc/ppp/pppoe-server-options
auth
require-chap
lcp-echo-interval 10
lcp-echo-failure 2
noipdefault
noipx
nodefaultroute
noproxyarp
# Netmask that clients will receive
#netmask 255.255.255.255
logfile /var/log/pppoe.log
EOF

pppoe-server -I enp0s8 -L 192.168.100.1 -R 192.168.100.10

killall pppoe-server
```