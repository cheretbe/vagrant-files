Temporarily use additional Ubuntu box
```shell
# on the host
cd ../../linux/ubuntu-focal/
vagrant up
vagrant ssh -- python3 /host_home/projects/vagrant-files/testlabs/ansible/provision/setup_host.py

# in ansible box
ansible -i 192.168.80.22, -u vagrant -m setup all

```shell
# --natpf<1-N> [<rulename>],tcp|udp,[<hostip>],<hostport>,[<guestip>],<guestport>]
# [!] Note that for running VM the syntax is controlvm natpf<1-N> and for
# powered off one it's modifyvm --natpf<1-N>
vboxmanage controlvm $(cat .vagrant/machines/ubuntu-bionic/virtualbox/id) \
  natpf1 "forward_port_80,tcp,,7000,,80"
vboxmanage controlvm $(cat .vagrant/machines/ubuntu-focal/virtualbox/id) \
  natpf1 "forward_port_80,tcp,,7001,,80"

curl -u backuppc:backuppc -s http://localhost:7000/BackupPC_Admin
curl -u backuppc:backuppc -s http://localhost:7001/BackupPC_Admin

curl -u backuppc:backuppc -s http://localhost/BackupPC_Admin
```

```shell
ansible-playbook ansible-playbooks/run_role.yml --extra-vars "role_name=backuppc-server" -l ubuntu-bionic:ubuntu-focal

ansible-playbook -i 192.168.80.54, -u vagrant \
  --extra-vars "ansible_connection=winrm ansible_port=5985" \
  --extra-vars "ansible_winrm_transport=ntlm ansible_password=$AO_DEFAULT_VAGRANT_PASSWORD" \
  --extra-vars "role_name=win-backuppc-client" /ansible-playbooks/run_role.yml

. ~/.cache/venv/py3/bin/activate
pytest ansible-playbooks/backuppc-server/tests/ -v --connection=ansible --hosts=ubuntu-bionic,ubuntu-focal
```

`local-config.yml` example:
```yaml
---
use_awx: true
awx_version: 7.0.0
docker_mirror: "http://localhost:5000"
ansible_vm_memory: "6144"
ansible_vm_cpus: "2"
```

```shell
~/ansible-playbooks/tools/awx/install_awx.sh && \
~/ansible-playbooks/tools/awx/configure_tower_cli.sh && \
~/ansible-playbooks/tools/awx/set_test_config.sh
```

```shell
. virtenv/py3/bin/activate

tower-cli receive --project ansible-playbooks > \
  /opt/ansible-playbooks/tools/debug/awx_objects/project.json
tower-cli receive --credential vagrant > \
  /opt/ansible-playbooks/tools/debug/awx_objects/credential.json
tower-cli receive --job_template check_if_reachable > \
  /opt/ansible-playbooks/tools/debug/awx_objects/template.json
tower-cli receive --inventory test_inventory > \
  /opt/ansible-playbooks/tools/debug/awx_objects/inventory.json
```

* https://github.com/adamrushuk/ansible-azure/blob/master/vagrant/scripts/configure_ansible_awx.sh