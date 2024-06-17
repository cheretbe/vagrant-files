```shell
# Local config
cp ../../multi_vm_config_template.yml ./local-config.yml

# Ansible dynamic inventory
cat > ansible.cfg<< EOF
[defaults]
inventory = ../../tools/ansible/vagrant_inventory.py
host_key_checking = False
EOF

# Ansible vars
mkdir -p host_vars
cat > host_vars/default.yml<< EOF
---

test1: value1
EOF

# Log level
VAGRANT_LOG=warn vagrant status
```

```ruby
  config.vm.provider "virtualbox" do |vb|
    vb.gui = true
    vb.memory = "1024"
    vb.cpus = "1"
  end
```
