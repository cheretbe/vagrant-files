#!/bin/bash

if [ -z "$1" ]; then
  shift_days=0
else
  shift_days=$1
fi

echo "Shifting 'seafile-server' VM's time to ${shift_days} day(s)"
shift_ms=$(( shift_days*86400000 ))

vagrant halt seafile-server

vboxmanage modifyvm $(cat .vagrant/machines/seafile-server/virtualbox/id) \
  --biossystemtimeoffset ${shift_ms}

vagrant up seafile-server

vagrant ssh seafile-server -- date
