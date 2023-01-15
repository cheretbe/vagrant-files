```shell
# 1 day = 86400000 ms
vboxmanage modifyvm $(cat .vagrant/machines/seafile-server/virtualbox/id) --biossystemtimeoffset -$((1*86400000))

tools/shift_time.sh -31
# reset
tools/shift_time.sh

vagrant ssh seafile-client -- rsync -vrhlt /host_home/Documents/mp3/temp/download /home/vagrant/seafile-client/test-library-1/
vagrant ssh seafile-client -- rm -rfv /home/vagrant/seafile-client/test-library-1/download/
vagrant ssh seafile-client -- seaf-cli status

vagrant ssh seafile-server -- sudo du -sh /opt/docker-data/seafile/data/

vagrant ssh seafile-server -- docker exec seafile /scripts/gc.sh --dry-run
```

`local-config.yml` example:
```yaml
---
linux_memory: "4096"
```
