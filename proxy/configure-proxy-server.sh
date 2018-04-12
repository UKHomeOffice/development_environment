#!/bin/bash

set -eux -o pipefail

export DEBIAN_FRONTEND=noninteractive
export SQUID_USER=proxy
export SQUID_CACHE_DIR=/var/spool/squid
export SQUID_LOG_DIR=/var/log/squid


install_apt_cacher_ng() {
  # Mask service to prevent it from starting - we need to make some owndership changes first.
  ln -s /dev/null /etc/systemd/system/apt-cacher-ng.service

  apt install -y apt-cacher-ng

  # Change ownership of apt-cacher-ng directories and files.
  chown -R proxy:proxy /run/apt-cacher-ng
  chown -R proxy:proxy /var/cache/apt-cacher-ng
  chown -R proxy:proxy /var/log/apt-cacher-ng
  chgrp proxy /etc/apt-cacher-ng/security.conf

  # Replace package service file with updated version - that runs as user "proxy"
  cp /vagrant/proxy/apt-cacher-ng.service /lib/systemd/system/apt-cacher-ng.service

  systemctl daemon-reload

  # Remove the service mask so that we can start the service.
  rm /etc/systemd/system/apt-cacher-ng.service

  # Enable and start the service
  /bin/systemctl enable apt-cacher-ng
  /bin/systemctl restart apt-cacher-ng
}


instal_squid() {
  # Mask service to prevent it from starting - we need to make some owndership changes first.
  ln -s /dev/null /etc/systemd/system/squid.service

  apt install -y squid

  # Update the distribution configuration - keeping a backup for reference.
  cp /etc/squid/squid.conf /etc/squid/squid.conf.orig
  cp /vagrant/proxy/squid.conf /etc/squid/squid.conf

  # Create the cache directory hierarchy - just in case it doesn't exist yet.
  /usr/sbin/squid -z

  # Remove the service mask so that we can start the service.
  rm /etc/systemd/system/squid.service

  # Enable and start the service
  /bin/systemctl enable squid
  /bin/systemctl restart squid
}


main() {
  apt update -y
  install_apt_cacher_ng

  # Enable apt to use the apt-cacher-ng proxy
  cp /vagrant/proxy/apt-conf-d-01proxy /etc/apt/apt.conf.d/01proxy

  apt update -y
  instal_squid

  apt install -y python python-pip

  apt upgrade -y

  pip install -q -U devpi-server

  cp /vagrant/proxy/devpi.service /lib/systemd/system/
  /bin/systemctl enable devpi.service
  /bin/systemctl start devpi.service

  echo "Exposed proxy ports"
  echo " - squid:         tcp/3128"
  echo " - devpi-server:  tcp/3141"
  echo " - apt-cacher-ng: tcp/3142"
}


main

