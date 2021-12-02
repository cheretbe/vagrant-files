require "ostruct"

@vagrant_ui = Vagrant::UI::Colored.new

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

def add_bridged_adapter(vm, adapter_settings)
  # Convert hash keys from strings to symbols
  vm.network("public_network", adapter_settings.transform_keys(&:to_sym))
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
