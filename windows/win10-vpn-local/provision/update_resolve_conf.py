#!/usr/bin/python3

import sys
import os
import shutil
import subprocess

# Why is this script needed:
# https://github.com/cheretbe/notes/blob/master/openvpn.md#dns
# TODO: Consider moving this script to https://github.com/cheretbe/bootstrap

if not os.environ.get("dev", None):
    sys.exit(0)
script_type = os.environ.get("script_type", None)
if not script_type:
    sys.exit(0)

def copy_as_link(src, dst):
    print(f"Copying '{src}' ==> '{dst}'", flush=True)
    if os.path.lexists(dst):
        os.unlink(dst)
    if os.path.islink(src):
        os.symlink(os.readlink(src), dst)
    else:
        shutil.copy(src, dst)

if script_type == "up":
    vpn_dns_servers = []

    for env_var in os.environ:
        if env_var.startswith("foreign_option_"):
            value_parts = os.environ[env_var].split(" ")
            if len(value_parts) == 3 and value_parts[0] == "dhcp-option" and value_parts[1] == "DNS":
                vpn_dns_servers += [value_parts[2]]
    if len(vpn_dns_servers) > 0:
        copy_as_link("/etc/resolv.conf", "/run/vpn_resolv_conf.backup")
        print(f"Updating /etc/resolv.conf to use the following DNS server(s): {vpn_dns_servers}", flush=True)
        os.unlink("/etc/resolv.conf")
        with open("/etc/resolv.conf", "w") as resolv_f:
            for dns_srv in vpn_dns_servers:
                resolv_f.write(f"nameserver {dns_srv}\n")
        subprocess.check_call(["/usr/bin/systemctl", "restart", "dnsmasq.service"])
        sys.stdout.flush()

elif script_type == "down":
    if os.path.isfile("/run/vpn_resolv_conf.backup"):
        copy_as_link("/run/vpn_resolv_conf.backup", "/etc/resolv.conf")
        os.unlink("/run/vpn_resolv_conf.backup")
        subprocess.check_call(["/usr/bin/systemctl", "restart", "dnsmasq.service"])
        sys.stdout.flush()
