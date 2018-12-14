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

def ip_address_by_interface_name(if_name):
    ip_address = None
    for line in subprocess.check_output("ip addr show " + if_name, shell=True).decode("utf-8").splitlines():
        values = line.split()
        if values[0] == "inet":
            ip_address = values[1]
    if not ip_address:
        raise Exception("Cannot find IP addres for interface " + if_name)
    return ip_address



# http://www.brianlinkletter.com/how-to-build-a-network-of-linux-routers-using-quagga/
# https://www.linux.com/learn/intro-to-linux/2018/3/dynamic-linux-routing-quagga
# http://calcn1.com/blog/linux/52.html
# http://www.tux.in.ua/articles/2182
# https://www.nongnu.org/quagga/docs/docs-multi/OSPF-Configuration-Examples.html

parser = argparse.ArgumentParser(description="Quagga OSPF configuration script")
parser.add_argument("interfaces", nargs="+", metavar="interface",
    help="Interface name or MAC-address")
options = parser.parse_args()

for i in range(len(options.interfaces)):
    if (":" in options.interfaces[i]) and (len(options.interfaces[i].split(":")) == 6):
      options.interfaces[i] = interface_name_by_mac(options.interfaces[i])

needed_packages = ["quagga", "quagga-doc"]

run("apt-get -q update")
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

ospfd_conf_contents += "\nrouter ospf\n  ospf router-id 192.168.199.10\n"

for interface in options.interfaces:
    ospfd_conf_contents +=  "  network " + ip_address_by_interface_name(interface) + " area 1\n"

print("Writing '/etc/quagga/ospfd.conf'")
with open("/etc/quagga/ospfd.conf", "w") as f:
    f.write(ospfd_conf_contents)

# ! -*- zebra -*-
# hostname host1
# password zebra
# enable password zebra

# log file /var/log/quagga/zebra.log

# interface enp0s8
# ip address 192.168.100.10/24
# ip forwarding

# interface enp0s9
# ip address 192.168.199.10/24
# ip forwarding