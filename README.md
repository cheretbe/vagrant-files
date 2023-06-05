```shell
cp ../../multi_vm_config_template.yml ./local-config.yml

VAGRANT_LOG=warn vagrant status
```

```ruby
  config.vm.provider "virtualbox" do |vb|
    vb.gui = true
    vb.memory = "1024"
    vb.cpus = "1"
  end
```
