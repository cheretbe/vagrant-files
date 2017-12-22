```ruby
system('./myscript.sh')

if Vagrant::Util::Platform.windows? then
  puts "on Windows"
else
  puts "not on Windows"
end

Vagrant.configure("2") do |config|
  config.vm.provision "shell", inline: "\"#{ENV['UPSTART_SESSION']}\" | Out-File 'c:\\users\\vagrant\\test.txt'"
end

git_branch = `git rev-parse --abbrev-ref HEAD`
if git_branch .eql? "develop\n" then
  provision_param = "-local"
else
  provision_param = ""
```
```powershell
[scriptblock]::Create(((New-Object System.Net.WebClient).DownloadString("https://git.io/vby9m"))).Invoke("windows-config-builder.ps1", $True, @{"localTest" = $TRUE; "Verbose" = $TRUE})
[scriptblock]::Create((Get-Content "C:\users\vagrant\Documents\gist.txt" | Out-String)).Invoke("windows-config-builder.ps1", $True)
```
