#!/bin/bash

set -euxv -o pipefail

export VAGRANT="/vagrant"
export PROXY=${PROXY:-192.168.87.254}

> /etc/apt/apt.conf

echo "Installing packages for pxe server"
apt-get update
apt-get install -fy dnsmasq nginx iptables-persistent apt-cacher-ng

#Location for all pxe files
mkdir -p /srv/tftpboot

if [[ ! -f /srv/tftpboot/grubnetx64.efi.signed ]]; then
 echo "Downloading grub efi signed pxe boot image"
 wget -O /srv/tftpboot/grubnetx64.efi.signed http://archive.ubuntu.com/ubuntu/dists/xenial/main/uefi/grub2-amd64/current/grubnetx64.efi.signed >/dev/null 2>&1
fi
if [[ ! -f /srv/tftpboot/netboot.tar.gz ]]; then
 echo "Downloading netboot tarball"
 wget -O /srv/tftpboot/netboot.tar.gz http://archive.ubuntu.com/ubuntu/dists/xenial/main/installer-amd64/current/images/netboot/netboot.tar.gz
fi

#Unzip netboot
cd /srv/tftpboot
tar xzf netboot.tar.gz

#Setup grub with preseed
[[ ! -d /srv/tftpboot/grub ]] && mkdir -p /srv/tftpboot/grub
cp -f ${VAGRANT}/pxe_files/grub-network.cfg /srv/tftpboot/grub/

#Setup non-grub install
cp -f ${VAGRANT}/pxe_files/txt-network.cfg /srv/tftpboot/ubuntu-installer/amd64/boot-screens/txt.cfg

#Copy preseed and scripts to html
cp -f ${VAGRANT}/pxe_files/secure-desktop.seed /tmp/secure-desktop.seed
echo "Updating late_command for preseed"
#$tmp/script/setup_preseed_command.sh >> /tmp/secure-desktop.seed

LATE_COMMAND="echo 'Processing scripts'" 
LATE_COMMAND="$LATE_COMMAND; in-target bash -c 'mkdir -p /opt/firstboot_scripts'"

for file in ${VAGRANT}/pxe_files/firstboot_scripts/*
do
  LATE_COMMAND="$LATE_COMMAND; in-target bash -c 'export http_proxy="";curl http://${PROXY}/firstboot_scripts/$(basename $file) -o /opt/firstboot_scripts/$(basename $file)'" 
done

#Now add the order to call them in
LATE_COMMAND="$LATE_COMMAND; in-target bash -c 'chmod +x /opt/firstboot_scripts/*.sh'"
LATE_COMMAND="$LATE_COMMAND; in-target bash -c '/opt/firstboot_scripts/desktop-bootstrap.sh'"

echo "d-i preseed/late_command			string $LATE_COMMAND" >> /tmp/secure-desktop.seed


cp /tmp/secure-desktop.seed /var/www/html/secure-desktop-nvme0.seed
cp /tmp/secure-desktop.seed /var/www/html/secure-desktop-sda.seed
cp /tmp/secure-desktop.seed /var/www/html/secure-desktop-sdb.seed

grep -v 'DISK' /tmp/secure-desktop.seed > /var/www/html/secure-desktop.seed
sed -i 's/DISK/nvme0n1/' /var/www/html/secure-desktop-nvme0.seed
sed -i 's/DISK/sda/' /var/www/html/secure-desktop-sda.seed
sed -i 's/DISK/sdb/' /var/www/html/secure-desktop-sdb.seed

# Copy first boot scripts
cp -rp ${VAGRANT}/pxe_files/firstboot_scripts /var/www/html/

chown -R www-data:www-data /var/www/html

#Configure dnsmasq
cp -f ${VAGRANT}/pxe_files/dnsmasq.conf /etc/

#Setup machine to be the router 
echo "Setup ip forwarding and Masquerading"
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
/sbin/iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
#iptables-save > /etc/iptables/rules.v4

systemctl restart dnsmasq
systemctl restart nginx
systemctl restart apt-cacher-ng

exit 0
