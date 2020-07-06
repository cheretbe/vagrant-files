#!/usr/bin/env python3

import yaml


with open("/etc/netplan/50-vagrant.yaml") as f:
    net_config = yaml.safe_load(f)

print(net_config["network"]["ethernets"])
