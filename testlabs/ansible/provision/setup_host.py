#!/usr/bin/env python3

# ssh-keygen -yf ~/.vagrant.d/insecure_private_key
ansible_pub_key = (
    "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz"
    "4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6Iedplq"
    "oPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQ"
    "PyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhM"
    "mBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlq"
    "m8tehUc9c9WhQ=="
)

with open("/home/vagrant/.ssh/authorized_keys", "r+") as fh:
    for line in fh:
        if line.strip() == ansible_pub_key:
            break
    else:
        print("Adding vagrant@ansible's key to authorized keys file")
        print(ansible_pub_key, file=fh)
