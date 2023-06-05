require 'yaml'
require 'json'
# require 'pp'
# require 'pry'
require "awesome_print" # gem install awesome_print
# require "config"

# https://github.com/danielsdeleo/deep_merge
# gem fetch deep_merge
$LOAD_PATH.unshift('.')
require('deep_merge')

# puts "There you go"



# local_config = YAML.load_file(config_file_name)
local_config = YAML.load_file("/vagrant_lib/lib/multi_vm_settings_template.yml") #.transform_keys(&:to_sym)

# puts(local_config)
# pp local_config
# Pry::ColorPrinter.pp(local_config)
ap local_config

puts "===================================="

default_config = {"vms": {"vm1": {"memory": 2048 }}}
# Ugly hack
# https://stackoverflow.com/questions/39240219/how-to-recursively-convert-keys-of-ruby-hashes-that-are-symbols-to-string
default_config = JSON.parse(JSON.dump(default_config))
ap default_config

# print(local_config["vms"])
puts "===================================="
# default_config.merge(local_config)

# resulting_config = default_config.merge(local_config)
resulting_config = default_config.deep_merge(local_config)

ap default_config.merge(resulting_config)
puts resulting_config

puts ({"string_key" => "value"})
puts ({"symbol_key": "value"})
