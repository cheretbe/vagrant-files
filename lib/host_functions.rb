require "ostruct"
require "yaml"

class CustomAnsibleError < Vagrant::Errors::VagrantError
  error_message(
    "Ansible provision failed to complete successfully. Any error output should be visible above"
  )
end

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

@vagrant_ui = Vagrant::UI::Colored.new

def read_local_settings_new(settings)
  missing_mandatory_settings = []

  config_file_name = File.join(File.dirname(caller_locations.first.path), "local-config.yml")
  local_config = {}
  if File.file?(config_file_name)
    Vagrant.global_logger.warn("Reading local config from #{config_file_name}")
    local_config = YAML.load_file(config_file_name)
    if local_config.nil?
      local_config = {}
    end
  else
    Vagrant.global_logger.warn("Local config file #{config_file_name} is missing")
  end

  settings.each do |setting|
    setting = setting.transform_keys(&:to_s)
    if not local_config.key?(setting["name"])
      if setting.key?("default")
        Vagrant.global_logger.warn("  Using default value '#{setting["default"]}' for '#{setting["name"]}' setting")
        local_config[setting["name"]] = setting["default"]
      else
        missing_mandatory_settings.push(" - " + setting["name"])
      end
    end
  end

  if missing_mandatory_settings.length > 0
    missing_msg = format("The following mandatory settings are not configured "\
      "in '%s':\n%s", config_file_name, missing_mandatory_settings.join("\n"))
    if ARGV[0] == "up"
      @vagrant_ui.error (missing_msg + "\nAborting")
      abort
    else
      @vagrant_ui.warn missing_msg
    end
  end

  Vagrant.global_logger.warn("Final local config:")
  local_config.each do |config_key, config_value|
    Vagrant.global_logger.warn("  #{config_key} = #{config_value}")
  end
  return local_config
end

def read_local_settings(settings)
  missing_mandatory_settings = []
  config_file_name = File.join(File.dirname(caller_locations.first.path), "local-config.yml")
  Vagrant.global_logger.info("Local config: #{config_file_name}")
  local_config = {}
  if File.file?(config_file_name)
    Vagrant.global_logger.info("Reading local config from #{config_file_name}")
    local_config = YAML.load_file(config_file_name)
    if local_config.nil?
      local_config = {}
    end
  end

  return_value = {}
  settings.each do |setting|
    setting_value = nil
    if local_config.key?(setting["name"])
      setting_value = local_config[setting["name"]]
    else
      if setting.key?("default")
        setting_value = setting['default']
      else
        Vagrant.global_logger.info(format("  Using default value for '%s' setting", setting["name"]))
        missing_mandatory_settings.push(" - " + setting["name"])
      end
    end
    Vagrant.global_logger.info(format("  %s = %s", setting["name"], setting_value))
    return_value[setting["name"]] = setting_value
  end

  if missing_mandatory_settings.length > 0
    missing_msg = format("The following mandatory settings are not configured "\
      "in '%s':\n%s", config_file_name, missing_mandatory_settings.join("\n"))
    if ARGV[0] == "up"
      @vagrant_ui.error (missing_msg + "\nAborting")
      abort
    else
      @vagrant_ui.warn missing_msg
    end
  end

  return OpenStruct.new(return_value)
end

def get_standard_setting(setting_name, vm_name, settings, &block)
  setting = nil
  if settings.key?(setting_name)
    setting = settings[setting_name]
  end
  if settings.key?("#{setting_name}.#{vm_name}")
    setting = settings["#{setting_name}.#{vm_name}"]
  end
  yield(setting)
end

def apply_standard_settings(config, vm_name, settings, no_synced_dirs: false)
  config.vm.provider("virtualbox") do |vb|
    vb.customize ["modifyvm", :id, "--groups", "/__vagrant"]
    get_standard_setting("memory", vm_name, settings) do |setting|
      vb.memory = setting unless setting.nil?
    end
    get_standard_setting("cpus", vm_name, settings) do |setting|
      vb.cpus = setting unless setting.nil?
    end
    get_standard_setting("sound", vm_name, settings) do |setting|
      # nil is falsey, so there will be no sound if the setting is not present
      add_audio_controler(vb) if setting
    end
  end
  get_standard_setting("networks", vm_name, settings) do |networks|
    unless networks.nil?
      networks.each do |network|
        network.each do |network_key, network_value|
          # https://github.com/hashicorp/vagrant/blob/main/plugins/kernel_v2/config/vm.rb
          # @param [Symbol] type Type of network
          # @param [Hash] options Options for the network.
          # def network(type, **options)
          config.vm.network(network_key.to_sym, **network_value.transform_keys(&:to_sym))
        end
      end
    end
  end
  unless no_synced_dirs
    config.vm.synced_folder "/", "/host"
    config.vm.synced_folder Dir.home, "/host_home"
  end
end

def add_audio_controler(vb)
  audio_driver = case RUBY_PLATFORM
    when /linux/
      "pulse"
    when /darwin/
      "coreaudio"
    else
      "dsound"
    end
  vb.customize ["modifyvm", :id, "--audio", audio_driver, "--audiocontroller", "hda"]
  vb.customize ["modifyvm", :id, "--audioout", "on"]
end

def check_env_variables(mandatory_vars: [], optional_vars: [])
  missing_mandatory_vars = []
  missing_optional_vars = []

  mandatory_vars.each do |mandatory_var|
    if not ENV.has_key?(mandatory_var)
      missing_mandatory_vars.push(" - " + mandatory_var)
    end
  end

  optional_vars.each do |optional_var|
    if not ENV.has_key?(optional_var)
      missing_optional_vars.push(" - " + optional_var)
    end
  end

  if missing_optional_vars.length > 0
    @vagrant_ui.warn format("The following recommended environment variable(s) "\
      "are not defined:\n%s", missing_optional_vars.join("\n"))
  end

  if missing_mandatory_vars.length > 0
    @vagrant_ui.error format("The following mandatory environment variable(s) are "\
      "not defined:\n%s", missing_mandatory_vars.join("\n"))
    if ARGV[0] == "up"
      @vagrant_ui.error "Aborting"
      abort
    end
  end
end

# def define(name, options=nil, &block)
# https://github.com/hashicorp/vagrant/blob/main/plugins/kernel_v2/config/vm.rb#L434
def define_ansible_controller(
    config, ip, intnet_name: "vagrant-intnet", custom_playbook: nil,
    common_repo_source: "master", &block
  )
  valid_repo_values = ["master", "develop", "local"]
  unless valid_repo_values.include? common_repo_source
    @vagrant_ui.error (
      "Incorrect value for 'common_repo_source' parameter: #{common_repo_source}. Valid " +
      "options are #{valid_repo_values}"
    )
    abort
  end

  config.vm.define :"ansible-controller" do |ansible_controller|
    ansible_controller.vm.box = "cheretbe/ansible-controller"
    ansible_controller.vm.hostname = "ansible-controller"
    ansible_controller.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--groups", "/__vagrant"]
    end
    ansible_controller.vm.network "private_network", ip: ip, virtualbox__intnet: intnet_name

    ansible_controller.vm.synced_folder "/", "/host"
    ansible_controller.vm.synced_folder Dir.home, "/host_home"

    ansible_controller.vm.provision "file",
      source: File.dirname(__FILE__) + "/ansible_controller_provision.yml",
      destination: "/home/vagrant/ansible_controller_provision.yml"

    ansible_controller.vm.provision "ansible_local" do |ansible|
      ansible.compatibility_mode = "2.0"
      ansible.install = false
      ansible.playbook = "/home/vagrant/ansible_controller_provision.yml"
      ansible.extra_vars = {
        common_repo_source: common_repo_source
      }
    end

    unless custom_playbook.nil?
      ansible_controller.vm.provision "ansible_local" do |ansible|
        ansible.compatibility_mode = "2.0"
        ansible.install = false
        ansible.playbook = custom_playbook
      end
    end

    block.call ansible_controller if block
  end
end

# Based on:
# https://github.com/hashicorp/vagrant/blob/main/plugins/provisioners/ansible/provisioner/base.rb
# https://github.com/hashicorp/vagrant/blob/main/plugins/provisioners/ansible/provisioner/guest.rb
def do_host_ansible_provision(machine, target_host, playbook, extra_vars: {})
  machine.ui.detail("Provisioning with Ansible playbook '#{playbook}'")
  env_variables = "PYTHONUNBUFFERED=1 ANSIBLE_SSH_RETRIES=3"
  env_variables += " ANSIBLE_FORCE_COLOR=true" if machine.env.ui.color?

  command = "#{env_variables} "\
            "/home/vagrant/.cache/venv/ansible/bin/ansible-playbook "\
            "-i /vagrant/provision/inventory.yml "\
            "-l #{target_host} --extra-vars #{extra_vars.to_json.shellescape} "\
            "/vagrant/provision/#{playbook}"
  Vagrant.global_logger.info("Ansible command: #{command}")

  ansible_controller = machine.env.machine(:"ansible-controller", :virtualbox)
  ansible_controller.communicate.execute("rm ~/.ssh/known_hosts", error_check: false)
  result = ansible_controller.communicate.execute(command, error_check: false) do |type, data|
    if [:stderr, :stdout].include?(type)
      machine.env.ui.info(data, new_line: false, prefix: false)
    end
  end
  raise CustomAnsibleError if result != 0
end


def ansible_provision(config, playbook, extra_vars: {})
  config.trigger.after [:up, :reload, :provision, :snapshot_restore] do |trigger|
    trigger.ruby do |env,machine|
      if machine.state.id == :running and machine.custom_provision_enabled
        # machine.ui.warn(machine.name)
        # machine.ui.warn(extra_vars)
        do_host_ansible_provision machine,
          target_host=machine.name,
          playbook=playbook,
          extra_vars: extra_vars
      end
    end
  end
end