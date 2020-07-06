#!/usr/bin/env python3

import os
import subprocess
import yaml

def main():
    cloud_config_updated = False
    with open("/etc/netplan/50-cloud-init.yaml") as conf_f:
        cloud_config = yaml.safe_load(conf_f)

    for if_name, if_config in cloud_config["network"]["ethernets"].items():
        if if_config.get("dhcp4-overrides") is None:
            if_config["dhcp4-overrides"] = {"use-dns": False}
            cloud_config_updated = True

    if cloud_config_updated:
        with open("/etc/netplan/50-cloud-init.yaml", "w") as conf_f:
            conf_f.write(yaml.dump(cloud_config, default_flow_style=False))

    with open("/etc/netplan/50-vagrant.yaml") as conf_f:
        vagrant_config = yaml.safe_load(conf_f)

    intnet_if_name = None
    for if_name, if_config in vagrant_config["network"]["ethernets"].items():
        if if_config["addresses"] == ["192.168.199.12/24"]:
            intnet_if_name = if_name

    custom_dns_config = {
        "network": {
            "ethernets": {
                intnet_if_name: {
                    "nameservers": {"addresses": ["192.168.199.10"]}
                }
            },
            "renderer": "networkd",
            "version": 2
        }
    }

    custom_config_updated = False
    if os.path.isfile("/etc/netplan/90-domain-dns.yaml"):
        with open("/etc/netplan/90-domain-dns.yaml") as conf_f:
            existing_dns_config = yaml.safe_load(conf_f)
        custom_config_updated = existing_dns_config != custom_dns_config
    else:
        custom_config_updated = True

    if custom_config_updated:
        with open("/etc/netplan/90-domain-dns.yaml", "w") as conf_f:
            conf_f.write(yaml.dump(custom_dns_config, default_flow_style=False))

    if cloud_config_updated or custom_config_updated:
        subprocess.check_call(["netplan", "apply"])

    print(intnet_if_name)

if __name__ == "__main__":
    main()
