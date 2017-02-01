#!/bin/bash

set -e

# See http://askubuntu.com/questions/409607/how-to-create-a-customized-ubuntu-server-iso

export WORK="/opt/cd_image_build"
export SEED="${SEED:-/vagrant/}"
export SOURCE=xenial-server-amd64.iso
export TARGET=$(echo "$SOURCE" | sed -e 's/server-/custom-/')

if [ ! -f ${SOURCE} ]; then
  echo missing ${SOURCE}
  curl -L# http://cdimage.ubuntu.com/ubuntu-server/xenial/daily/current/xenial-server-amd64.iso -o xenial-server-amd64.iso
fi
echo WORK=${WORK}
echo SOURCE=${SOURCE}
echo TARGET=${TARGET}

# remove old custom iso
rm -f $TARGET

# install pre-requisites
if [ `cat /etc/lsb*| egrep 'RELEASE' | awk -F '=' '{print $2}'` == "16.04" ]
then 
  apt-get install -y syslinux genisoimage xorriso syslinux-utils
fi
if [ `cat /etc/lsb*| egrep 'RELEASE' | awk -F '=' '{print $2}'` == "14.04" ]
then 
  apt-get install -y syslinux genisoimage xorriso syslinux
fi

# unmount iso if needed
if [ -d ${WORK}/iso ]; then sudo umount ${WORK}/iso || true ; fi
rm -fr ${WORK}/iso ${WORK}/newIso
mkdir -p ${WORK}/iso

# mount source image and copy contents
mount -o ro,loop ${SOURCE} ${WORK}/iso/
rsync -a ${WORK}/iso/ ${WORK}/newIso
umount ${WORK}/iso
rmdir ${WORK}/iso

# new preseed file
cp ${SEED}files/secure-desktop.seed /tmp/iso.seed
echo "d-i preseed/late_command string \\" >> /tmp/iso.seed
echo "in-target bash -c 'mkdir -p /opt/firstboot_scripts; cp /media/cdrom/firstboot_scripts/* /opt/firstboot_scripts/; chmod +x /opt/firstboot_scripts/*.sh; /opt/firstboot_scripts/desktop-bootstrap.sh'" >> /tmp/iso.seed

grep -v 'DISK' /tmp/iso.seed > ${WORK}/newIso/preseed/secure-desktop.seed
cp /tmp/iso.seed ${WORK}/newIso/preseed/secure-desktop-nvme0.seed
sed -i 's/DISK/nvme0n1/' ${WORK}/newIso/preseed/secure-desktop-nvme0.seed
cp /tmp/iso.seed ${WORK}/newIso/preseed/secure-desktop-sda.seed
sed -i 's/DISK/sda/' ${WORK}/newIso/preseed/secure-desktop-sda.seed
cp /tmp/iso.seed ${WORK}/newIso/preseed/secure-desktop-sdb.seed
sed -i 's/DISK/sdb/' ${WORK}/newIso/preseed/secure-desktop-sdb.seed
cp ${SEED}files/txt.cfg ${WORK}/newIso/isolinux/txt.cfg
cp ${SEED}files/grub.cfg ${WORK}/newIso/boot/grub.cfg
echo en | sudo dd of=${WORK}/newIso/isolinux/lang
mkdir -p ${WORK}/newIso/firstboot_scripts
cp -rp ${SEED}files/firstboot_scripts ${WORK}/newIso/

# re-generate md5sum
# The find will warn 'File system loop detected' and return non-zero exit status on the 'ubuntu' symlink to '.'
# To avoid that, temporarily move it out of the way
mv ${WORK}/newIso/ubuntu ${WORK}/ubuntu
(cd ${WORK}/newIso; find '!' -name "md5sum.txt" '!' -path "./isolinux/*" -follow -type f -exec `which md5sum` {} \; > ${WORK}/md5sum.txt)
mv ${WORK}/md5sum.txt ${WORK}/newIso/
mv ${WORK}/ubuntu ${WORK}/newIso

# build ISO image
mkisofs -r -V "Custom Ubuntu Install CD" \
  -cache-inodes \
  -J -l -b isolinux/isolinux.bin \
  -c isolinux/boot.cat -no-emul-boot \
  -boot-load-size 4 -boot-info-table \
  -o ${SEED}/$TARGET ${WORK}/newIso/
ls -l ${SEED}/$TARGET
chown $USER:$USER ${SEED}/$TARGET
isohybrid ${SEED}/$TARGET

#sleep 300
rm -fr ${WORK}/newIso

echo created $TARGET
