Ubuntu + Win10
```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.define :host1 do |host1|
    host1.vm.box = "ubuntu/xenial64"
    host1.vm.hostname = "host1"
    host1.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--groups", "/__vagrant"]
      vb.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]
    end
    host1.vm.network "private_network", ip: "192.168.199.10", virtualbox__intnet: "vagrant-intnet"
  end

  config.vm.define :host2 do |host2|
    host2.vm.box = "cheretbe/win10_en_64"
    host2.winrm.username = "vagrant"
    host2.winrm.password = "#{ENV['AO_DEFAULT_VAGRANT_PASSWORD']}"
    host2.vm.boot_timeout = 600
    host2.vm.hostname = "host2"
    host2.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--groups", "/__vagrant"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    end
    host2.vm.network "private_network", ip: "192.168.199.11", virtualbox__intnet: "vagrant-intnet"
    # host2.vm.provision "shell", path: "provision-script.ps1"
  end
end
```

Win10 + Win10
```
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.define :host1 do |host1|
    host1.vm.box = "cheretbe/win10_en_64"
    host1.winrm.username = "vagrant"
    host1.winrm.password = "#{ENV['AO_DEFAULT_VAGRANT_PASSWORD']}"
    host1.vm.boot_timeout = 600
    host1.vm.hostname = "host1"
    host1.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--groups", "/__vagrant"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    end
    host1.vm.network "private_network", ip: "192.168.199.10", virtualbox__intnet: "vagrant-intnet"
    host1.vm.provision "shell", path: "provision-script.ps1"
  end

  config.vm.define :host2 do |host2|
    host2.vm.box = "cheretbe/win10_en_64"
    host2.winrm.username = "vagrant"
    host2.winrm.password = "#{ENV['AO_DEFAULT_VAGRANT_PASSWORD']}"
    host2.vm.boot_timeout = 600
    host2.vm.hostname = "host2"
    host2.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--groups", "/__vagrant"]
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    end
    host2.vm.network "private_network", ip: "192.168.199.11", virtualbox__intnet: "vagrant-intnet"
    host2.vm.provision "shell", path: "provision-script.ps1"
  end
end
```

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::DarkCyan

if ($NULL -eq (Get-NetFirewallRule -DisplayName "_allow_vagrant_intnet" -ErrorAction SilentlyContinue)) {
  Write-Host "Adding firewall rule (allow vagrant-intnet)"
  New-NetFirewallRule -DisplayName "_allow_vagrant_intnet" `
    -RemoteAddress "192.168.199.0/24" -Protocol Any -Profile Any -Action Allow `
    -Enabled True | Out-Null
} else {
  Write-Host "Firewall rule is already present (allow vagrant-intnet)"
} #if

if ($Env:COMPUTERNAME -eq "host1") {
  $otherHostName = "host2"
  $otherHostIP = "192.168.199.11"
} else {
  $otherHostName = "host1"
  $otherHostIP = "192.168.199.10"
} #if

$hostsFile = Join-Path -Path $Env:windir -ChildPath "System32\drivers\etc\hosts"
if ($NULL -eq (Get-Content $hostsFile | Where-Object { $_.Contains($otherHostName) })) {
  Write-Host ("Adding {0} ({1}) to '{2}'" -f $otherHostName, $otherHostIP, $hostsFile)
  # ("{0} {1}" -f $otherHostIP, $otherHostName) | Out-File -Append $hostsFile
  Add-Content $hostsFile ("`r`n{0} {1}" -f $otherHostIP, $otherHostName)
} else {
  Write-Host ("'{0}' already contains '{1}' entry. Skipping" -f $hostsFile, $otherHostName)
} #if

Set-Item "wsman:\localhost\Client\TrustedHosts" -Value "*" -Force
```