`local-config.yml` example:
```yaml
---
# win_memory: "4096"
# win_cpus: "2"
# https://github.com/cheretbe/notes/blob/master/vagrant.md#networking
# bridged_adapter: {}
bridged_adapter:
  bridge: "enp0s31f6"
  mac: "0800275A78D2"
  # nic_type: virtio
  type: "dhcp"
```
