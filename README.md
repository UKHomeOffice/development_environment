# Generic Secure Development Environment

These ansible scripts are free to use and follow where possible best practice guidence from the security community. Please feel free to fork this repository for your own needs and also submit pull requests to enhance or harden where approptiate.

All modules included here should work as a minimum under xfce4 with either an Ubuntu or RedHat/CentOS base image. For Ubuntu the compatability checks start at 16.04 where as for RedHat/CentOS it also supports 6.7 along with 7 and above however, continuing support for 6.7 is not required so long as the module checks to only install on OS's of a higher version.


## Bits on the list to add

* blackbox - Stackexchange
* DNSMasq
* aide - filesystem monitoring

?? how to require a password for debian single user mode and disable interactive boot mode


## Usage

### Setting up build environment

To create an environment that new computers can be PXE booted from a PXE boot server and a proxy server (to speed up subsequent builds) are required. These are started as follows:

```
make proxycache
make pxe
```

Be aware that once the PXE server is up, it runs a DHCP service that may well assign your bridged interface an IP address and default route that it then tries (and fails) to use to connect to the internet. This will cause the builds to fail. To resolve this issue, either set the interface to only be used for IP address within its range or hard set the interface to use the IP address that it has been assigned, but delete the IP of the default gateway.

### Destroying the build environment

To destroy the build environment run the following:

```
make pxeclean
make proxyclean
```

### Running the build

Once the build environment is set up, simply boot your target computer, ensuring the BIOS is set to boot from the network. It should see the DHCP/PXE server and start its build process.

The only manual intervention is to select the build to use (go with the default) and to confirm the hostname (go with the default - it gets changed later anyway).

Once the OS installation is complete, you will be prompted to set up an initial user. NOTE: the user that you create at this stage is the admin user (the only one that can use sudo and su), this is not the user that you should use on a day-to-day basis.

### Adding further users

As the admin user, you can create further standard users with the `useradd` command. Further disk encryption passwords can be set up as follows:

`cryptsetup luksAddKey /dev/xxxx`

Where `/dev/xxxx` is the encrypted partition for your system.

### Completing the build

Once the initial configuration is complete, run one of the following as root (via sudo) to harden the server and add further packages:

#### Production

To bootstrap this job please run:

```
curl https://raw.githubusercontent.com/UKHomeOffice/development_environment/master/ansible/install.sh | bash
```

#### Development

This will install the latest tagged release, if you are developing and need a development version (not to be used on live machines but within Vagrant or test boxes) then you can run the following to pull and built the lastest development release:

```
export GIT_REF=develop
curl https://raw.githubusercontent.com/UKHomeOffice/development_environment/${GIT_REF}/ansible/install.sh | bash
```

If you also want to install awesome-wm then run the following (this method is subject to change if/when further DevOps-specific tools are added):

```
export GIT_REF=develop
curl https://raw.githubusercontent.com/UKHomeOffice/development_environment/${GIT_REF}/ansible/install.sh | AWM=true bash
```
