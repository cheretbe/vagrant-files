```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "cheretbe/win10_en_64"
  config.winrm.username = "vagrant"
  config.winrm.password = "#{ENV['AO_DEFAULT_VAGRANT_PASSWORD']}"
  config.vm.boot_timeout = 600
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.customize ["modifyvm", :id, "--groups", "/__vagrant"]
    vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
  end
end
```
