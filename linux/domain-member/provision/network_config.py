#!/usr/bin/env python3

import yaml
import subprocess

def main():
    cloud_config_updated = False
    with open("/etc/netplan/50-cloud-init.yaml") as conf_f:
        net_config = yaml.safe_load(conf_f)

    for if_name, if_config in net_config["network"]["ethernets"].items():
        if if_config.get("dhcp4-overrides") is None:
            if_config["dhcp4-overrides"] = {"use-dns": False}
            cloud_config_updated = True

    if cloud_config_updated:
        with open("/etc/netplan/50-cloud-init.yaml", "w") as conf_f:
            conf_f.write(yaml.dump(net_config, default_flow_style=False))


    vagrant_config_updated = False
    with open("/etc/netplan/50-vagrant.yaml") as conf_f:
        net_config = yaml.safe_load(conf_f)

    intnet_if_name = None
    intnet_if_config = None
    for if_name, if_config in net_config["network"]["ethernets"].items():
        if if_config["addresses"] == ["192.168.199.12/24"]:
            intnet_if_name = if_name
            intnet_if_config = if_config

    if intnet_if_config.get("nameservers") != {"addresses": ["192.168.199.10"]}:
        intnet_if_config["nameservers"] = {"addresses": ["192.168.199.10"]}
        vagrant_config_updated = True

    if vagrant_config_updated:
        with open("/etc/netplan/50-vagrant.yaml", "w") as conf_f:
            conf_f.write(yaml.dump(net_config, default_flow_style=False))

    if cloud_config_updated or vagrant_config_updated:
        subprocess.check_call(["netplan", "apply"])

    print(intnet_if_name)

if __name__ == "__main__":
    main()
