#!/bin/bash

set -eux -o pipefail

export SQUID_CACHE_DIR=/var/spool/squid
export SQUID_LOG_DIR=/var/log/squid
export SQUID_USER=proxy
export DEBIAN_FRONTEND=noninteractive

apt update -y
apt upgrade -y

apt install -y squid apt-cacher-ng python python-pip

pip install -q -U devpi-server

cp /vagrant/proxy/squid.conf /etc/squid/squid.conf

/bin/systemctl enable squid
/bin/systemctl start squid
/bin/systemctl enable apt-cacher-ng
/bin/systemctl start apt-cacher-ng

cp /vagrant/proxy/devpi.service /lib/systemd/system/
/bin/systemctl enable devpi.service
/bin/systemctl start devpi.service

echo "Exposing Ports tcp/3128, tcp/3141, tcp/3142"
