#!/bin/bash -eux

SSH_USER=${SSH_USERNAME:-vagrant}
VBOX_VERSION=5.1.10_112026

echo "==> Installing VirtualBox guest additions"
# Assuming the following packages are installed
apt-get install -y linux-headers-$(uname -r) build-essential perl
apt-get install -y dkms

mount -t iso9660 /dev/sr1 /media
sh /media/VBoxLinuxAdditions.run
umount /media
