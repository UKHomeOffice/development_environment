# This script configures the system (executed from preseed late_command)
# 2013-02-14 / Philipp Gassmann / gassmann@puzzle.ch

set -x

# Ensure proper logging
if [ "$1" != "stage2" ]; then
  mkdir /root/log
  /bin/bash /opt/firstboot_scripts/desktop-bootstrap.sh 'stage2' &> /root/log/desktop-bootstrap.log
  exit
fi

###### Custom ENVIRONMENT ######
################################

sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT=\).*/\1\"splash quiet\"/g' /etc/default/grub
update-grub

# removed

###### Prepare End User Configuration #####
###########################################

# get desktop-bootstrap file
chmod +x /opt/firstboot_scripts/desktop-bootstrap-user.sh

# Activate firstboot-custom (user setup)
cp /opt/firstboot_scripts/systemd-firstboot.service /etc/systemd/system/multi-user.target.wants/

# Installationsdatum speichern
date +%c > /root/install-date

#Remove the apt-conf
rm -f /etc/apt/apt.conf
