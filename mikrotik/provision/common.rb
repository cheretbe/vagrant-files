def upload_file(file_path, target_name, script_name)
  # info ("scp -P #{@machine.ssh_info[:port]} -i #{@machine.ssh_info[:private_key_path][0]} " +
           # "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null " +
           # "mt_client_provision.rsc #{@machine.ssh_info[:username]}@#{@machine.ssh_info[:host]}:/")

  run ("vagrant ssh -- :if ([:len [/system script find name=\"" + script_name +
    "\"]] != 0) do={ /system script remove " + script_name +" }")

  if Vagrant::Util::Platform.windows? then
    run ("vagrant ssh -- /system script run enable_smb")
    run ("powershell.exe -ExecutionPolicy Bypass -File ..\\provision\\smb_upload_file.ps1 -filePath " +
      file_path + " -targetName " + target_name)
  end

  run ("vagrant ssh -- /system script add name=" + script_name + "
    source=[/file get " + target_name + " contents]")
  run ("vagrant ssh -- :delay 5; /file remove " + target_name)
end