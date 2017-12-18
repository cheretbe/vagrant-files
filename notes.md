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
```
