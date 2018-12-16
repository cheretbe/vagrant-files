#!/usr/bin/env python3

import apt
import os
import sys
import subprocess
import socket
import argparse
import json

def run(command):
    print(command)
    subprocess.check_call(command, shell=True)

def interface_name_by_mac(mac_address):
    if_name = None
    for interface in os.listdir("/sys/class/net/"):
        with open("/sys/class/net/{}/address".format(interface), "r") as f:
            if_mac = f.read().rstrip()
        if if_mac.lower() == mac_address.lower():
            if_name = interface
            print("{} name is '{}'".format(mac_address, if_name))
            break
    if not if_name:
        raise Exception("Cannot find network interface with MAC-address " + mac_address)
    return if_name

parser = argparse.ArgumentParser(description="Quagga OSPF configuration script")
parser.add_argument("interfaces", nargs="+", metavar="interface",
    help="Interface name or MAC-address")
parser.add_argument("--router-id", required=True, help="router-ID of the OSPF process")
parser.add_argument("--networks", required=True, nargs="+", help="network(s) to provide to other OSPF routers")
options = parser.parse_args()

for i in range(len(options.interfaces)):
    if (":" in options.interfaces[i]) and (len(options.interfaces[i].split(":")) == 6):
        options.interfaces[i] = interface_name_by_mac(options.interfaces[i])

needed_packages = ["quagga", "quagga-doc"]

run("apt -q update")
packages_to_install = []
apt_cache = apt.Cache()
for needed_package in needed_packages:
    if not apt_cache[needed_package].is_installed:
        packages_to_install += [needed_package]

if len(packages_to_install) != 0:
    run("apt-get install -y -q " + " ".join(packages_to_install))

if not os.path.isfile("/etc/quagga/daemons.bak"):
    run("cp /etc/quagga/daemons /etc/quagga/daemons.bak")
print("Updating '/etc/quagga/daemons'")
with open("/etc/quagga/daemons", "r+") as f:
    old_lines = f.readlines()
    f.seek(0)
    for line in old_lines:
        if line == "zebra=no\n":
            print("Setting 'zebra=yes'")
            line = "zebra=yes\n"
        elif line == "ospfd=no\n":
            print("Setting 'ospfd=yes'")
            line = "ospfd=yes\n"
        f.write(line)
    f.truncate()

ospfd_conf_contents = r"""! -*- ospf -*-
hostname {host}
password zebra
log file /var/log/quagga/ospfd.log
""".format(host=socket.gethostname())

for interface in options.interfaces:
    ospfd_conf_contents += "\ninterface " + interface + "\n  ip ospf hello-interval 1\n"

ospfd_conf_contents += ("\nrouter ospf\n  ospf router-id {}\n").format(options.router_id)

for network in options.networks:
    ospfd_conf_contents +=  "  network " + network + " area 1\n"

print("Writing '/etc/quagga/ospfd.conf'")
with open("/etc/quagga/ospfd.conf", "w") as f:
    f.write(ospfd_conf_contents)
# print(ospfd_conf_contents)

zebra_conf_contents = r"""! -*- zebra -*-
hostname {host}
password zebra
enable password zebra
log file /var/log/quagga/zebra.log
""".format(host=socket.gethostname())

print("Writing '/etc/quagga/zebra.conf'")
with open("/etc/quagga/zebra.conf", "w") as f:
    f.write(zebra_conf_contents)
# print(zebra_conf_contents)

run("service quagga restart")