require 'yaml'
require 'vagrant'
require Vagrant.source_root.join("plugins/kernel_v2/config/vm")
require_relative '../host_functions.rb'

describe :"vm config test" do
  it "should call vm.network" do
    vm = double(VagrantPlugins::Kernel_V2::VMConfig)
    config = YAML.load('
      private_adapter:
        virtualbox__intnet: "vagrant-intnet"
        ip: "192.168.80.101"
    ')
    expect(vm).to receive(:network).with("public_network", config.transform_keys(&:to_sym)).exactly(1).time
    add_bridged_adapter(vm, config)
  end
end

describe "read_local_settings" do
  it "does something" do
    read_local_config_file = double(host_functions.read_local_config_file)
    # read_local_config_file = double()
    read_local_settings_test("dummy")
  end
end