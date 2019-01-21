Ubuntu
```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  #config.vm.box = "ubuntu/bionic64"
  config.vm.provider "virtualbox" do |vb|
    #vb.memory = "2048"
    vb.customize ["modifyvm", :id, "--groups", "/__vagrant"]
    # prevent 'ubuntu-xenial-16.04-cloudimg-console.log' file creation
    # https://groups.google.com/forum/#!topic/vagrant-up/eZljy-bddoI
    vb.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]
  end
end
```

Debian
```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # 7 (obsolete)
  # config.vm.box = "debian/wheezy64"
  # 8 (oldstable)
  # config.vm.box = "debian/jessie64"
  # 9 (stable)
  config.vm.box = "debian/stretch64"
  config.vm.provider "virtualbox" do |vb|
    #vb.memory = "2048"
    vb.customize ["modifyvm", :id, "--groups", "/__vagrant"]
  end
end
```
