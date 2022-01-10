`local-config.yml` example:
```yaml
---
ovpn_server_protocol: tcp   # default is udp
# Valid options are: "master", "develop", "local" (symlink to /host_home/projects/ansible-playbooks)
common_repo_source: develop # default is master
```

Debugging

```batch
:: fix routing after connection
route delete 192.168.80.61
```
