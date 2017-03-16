#!/bin/bash

set -euxv -o pipefail

export VAGRANT="/vagrant"


PROXY=${PROXY:-}
PXE=${PXE:-}

if [[ ! -z ${PROXY} ]]
then
  if [[ ${PROXY} == */* ]]
  then
    PROXY=$(echo ${PROXY} | awk -F'/' '{print $1}')
    echo "Proxy Server is set to: ${PROXY}"
  else
    echo "Proxy Server is set to: ${PROXY}"
  fi
else
  echo "Proxy Server is not set"
  exit 2
fi

if [[ ! -z ${PXE} ]]
then
  echo "PXE Server is set to: ${PXE}"
else
  echo "PXE Server is not set"
  exit 2
fi

if [[ -f /etc/os-release ]]
then
  OS=$(cat /etc/os-release|sed -e 's/"//'|grep ID_LIKE|awk -F '=' '{print $2}'|awk '{print $1}')
elif [[ -f /etc/redhat-release ]]
then
  OS=$(cat /etc/redhat-release | awk '{print tolower($1)}')
else
  echo "OS Unknown"
  exit 2
fi

if [[ ${OS} == "debian" ]]
then
  systemctl stop apt-daily.service
  if [[ ! -z ${PROXY} ]]
  then
    echo "Setting Proxy to: ${PROXY}"
    echo "Acquire::http::Proxy \"http://${PROXY}:3142/\";" > /etc/apt/apt.conf
    echo "Acquire::http::Proxy::apt.dockerproject.org \"DIRECT\";" > /etc/apt/apt.conf.d/01_docker_proxy.conf
    echo "Acquire::http::Proxy::packagecloud.io \"DIRECT\";" > /etc/apt/apt.conf.d/02_packagecloud_proxy.conf
    export http_proxy=${PROXY}:3128
    mkdir -p /root/.pip
    echo "[global]\nindex-url = http://${PROXY}:3141/pypi/\n--trusted-host http://${PROXY}:3141\n\n[search]\nindex = http://${PROXY}:
3141/pypi" > /root/.pip/pip.conf
  else
    unset http_proxy
    unset https_proxy
    rm -f /etc/apt/apt.conf
    rm -f /etc/apt/apt.conf.d/01_docker_proxy.conf
    rm -f /etc/apt/apt.conf.d/02_packagecloud_proxy.conf
    rm -rf /root/.pip
  fi
  apt update
  echo "Installing packages for pxe server"
  echo "grub-pc hold" |sudo dpkg --set-selections
  echo "grub-legacy-ec2 hold" |sudo dpkg --set-selections
  apt-get -fy install python-pip git libssl-dev libffi-dev
  apt-get -fy install dnsmasq nginx
  dpkg -s iptables-persistent &
  if [[ $? > 0 ]]
  then
    apt-get -fy install iptables-persistent
  fi
  apt-get upgrade -y
fi

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

LATE_COMMAND="echo 'Processing scripts'" 
LATE_COMMAND="$LATE_COMMAND; in-target bash -c 'mkdir -p /opt/firstboot_scripts'"

for file in ${VAGRANT}/pxe_files/firstboot_scripts/*
do
  LATE_COMMAND="$LATE_COMMAND; in-target bash -c 'export http_proxy="";curl http://${PXE}/firstboot_scripts/$(basename $file) -o /opt/firstboot_scripts/$(basename $file)'" 
done

#Now add the order to call them in
LATE_COMMAND="$LATE_COMMAND; in-target bash -c 'chmod +x /opt/firstboot_scripts/*.sh'"
LATE_COMMAND="$LATE_COMMAND; in-target bash -c '/opt/firstboot_scripts/desktop-bootstrap.sh'"

#Modify swap file size
LATE_COMMAND="$LATE_COMMAND; in-target bash -c 'swapoff /dev/vg-workstation/swap'"
LATE_COMMAND="$LATE_COMMAND; in-target bash -c 'lvremove -y /dev/vg-workstation/swap'"
LATE_COMMAND="$LATE_COMMAND; in-target bash -c 'lvcreate -L 4G -n swap vg-workstation'"
LATE_COMMAND="$LATE_COMMAND; in-target bash -c 'dd if=/dev/zero of=/dev/vg-workstation/swap bs=1M count=4096'"
LATE_COMMAND="$LATE_COMMAND; in-target bash -c 'mkswap /dev/vg-workstation/swap'"
LATE_COMMAND="$LATE_COMMAND; in-target bash -c 'swapon /dev/vg-workstation/swap'"

echo "d-i preseed/late_command			string $LATE_COMMAND" >> /tmp/secure-desktop.seed

sed -i "s/PROXY/${PROXY}/" /tmp/secure-desktop.seed
cp /tmp/secure-desktop.seed /var/www/html/secure-desktop-nvme0.seed
cp /tmp/secure-desktop.seed /var/www/html/secure-desktop-sda.seed

grep -v 'DISK' /tmp/secure-desktop.seed > /var/www/html/secure-desktop.seed
sed -i 's/DISK/nvme0n1/' /var/www/html/secure-desktop-nvme0.seed
sed -i 's/DISK/sda/' /var/www/html/secure-desktop-sda.seed

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

systemctl restart dnsmasq
systemctl restart nginx

exit 0
