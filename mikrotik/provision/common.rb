# echo.|net use \\172.28.128.3\backup /user:vagrant /persistent:no
# net use \\172.28.128.3\backup /d

def upload_file(machine, file_path)
  info "There you go"
  info ("scp -P #{@machine.ssh_info[:port]} -i #{@machine.ssh_info[:private_key_path][0]} " +
           "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null " +
           "mt_client_provision.rsc #{@machine.ssh_info[:username]}@#{@machine.ssh_info[:host]}:/")
  if Vagrant::Util::Platform.windows? then
    info "++++"
  end
end