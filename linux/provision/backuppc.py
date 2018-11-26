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
parser.add_argument('-b', '--batch', dest='batch_mode', action='store_true',
    default=False, help='Run in batch mode without any prompts')

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
    if options.batch_mode:
        # DEBIAN_FRONTEND variable is set to avoid postfix package showing configuration dialog
        run("DEBIAN_FRONTEND=noninteractive apt-get install -y -q " + " ".join(packages_to_install))
    else:
        run("apt-get install -y " + " ".join(packages_to_install))

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

    print("'backuppc' service status:")
    # 'systemctl is-active' echoes current status and sets exit code to 0 if it is 'active'
    if subprocess.run("systemctl is-active backuppc.service", shell=True).returncode == 0:
        print("Stopping 'backuppc' service")
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
    run("cp httpd/BackupPC.conf /etc/apache2/conf-available/backuppc.conf")

    # Allows to connect to web UI from anywhere, not only from 127.0.0.1 by removing the following lines:
    # order deny,allow
    # deny from all
    # allow from 127.0.0.1
    with open("/etc/apache2/conf-available/backuppc.conf", "r+") as f:
        old_lines = f.readlines()
        f.seek(0)
        for line in old_lines:
            if line not in ("order deny,allow\n", "deny from all\n", "allow from 127.0.0.1\n"):
                f.write(line)
        f.truncate()

    run("cp /etc/apache2/envvars /etc/apache2/envvars.bak")
    # Note that changing the apache user and group (next two commands) could cause other services
    # provided by apache to fail. There are alternatives if you don't want to change the apache
    # user: use SCGI or a setuid BackupPC_Admin script - see the docs.
    run('sed -i "s/export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=backuppc/" /etc/apache2/envvars')
    run('sed -i "s/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=backuppc/" /etc/apache2/envvars')

    run("cp /var/www/html/index.html /var/www/html/index.html.bak")
    with open("/var/www/html/index.html", "w") as f:
        f.write('<html><head><meta http-equiv="refresh" content="0; url=/BackupPC_Admin"></head></html>\n')

    run("a2enconf backuppc")
    run("a2enmod cgid")
    run("service apache2 restart")

    run("cp systemd/backuppc.service /etc/systemd/system")
    run('sed -i "s/#Group=backuppc/Group=backuppc/" /etc/systemd/system/backuppc.service')
    run("systemctl daemon-reload")
    run("systemctl enable backuppc.service")

    run("chmod u-s /var/www/cgi-bin/BackupPC/BackupPC_Admin")
    run("touch /etc/BackupPC/BackupPC.users")
    run("cp /etc/BackupPC/config.pl /etc/BackupPC/config.pl.bak")
    # Replace
    #    $Conf{CgiAdminUserGroup} = '';
    #    $Conf{CgiAdminUsers}     = '';
    # with
    #    $Conf{CgiAdminUserGroup} = 'backuppc';
    #    $Conf{CgiAdminUsers}     = 'backuppc';
    with open("/etc/BackupPC/config.pl", "r+") as f:
        old_lines = f.readlines()
        f.seek(0)
        for line in old_lines:
            # if line not in ("order deny,allow\n", "deny from all\n", "allow from 127.0.0.1\n"):
            if line == "$Conf{CgiAdminUserGroup} = '';\n":
                line = "$Conf{CgiAdminUserGroup} = 'backuppc';\n"
            if line == "$Conf{CgiAdminUsers}     = '';\n":
                line = "$Conf{CgiAdminUsers}     = 'backuppc';\n"
            f.write(line)
        f.truncate()

    run("chown -R backuppc:backuppc /etc/BackupPC")

    run("htpasswd /etc/BackupPC/BackupPC.users backuppc")

run("service backuppc start")

if show_postfix_warning:
    print("\033[93m\n[!] Don't forget to configure MTA with 'dpkg-reconfigure postfix --priority low' \033[0m")