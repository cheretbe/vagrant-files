def quoted_string_to_mac_address(str)
  # "0800278917AB" ==> 08:00:27:89:17:AB
  return (str[1..2] + ":" + str[3..4] + ":" + str[5..6] +
    ":" + str[7..8] + ":" + str[9..10] + ":" + str[11..12])
end

def get_vb_nic_mac_address(machine_id, nic_idx)
  read_info = true
  if (not $vb_vm_info.nil?) then
    read_info = $vb_vm_info["UUID"] != "\"#{machine_id}\""
  end
  if (read_info) then
    # Save VM info in a global variable to avoid subsequent vboxmanage calls
    # if more than one MAC address is needed
    vb_provider = VagrantPlugins::ProviderVirtualBox::Driver::Meta.new
    $vb_vm_info = Hash.new
    vb_provider.execute("showvminfo", machine_id, "--machinereadable").split("\n").each do |info_line|
      info_name, info_value = info_line.split("=", 2)
      $vb_vm_info[info_name] = info_value
    end
  end
  return(quoted_string_to_mac_address($vb_vm_info["macaddress#{nic_idx}"]))
end