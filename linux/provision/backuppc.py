#!/usr/bin/env python3

import os
import sys
import apt
import subprocess
import requests
import shutil
import distutils.version
import pwd
import argparse

parser = argparse.ArgumentParser(description="BackupPC installation script")
parser.add_argument("-l", "--data-dir-to-link", dest="data_dir_to_link", default=None,
    help="Path to the BackupPC data directory to be symlinked as /var/lib/backuppc")
parser.add_argument("-n", "--hostname", dest="hostname", default="backuppc",
    help="Host name (default: backuppc)")
parser.add_argument("-а", "--force-version", dest="force_version", default=None,
    help="Set specific version to install", metavar="VERSION")

options = parser.parse_args()

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


run("apt-get -q update")
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

installed_version = None
upgrade_mode = False
# We are looking for a line like this:
# '# Version 4.2.1, released 7 May 2018.'
if os.path.isfile("/usr/local/BackupPC/bin/BackupPC"):
    with open("/usr/local/BackupPC/bin/BackupPC", "r") as f:
        for line in f:
            if line.startswith("# Version "):
                installed_version = line[10:].split(",")[0]
                break
if installed_version:
    print("Currently isntalled version is: " + installed_version)
    latest_version = requests.get("https://api.github.com/repos/backuppc/backuppc/releases/latest").json()["tag_name"]
    print("Latest version is: " + latest_version)
    if distutils.version.LooseVersion(latest_version) > distutils.version.LooseVersion(installed_version):
        print("Upgrading {} ==> {}".format(installed_version, latest_version))
        upgrade_mode = True
    else:
        print("BackupPC does not need an upgrade. Exiting")
        sys.exit(0)

if upgrade_mode:
    run("service backuppc stop")
else:
    print("Installing BackupPC")

    # For a symlink with non-existing target exists is False, but islink is True
    if os.path.exists("/var/lib/backuppc") or os.path.islink("/var/lib/backuppc"):
        raise Exception("'/var/lib/backuppc' already exists. Exiting")
    if options.data_dir_to_link:
        run("ln -s {} /var/lib/backuppc".format(options.data_dir_to_link))

    user_exists = False
    try:
        pwd.getpwnam("backuppc")
        user_exists = True
    except KeyError:
        pass
    if user_exists:
        raise Exception("User `backuppc' already exists. Exiting")
    run("adduser --system --home /var/lib/backuppc --group --disabled-password --shell /bin/false backuppc")

    if options.data_dir_to_link:
        run("chown backuppc:backuppc {}".format(options.data_dir_to_link))

    run("mkdir -p /var/lib/backuppc/.ssh")
    run("chmod 700 /var/lib/backuppc/.ssh")
    # [!] 'StrictHostKeyChecking no' parameter is optional, it allows connecting to any host
    # without explicitly adding it to .ssh/known_hosts
    with open("/var/lib/backuppc/.ssh/config", "w") as f:
        f.write("BatchMode yes\nStrictHostKeyChecking no\n")
    run('ssh-keygen -q -t rsa -b 4096 -N "" -C "BackupPC key" -f /var/lib/backuppc/.ssh/id_rsa')
    run("chmod 600 /var/lib/backuppc/.ssh/id_rsa")
    run("chmod 644 /var/lib/backuppc/.ssh/id_rsa.pub")
    run("chown -R backuppc:backuppc /var/lib/backuppc/.ssh")

# print("there you go")
# sys.exit(0)

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

if options.force_version:
    release_info = requests.get("https://api.github.com/repos/backuppc/backuppc/releases/tags/{}".format(options.force_version)).json()
else:
    release_info = requests.get("https://api.github.com/repos/backuppc/backuppc/releases/latest").json()
local_filename = download_file(release_info["assets"][0]["browser_download_url"])
run("tar -xzvf " + local_filename)
os.chdir("BackupPC-" + release_info["tag_name"])
if upgrade_mode:
    run("./configure.pl --batch --config-path /etc/BackupPC/config.pl")
else:
    run("./configure.pl --batch --cgi-dir /var/www/cgi-bin/BackupPC "
        "--data-dir /var/lib/backuppc --hostname {} --html-dir /var/www/html/BackupPC "
        "--html-dir-url /BackupPC --install-dir /usr/local/BackupPC".format(options.hostname))

if show_postfix_warning:
    print("\033[93m\n[!] Don't forget to configure MTA with 'dpkg-reconfigure postfix --priority low' \033[0m")