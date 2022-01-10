`local-config.yml` example:
```yaml
---
# https://support.purevpn.com/vpn-servers
purevpn_server: cz2-auto-tcp.ptoserver.com
purevpn_protocol: tcp
purevpn_user: username
purevpn_password: password
sound: true
# Valid options are: "master", "develop", "local" (symlink to /host_home/projects/ansible-playbooks)
common_repo_source: develop # default is master
```
