#!/usr/bin/env python3

with open ("/vagrant/provision/id_rsa.pub", "r") as fh:
    ansible_pub_key = fh.read().strip()

with open("/home/vagrant/.ssh/authorized_keys", "r+") as fh:
    for line in fh:
        if line.strip() == ansible_pub_key:
            break
    else:
        print("Adding vagrant@ansible's key to authorized keys file")
        print(ansible_pub_key, file=fh)
