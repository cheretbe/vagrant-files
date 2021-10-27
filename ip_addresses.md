### linux

| Environment/<br>VM Name   | Int. Network Name        | IP Address       |
|---------------------------|--------------------------|------------------|
| **burp-client**           |                          |                  |
| default                   | `vagrant-burp`           | `172.24.0.11`    |
|                           |                          |                  |
| **burp-server**           |                          |                  |
| default                   | `vagrant-burp`           | `172.24.0.10`    |
|                           |                          |                  |
| **domain-member**         |                          |                  |
| default                   | `vagrant-domain`         | `192.168.199.12` |
|                           |                          |                  |
| **package-cache**         |                          |                  |
| default                   | `---`                    | `---`            |
|                           |                          |                  |
| **ubuntu-bionic**         |                          |                  |
| default                   | `---`                    | `---`            |
|                           |                          |                  |
| **ubuntu-focal**          |                          |                  |
| default                   | `---`                    | `---`            |
|                           |                          |                  |
| **ubuntu-xenial**         |                          |                  |
| default                   | `---`                    | `---`            |
|                           |                          |                  |
| **ubuntu-zfs**            |                          |                  |
| default                   | `---`                    | `---`            |

### windows

| Environment/<br>VM Name   | Int. Network Name        | IP Address       |
|---------------------------|--------------------------|------------------|
| **domain-controller**     |                          |                  |
| default                   | `vagrant-domain`         | `192.168.199.10` |
|                           |                          |                  |
| **domain-member**         |                          |                  |
| default                   | `vagrant-domain`         | `192.168.199.11` |
|                           |                          |                  |
| **win10-ru**              |                          |                  |
| win10                     | `vagrant-intnet`         | `172.24.0.11`    |
| ansible-controller        | `vagrant-intnet`         | `172.24.0.10`    |
|                           |                          |                  |
| **win10-vpn**             |                          |                  |
| win10                     | `vagrant-intnet`         | `172.24.0.21`    |
| ansible-controller        | `vagrant-intnet`         | `172.24.0.20`    |
|                           |                          |                  |
| **win10-vpn-local**       |                          |                  |
| router                    | `vagrant-win-vpn`        | `192.168.80.11`  |
| win10                     | `vagrant-win-vpn`        | `192.168.80.12`  |
| ansible-controller        | `vagrant-win-vpn`        | `192.168.80.10`  |


### testlabs

| Environment/<br>VM Name   | Int. Network Name        | IP Address      |
|---------------------------|--------------------------|-----------------|
| **burp**                  |                          |                 |
| burp-server               | `vagrant-intnet`         | `172.24.0.20`   |
| win10                     | `vagrant-intnet`         | `172.24.0.11`   |
| ubuntu-bionic             | `vagrant-intnet`         | `172.24.0.12`   |
| ansible-controller        | `vagrant-intnet`         | `172.24.0.10`   |
|                           |                          |                 |
| **linux-iptables-router** |                          |                 |
| isp                       | `vagrant-isp`            | `192.168.78.1`  |
| router                    | `vagrant-isp`            | `192.168.78.2`  |
|                           | `vagrant-client`         | `192.168.79.10` |
| client                    | `vagrant-client`         | `192.168.79.11` |
| external                  | `vagrant-isp`            | `192.168.78.3`  |
|                           |                          |                 |
| **tim**                   |                          |                 |
| client-router             | `vagrant-vpn-client-lan` | `192.168.1.1`   |
|                           | `vagrant-wan`            | `10.64.0.2/10`  |
| isp                       | `vagrant-wan`            | `10.64.0.1/10`  |
| tim-router                | `vagrant-tim-lan`        | `192.168.2.1`   |
|                           | `vagrant-wan`            | `10.64.0.3/10`  |
| vpn-server                | `---`                    | `---`           |
| tim-server                | `vagrant-tim-lan`        | `192.168.2.11`  |
|                           | `vagrant-tim-partners`   | `192.168.30.11` |
| vpn-client                | `vagrant-vpn-client-lan` | `192.168.1.10`  |
|                           |                          |                 |
| **tim-clients**           |                          |                 |
| internal                  | `---`                    | `---`           |
| external                  | `---`                    | `---`           |
|                           |                          |                 |
| **win+linux**             |                          |                 |
| ubuntu-focal              | `vagrant-win-linux`      | `192.168.80.31` |
| win10                     | `vagrant-win-linux`      | `192.168.80.32` |
| ansible-controller        | `vagrant-win-linux`      | `192.168.80.30` |
