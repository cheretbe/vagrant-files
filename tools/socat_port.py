#!/usr/bin/env python3

import os
import sys
import argparse
import shutil
import subprocess
import json
import socket
import contextlib
try:
    import humanfriendly.prompts
except ModuleNotFoundError:
    sys.exit("No module named 'humanfriendly'. You can install it system-wide with 'sudo apt install python3-humanfriendly'")

def socat_to_first_free_port(vm_name):
    # default via 192.168.1.1 dev enp0s31f6 proto dhcp src 192.168.1.2 metric 100
    primary_ip = subprocess.check_output(("ip", "route", "show", "default"), universal_newlines=True).splitlines()[0].split(" ")[8]
    print(f"Using {primary_ip} as primary IP address")

    socat_port = None
    with contextlib.closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as sock:
        for port in range(8291, 8391):
            if sock.connect_ex((primary_ip, port)) == 0:
                print(f"Port {port} is occupied")
            else:
                socat_port = port
                break
    print(f"Using port {socat_port}")

    print(f"Getting host-only IP address for VM '{vm_name}'")
    # 192.168.56.62/24 -> 192.168.56.62
    vm_ip = subprocess.check_output(("vagrant", "ssh", vm_name, "--", ":put [/ip address get [find interface=host_only] address]"), universal_newlines=True).split("/")[0]
    print(f"Forwarding {primary_ip}:{socat_port} to {vm_ip}:8291 with socat")
    subprocess.check_call(("socat", f"tcp-listen:{socat_port},fork,bind={primary_ip}", f"tcp:{vm_ip}:8291"))


def main(args):
    if shutil.which("socat") is None:
        sys.exit("ERROR: socat executable is not available")

    print("Running vagrant status")
    if args.vm_name:
        status_command = ("vagrant", "status", args.vm_name, "--machine-readable")
    else:
        status_command = ("vagrant", "status", "--machine-readable")
    vagrant_status = []
    # https://www.vagrantup.com/docs/cli/machine-readable
    # timestamp,target,type,data...
    for line in subprocess.check_output(
            status_command,
            universal_newlines=True
    ).splitlines():
        vagrant_status.append(line.split(","))

    vms = []
    for status_values in vagrant_status:
        if status_values[2] == "metadata" and status_values[3] == "provider":
            vms.append({"name": status_values[1]})
    for vm in vms:
        for status_values in vagrant_status:
            if status_values[1] == vm["name"] and status_values[2] == "state":
                vm["running"] = (status_values[3] == "running")
        vm["is_ros"] = False
        if os.path.isfile(f".vagrant/machines/{vm['name']}/virtualbox/box_meta"):
            with open(f".vagrant/machines/{vm['name']}/virtualbox/box_meta") as f_meta:
                config = json.load(f_meta)
            vm["is_ros"] = config["name"].startswith("cheretbe/routeros")

    if args.vm_name:
        vm_name = args.vm_name
    else:
        if len(vms) == 1:
            vm_name = vms[0]["name"]
        else:
            vm_names = [i["name"] for i in vms if i["is_ros"] and i["running"]]
            if len(vm_names) == 0:
                sys.exit("ERROR: There are no running RouterOS VMs")
            elif len(vm_names) == 1:
                vm_name = vm_names[0]
                print(f"Auto-selecting the only running RouterOS VM '{vm_name}'")
            else:
                vm_name = humanfriendly.prompts.prompt_for_choice(
                    sorted(vm_names) + ["Exit"]
                )
                if vm_name == "Exit":
                    sys.exit("Cancelled by user")

    vm = next((item for item in vms if item["is_ros"] and item["running"] and (item["name"] == vm_name)), None)
    if not vm:
        sys.exit(f"ERROR: There is no running RouterOS VM named '{vm_name}'")

    try:
        socat_to_first_free_port(vm["name"])
    except KeyboardInterrupt:
        pass

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("vm_name", nargs="?", default="", help="VM name (optional)")
    args = parser.parse_args()

    main(args)
