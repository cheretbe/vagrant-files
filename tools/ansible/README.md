```shell
ansible-inventory --graph --vars
ansible-inventory -i ~/vagrant-files/tools/ansible/vagrant_inventory.py --graph --vars
```

`ansible.cfg` example
```
[defaults]
inventory = ../../tools/ansible/vagrant_inventory.py
```