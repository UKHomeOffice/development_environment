# This script configures system for Enduser
# 2013-02-14 / philipp gassmann / gassmann@puzzle.ch

set -x

if [ "$1" != "stage2" ]; then
  ## STAGE 1: Start X Server, xclock and Terminal that will run stage2 of the script

  # kill running xserver
  systemctl stop lightdm

  # start xserver
  xinit $(which metacity) &
  sleep 2
  export DISPLAY=:0
  #This was enabled for debug
  #xterm &
  xclock &

  # set keymap
  setxkbmap gb 

  # we call ourselves again in a terminal for stage2
  /bin/bash /opt/firstboot_scripts/desktop-bootstrap-user.sh 'stage2'
  rm -f /etc/systemd/system/multi-user.target.wants/systemd-firstboot.service
  exit # after exit, lightdm should continue starting.

fi
  ## STAGE 2: Actual User Configuration

  #Disable Output (= don't show passwords)
  set +x

  # Continue? or update and shutdown
  Installdate=`cat /root/install-date`
  . /etc/os-release

  if zenity  --question --title "Info"  --text "Ready for User Setup \n\n$PRETTY_NAME\nInstalled on $Installdate" --cancel-label="Update and Poweroff" --ok-label="Continue"; then
      true
    else
      set -x
      apt-get update
      apt-get dist-upgrade -y
      sleep 5
      shutdown -h 0
  fi

    ## Detect all encrypted partitions ##
    crypt_devices=""
    crypt_luksdrives=`mktemp crypt_luksdrives.XXXX`
    crypt_lukdevs=`mktemp crypt_lukdevs.XXXX`
    mount | grep luks > $crypt_luksdrives #find mounted luks partitions
    swapoff -va | grep luks >> $crypt_luksdrives; swapon -a #get encrypted swap
    lvmdiskscan | grep luks >> $crypt_luksdrives # get encrypted physical partitions of lvm

    sed -n -e 's/.*\(luks-[-a-z0-9]*\).*/\1/p' $crypt_luksdrives | tee $crypt_lukdevs # get luks-9cfg-acme-... part

    # Ubuntu crypttab:
    # example:# sda5_crypt UUID=b8783528-c231-420f-a03e-a6b6e00508ba none luks
    cut -d" " -f 1 /etc/crypttab >> $crypt_lukdevs

    # get device (e.g. /dev/sda2) of luks-partition
    IFS=$'\n'
    for luks in `cat $crypt_lukdevs`; do
        crypt_devices="$crypt_devices `cryptsetup status /dev/mapper/$luks | sed -n -e 's/\ *device:\ *//p'`"
    done
    unset IFS

    #Query admin encrpytion pw but only when crypted partitions are found.
    if [ "$crypt_devices" != "" ]; then
      apwcheck=0
      while [ $apwcheck -ne 1 ]; do
        crypt_adminpw1=`zenity --entry --hide-text --text="Current Disk Encryption Password"`

        crypt_oldpw_file=`mktemp pwfile.XXXX`
        echo -n $crypt_adminpw1 > $crypt_oldpw_file

	      luks_password_test=0
        for dev in $crypt_devices; do
           echo "Test password on $dev"
           cryptsetup luksOpen --test-passphrase $dev --key-file=$crypt_oldpw_file
           luks_password_test=$?
        done

	      rm -f $crypt_oldpw_file

        if [ "$luks_password_test" == "0" ]; then
          apwcheck=1
          crypt_adminpw="$crypt_adminpw1"
        else
          zenity --error --text="Wrong password entered!"
        fi
      done
    fi

  # query username
  firstname=`zenity --entry --text="First Name"`
  lastname=`zenity --entry --text="Last Name"`

  fullname="$firstname $lastname"
  username="`echo $firstname | cut -c 1`$lastname"
  username=`echo $username | tr [A-ZÄÖÜ] [a-zäöü] | sed -e s/ä/ae/g -e s/ö/oe/g -e s/ü/ue/g`

  # query and verify password
  pwcheck=0
  while [ $pwcheck -ne 1 ]; do
    # quality-check
    testquality=0
    while [ $testquality -eq 0 ]; do
      export pw1=`zenity --entry --hide-text --text="User Password"`
      # length check
      if [ "`expr length $pw1`" -ge 14 ]; then
         if `echo $pw1 | cracklib-check | grep -q ": OK"` ; then  # TODO: Improve check. could use pwqcheck
           testquality=1
         else
           crackliberror=`echo $pw1 | cracklib-check | cut -d ":" -f2`
           zenity --error --text="Password too weak \nError:$crackliberror"
         fi
       else
         zenity --error --text="Password too short \nMinimal length: 14 characters"
      fi
    done

    # verify password
    pw2=`zenity --entry --hide-text --text="Repeat User Password"`
    if [ "$pw1" == "$pw2" ]; then
        pwcheck=1
        export password="$pw1"
      else
        zenity --error --text="Passwords don't match"
    fi
  done

  lukspasscheck=0
  while [ $lukspasscheck -ne 1 ]; do
    # quality-check
    testquality=0
    while [ $testquality -eq 0 ]; do
      export pw1=`zenity --entry --hide-text --text="New Disk Encryption Password"`
      # length check
      if [ "`expr length $pw1`" -ge 14 ]; then
         if `echo $pw1 | cracklib-check | grep -q ": OK"` ; then  # TODO: Improve check. could use pwqcheck
           testquality=1
         else
           crackliberror=`echo $pw1 | cracklib-check | cut -d ":" -f2`
           zenity --error --text="Password too weak \nError:$crackliberror"
         fi
       else
         zenity --error --text="Password too short \nMinimal length: 14 characters"
      fi
    done

    # verify password
    pw2=`zenity --entry --hide-text --text="Repeat Disk Encryption Password"`
    if [ "$pw1" == "$pw2" ]; then
        lukspasscheck=1
        export lukspassword="$pw1"
      else
        zenity --error --text="Passwords don't match"
    fi
  done

###### GENERAL SYSTEM SETTINGS ######

#config hostname
  echo 'Set hostname'
  old_hostname=`hostname`
  old_domainname=`domainname`
  new_hostname="$username-workstation"
  new_domainname=`zenity --entry --text="Domain Name"`

  # change hostname in specific files
  sed -i "s/$old_hostname/$new_hostname/" /etc/ssh/ssh*key.pub
  sed -i "s/$old_hostname/$new_hostname/g" /etc/hosts
  sed -i "s/local.lan/$new_domainname/g" /etc/hosts
  sed -i "s/$old_domainname/$new_domainname/g" /etc/hosts
  echo "$new_hostname.$new_domainname" > /etc/hostname
  echo "127.0.1.1    $new_hostname.$new_domainname" >> /etc/hosts

  #change hostname for this session.
  hostname $new_hostname.$new_domainname

  # change and add password for found partitions
  echo 'Add user password to disk-encryption passwords'
  crypt_userpw=$lukspassword
  crypt_oldpw_file=`mktemp pwfile.XXXX`
  echo -n $crypt_adminpw > $crypt_oldpw_file
  for dev in $crypt_devices; do
      echo "Set password on $dev"
      echo -n $crypt_userpw | cryptsetup luksAddKey $dev --key-file=$crypt_oldpw_file
      adding_user_key=$?
      if [ "$adding_user_key" == "0" ]
      then
          echo -n $crypt_adminpw | cryptsetup luksRemoveKey $dev --key-file=$crypt_oldpw_file
      else
          zenity --info --text="Error adding users password to disk encryption"
	  exit 1
      fi
  done

  # cleanup
  rm -f $crypt_luksdrives
  rm -f $crypt_oldpw_file

  # Create User
  echo 'Configure user account'

  grep -q $username /etc/passwd || {
    useradd $username -c "$fullname" -s /bin/bash -m -G lp,cdrom,audio,video,netdev,adm,lpadmin,sudo
    echo "$username:$password"|chpasswd
  }

#Remove tempuser
userdel tempuser
rm -rf /home/tempuser

#chown home to user
  chown -R $username /home/$username/

# Install VirtualEnv Python dev and setup ansible
#su - $username -c "virtualenv python_dev; source python_dev/bin/activate; pip install ansible"

###### CLEAN UP #####

# finish stage2
  zenity --info --text="User Setup finished, disk encryption password changed as well\nNew Username is: ${username}"

# stage 2 finished
