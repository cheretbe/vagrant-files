#!/usr/bin/env python3

import os
import apt
import subprocess
import requests
import shutil

needed_packages = ["apache2", "apache2-utils", "libapache2-mod-perl2",
    "smbclient", "postfix", "libapache2-mod-scgi", "libarchive-zip-perl",
    "libfile-listing-perl", "libxml-rss-perl", "libcgi-session-perl", "make",
    "gcc"]

def run(command):
    print(command)
    subprocess.check_call(command, shell=True)

def download_file(url):
    print("Downloading " + url)
    local_filename = url.split('/')[-1]
    r = requests.get(url, stream=True)
    with open(local_filename, 'wb') as f:
        shutil.copyfileobj(r.raw, f)
    return local_filename


# run("apt-get -q update")
packages_to_install = []
apt_cache = apt.Cache()
for needed_package in needed_packages:
    if not apt_cache[needed_package].is_installed:
        packages_to_install += [needed_package]
show_postfix_warning = not apt_cache["postfix"].is_installed

if len(packages_to_install) != 0:
    print("Installing packages: " + ", ".join(packages_to_install))
    # DEBIAN_FRONTEND variable is set to avoid postfix package showing configuration dialog
    run("DEBIAN_FRONTEND=noninteractive apt-get install -y -q " + " ".join(packages_to_install))

src_dir = os.path.expanduser("~/source")
os.makedirs(src_dir, exist_ok=True)
os.chdir(src_dir)

# curl https://api.github.com/rate_limit
release_info = requests.get("https://api.github.com/repos/backuppc/backuppc-xs/releases/latest").json()
local_filename = download_file(release_info["assets"][0]["browser_download_url"])
run("tar -xzvf " + local_filename)
os.chdir("BackupPC-XS-" + release_info["tag_name"])
run("perl Makefile.PL")
run("make")
run("make test")
run("make install")
os.chdir("..")

release_info = requests.get("https://api.github.com/repos/backuppc/rsync-bpc/releases/latest").json()
local_filename = download_file(release_info["assets"][0]["browser_download_url"])
run("tar -xzvf " + local_filename)
os.chdir("rsync-bpc-" + release_info["tag_name"])
run("./configure")
run("make")
run("make install")
os.chdir("..")

release_info = requests.get("https://api.github.com/repos/backuppc/backuppc/releases/latest").json()
local_filename = download_file(release_info["assets"][0]["browser_download_url"])
run("tar -xzvf " + local_filename)
os.chdir("BackupPC-" + release_info["tag_name"])
run("ls -lh")

if show_postfix_warning:
    print("\033[93m\n[!] Don't forget to configure MTA with 'dpkg-reconfigure postfix --priority low' \033[0m")