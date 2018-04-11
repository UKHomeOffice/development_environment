#!/bin/bash

set -eux -o pipefail

export SQUID_CACHE_DIR=/var/spool/squid
export SQUID_LOG_DIR=/var/log/squid
export SQUID_USER=proxy
export DEBIAN_FRONTEND=noninteractive

apt update -y
apt install -y squid apt-cacher-ng

cp /vagrant/proxy/apt.conf /etc/apt/apt.conf

/bin/systemctl stop squid
cp /etc/squid/squid.conf /etc/squid/squid.conf.orig
cp /vagrant/proxy/squid.conf /etc/squid/squid.conf
/usr/sbin/squid -z
/bin/systemctl enable squid
/bin/systemctl start squid
/bin/systemctl enable apt-cacher-ng
/bin/systemctl start apt-cacher-ng

apt update -y
apt upgrade -y

apt install -y python python-pip

pip install -q -U devpi-server


cp /vagrant/proxy/devpi.service /lib/systemd/system/
/bin/systemctl enable devpi.service
/bin/systemctl start devpi.service

echo "Exposing Ports tcp/3128, tcp/3141, tcp/3142"
