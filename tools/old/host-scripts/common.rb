# Custom plugin to work around the following issue:
# https://github.com/hashicorp/vagrant/issues/9846
class CustomProvisionPlugin < Vagrant.plugin('2')
  class CustomProvisionAction
    def initialize(app, env)
      @app = app
    end

    def call(env)
      @app.call(env)
      machine = env[:machine]
      class << machine
        attr_accessor :custom_provision_enabled
      end
      machine.custom_provision_enabled = env[:provision_enabled]
    end
  end

  name "custom_provision"

  action_hook "custom_provision" do |hook|
    hook.after Vagrant::Action::Builtin::Provision, CustomProvisionAction
  end
end


def quoted_string_to_mac_address(str)
  # "0800278917AB" ==> 08:00:27:89:17:AB
  return (str[1..2] + ":" + str[3..4] + ":" + str[5..6] +
    ":" + str[7..8] + ":" + str[9..10] + ":" + str[11..12])
end

def get_vb_nic_mac_address_list(machine)
  vm_nic_count = 0
  vm_NIC_mac_addresses = []

  vm_info = Hash.new
  machine.provider.driver.execute("showvminfo", machine.id, "--machinereadable").split("\n").each do |info_line|
    info_name, info_value = info_line.split("=", 2)
    vm_info[info_name] = info_value

    # showvminfo returns "none" for non-present network adapters
    # So we are dealing with values like these:
    # nic1="nat" nic2="hostonly" nic3="none" etc.
    if info_name.start_with?("nic") then
      if info_name.delete("nic").to_i != 0 and info_value != "\"none\"" then
        vm_nic_count += 1
      end
    end
  end

  # MAC addresses have format: macaddress1="0800278917AB" etc.
  # Convert them to "08:00:27:89:17:AB" format
  for i in 1..vm_nic_count
    vm_NIC_mac_addresses += [quoted_string_to_mac_address(vm_info["macaddress#{i}"])]
  end

  return vm_NIC_mac_addresses
end

def upload_mikrotik_script(machine, source_file_path, target_script_name)
  puts "Uploading script '#{target_script_name}' from file '#{source_file_path}'"

  system("vagrant", "ssh", "#{machine.name}", "--", ":if ([:len [/system script find " +
    "name=\"#{target_script_name}\"]] != 0) do={ :put \"Target script already exists. Removing\"; " +
    "/system script remove #{target_script_name} }")

  machine.communicate.tap do |comm|
    comm.upload(source_file_path, "temp_script_2del.rsc")
  end
  system("vagrant", "ssh", "#{machine.name}", "--", "/system script add name=" +
    target_script_name + " source=[/file get temp_script_2del.rsc contents]")
  system("vagrant", "ssh", "#{machine.name}", "--", ":delay 5; /file remove temp_script_2del.rsc")
end