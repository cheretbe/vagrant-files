`local-config.yml` example:
```yaml
---
ovpn_server_protocol: tcp  # default is udp
use_local_repo: true       # default is false
```

Debugging

```shell
rm temp/client1.ovpn && vagrant provision
```

```batch
:: fix routing after connection
route delete 192.168.80.61
```
