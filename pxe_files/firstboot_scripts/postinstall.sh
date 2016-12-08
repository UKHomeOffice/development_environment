#!/bin/bash

set -eux -o pipefail

if [[ $UID -ne 0 ]]; then
  echo "This script needs to be run as root (with sudo)"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

#Make sure machine starts with splash
sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT=\).*/\1\"splash quiet\"/g' /etc/default/grub; \
 bash -c 'update-grub'; \

#Prevent standard user executing su
dpkg-statoverride --update --force --add root adm 4750 /bin/su

# Configure a basic IPv4 firewall
echo "*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p tcp -m tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT
-A OUTPUT -o lo -j ACCEPT
COMMIT" > /etc/iptables/rules.v4

# Configure a basic IPv6 firewall
echo "*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 134 -j ACCEPT
-A INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 135 -j ACCEPT
-A INPUT -p ipv6-icmp -m icmp6 --icmpv6-type 136 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT
-A OUTPUT -o lo -j ACCEPT
COMMIT" > /etc/iptables/rules.v6

# Load the above rule sets
#service iptables-persistent start

# Set some AppArmor profiles to enforce mode
aa-enforce /etc/apparmor.d/usr.bin.firefox
aa-enforce /etc/apparmor.d/usr.sbin.avahi-daemon
aa-enforce /etc/apparmor.d/usr.sbin.dnsmasq
aa-enforce /etc/apparmor.d/bin.ping
aa-enforce /etc/apparmor.d/usr.sbin.rsyslogd

# Turn off privacy-leaking aspects of Unity
if [ ! -d /etc/dconf/profile ]; then
 mkdir -p /etc/dconf/profile
fi
echo "user-db:user" > /etc/dconf/profile/user
echo "system-db:local" >> /etc/dconf/profile/user

mkdir -p /etc/dconf/db/local.d

echo "[com/canonical/unity/lenses]" > /etc/dconf/db/local.d/unity
echo "remote-content-search=false" >> /etc/dconf/db/local.d/unity

mkdir -p /etc/dconf/db/local.d/locks

echo "/com/canonical/unity/lenses/remote-content-search" > /etc/dconf/db/local.d/locks/unity

dconf update

#Make sure auto-updates is enabled
  # Enable automatic updates
  echo "APT::Periodic::Update-Package-Lists \"1\";
APT::Periodic::Unattended-Upgrade \"1\";
APT::Periodic::AutocleanInterval \"7\";" >> /etc/apt/apt.conf.d/20auto-upgrades

# Disable apport (error reporting)
sed -ie '/^enabled=1$/ s/1/0/' /etc/default/apport

# Protect user home directories
sed -ie '/^DIR_MODE=/ s/=[0-9]*\+/=0750/' /etc/adduser.conf
sed -ie '/^UMASK\s\+/ s/022/027/' /etc/login.defs

# Disable shell access for new users (not affecting the existing admin user)
sed -ie '/^SHELL=/ s/=.*\+/=\/usr\/sbin\/nologin/' /etc/default/useradd
sed -ie '/^DSHELL=/ s/=.*\+/=\/usr\/sbin\/nologin/' /etc/adduser.conf

# Disable guest login
mkdir -p /etc/lightdm/lightdm.conf.d
echo "[SeatDefaults]
allow-guest=false
" > /etc/lightdm/lightdm.conf.d/50-no-guest.conf

# A hook to disable online scopes in dash on login
cat <<EOF > /usr/local/bin/unity-privacy-hook.sh
#!/bin/bash
gsettings set com.canonical.Unity.Lenses disabled-scopes "['more_suggestions-amazon.scope', 'more_suggestions-u1ms.scope', 'more_suggestions-populartracks.scope', 'music-musicstore.scope', 'more_suggestions-ebay.scope', 'more_suggestions-ubuntushop.scope', 'more_suggestions-skimlinks.scope']"
for USER in \`ls -1 /home\`; do
  if [ ! i\${USER} == "lost+found" ]
  then
    chown -R \${USER}:\${USER} /home/\${USER}
  fi
done
exit 0
EOF
  chmod 755 /usr/local/bin/unity-privacy-hook.sh
  echo "[SeatDefaults]
session-setup-script=/usr/local/bin/unity-privacy-hook.sh" > /etc/lightdm/lightdm.conf.d/20privacy-hook.conf

# Fix some permissions in /var that are writable and executable by the standard user
chmod o-w /var/crash
chmod o-w /var/metrics
chmod o-w /var/tmp

echo -e "\nPOST INSTALLATION COMPLETE"

reboot
