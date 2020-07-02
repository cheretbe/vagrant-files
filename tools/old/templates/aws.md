
```ruby
# Require the AWS provider plugin
require 'vagrant-aws'

# Create and configure the AWS instance(s)
Vagrant.configure('2') do |config|

  # Use dummy AWS box
  config.vm.box = 'aws-dummy'

  # Specify AWS provider configuration
  config.vm.provider 'aws' do |aws, override|
    # Read AWS authentication information from environment variables
    aws.access_key_id = ENV['AWS_ACCESS_KEY_ID']
    aws.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']

    # Specify SSH keypair to use
    aws.keypair_name = 'aws-key-pair'

    # Specify region, AMI ID, and security group(s)
    aws.region = 'eu-central-1'
    aws.ami = 'ami-0bdf93799014acdc4'
    # aws.security_groups = ['default']
    aws.instance_type = "t2.micro"
    aws.subnet_id = "subnet-31ac8c7c"
    aws.associate_public_ip = true
    aws.tags = {
      'Name' => 'Vagrant_1',
      'Description' => 'Vagrant AWS test instance'
    }

    # Specify username and private key path
    override.ssh.username = 'ubuntu'
    override.ssh.private_key_path = '~/keys/aws-key-pair.pem'
  end
end
```
