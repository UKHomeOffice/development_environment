# Generic Secure Development Environment

These ansible scripts are free to use and follow where possible best practice guidence from the security community. Please feel free to fork this repository for your own needs and also submit pull requests to enhance or harden where approptiate.

All modules included here should work as a minimum under xfce4 with either an Ubuntu or RedHat/CentOS base image. For Ubuntu the compatability checks start at 16.04 where as for RedHat/CentOS it also supports 6.7 along with 7 and above however, continuing support for 6.7 is not required so long as the module checks to only install on OS's of a higher version.


## Bits on the list to add

* Grub Cmdline hardening Tweaks - needs ubuntu adding to upstream role
* blackbox - Stackexchange
* JDK
* Jenkins
* Jmeter
* DNSMasq 
* Google Chrome
* ntp
* packer / vagrant
* aide - filesystem monitoring

?? how to require a password for debian single user mode and disable interactive boot mode


## Usage

### Production

To bootstrap this job please run:

```
curl https://raw.githubusercontent.com/KEAOSolutions/development_environment/master/install.sh | bash
```

### Development

This will install the latest tagged release, if you are developing and need a development version (not to be used on live machines but within Vagrant or test boxes) then you can run the following to pull and built the lastest development release:

```
curl https://raw.githubusercontent.com/KEAOSolutions/development_environment/develop/install.sh | TAG=develop bash
```
