#!/usr/bin/python3

import sys
import os

if not os.environ.get("dev", None):
    sys.exit(0)
script_type = os.environ.get("script_type", None)
if not script_type:
    sys.exit(0)

# https://stackoverflow.com/questions/4847615/copying-a-symbolic-link-in-python
def copy_as_link(src, dst):
    if os.path.islink(src):
        os.symlink()

if script_type == "up":
    vpn_resolv_conf = ""

    for env_var in os.environ:
        if env_var.startswith("foreign_option_"):
            value_parts = os.environ[env_var].split(" ")
            if len(value_parts) == 3 and value_parts[0] == "dhcp-option" and value_parts[1] == "DNS":
                vpn_resolv_conf += "nameserver " + value_parts[2] + "\n"
    if vpn_resolv_conf:
        print(vpn_resolv_conf)
elif script_type == "down":
    print("==> down")

# print(sys.argv)
