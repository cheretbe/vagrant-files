#!/usr/bin/env python3

import subprocess

def main():
    pool_exists = True
    try:
        subprocess.check_call(["zpool", "list", "zfs-test"])
    except subprocess.CalledProcessError:
        pool_exists = False

    if not pool_exists:
        test_device = None
        for line in subprocess.check_output(
                ["lsblk", "-l", "-d", "-p", "-n", "-o", "NAME,SIZE"],
                universal_newlines=True
        ).splitlines():
            device_info = line.split()
            if device_info[1] == "20G":
                test_device = device_info[0]
        print("Creating ZFS pool 'zfs-test'")
        subprocess.check_call(["zpool", "create", "zfs-test", test_device])

if __name__ == "__main__":
    main()
