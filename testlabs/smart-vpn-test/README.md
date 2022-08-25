`local-config.yml` example:
```yaml
---
linux_memory: "4096"
# Valid options are: "master", "develop", "local" (symlink to /host_home/projects/ansible-playbooks)
common_repo_source: develop # default is master

ovpn_client_server_type: purevpn
# https://support.purevpn.com/vpn-servers
ovpn_client_server: cz2-auto-tcp.ptoserver.com
ovpn_client_protocol: tcp
ovpn_client_purevpn_user: user
ovpn_client_purevpn_password: password


```shell
sudo apt install whois

curl https://apt.releases.hashicorp.com
whois $(dig +short apt.releases.hashicorp.com | sed -n 1p)

# NetRange:       13.32.0.0 - 13.33.255.255
# CIDR:           13.32.0.0/15
```