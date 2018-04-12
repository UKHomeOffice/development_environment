```UPDATE TO LATEST VERSIONS OF VBOX AND VAGRANT!
https://www.vagrantup.com/downloads.html
apt-get install virtualbox-5.2
```


# Generic Secure Development Environment

These ansible scripts are free to use and follow where possible best practice guidence from the security community. Please feel free to fork this repository for your own needs and also submit pull requests to enhance or harden where approptiate.

All modules included here should work as a minimum under xfce4 with either an Ubuntu or RedHat/CentOS base image. For Ubuntu the compatability checks start at 16.04 where as for RedHat/CentOS it also supports 6.7 along with 7 and above however, continuing support for 6.7 is not required so long as the module checks to only install on OS's of a higher version.

# FAQ

Some questions answere [here](./FAQ.md)


## Bits on the list to add

* blackbox - Stackexchange
* DNSMasq
* aide - filesystem monitoring

?? how to require a password for debian single user mode and disable interactive boot mode


## Usage

### Setting up build environment

To create an environment that new computers can be PXE booted from a PXE boot server and a proxy server (to speed up subsequent builds) are required. These are started as follows:

```
make proxy
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

#### Vagrantfile

The Vagrantfile has two lines commented out for setting the proxy and pxe public networks which includes the assignment of a network bridge similar to the following:

```
proxy.vm.network "public_network", ip: "ip_value", bridge: networks["network_bridge_value"]
```

These lines have been added to provide the option of running the vagrant up commands of both the pxe and proxy servers to run without human intervention of entering which network bridge to use. These lines are currently commented out to prevent any interference with existing users. However, if uncommented and used instead of the existing vm.network lines, then the network bridge value should be placed into a yaml file similar to the following:

```
network_bridge: 'network_bridge_value'
```

and the Vagrantfile will need to specify the location of the yaml file for it to read:

```
networks = YAML.load_file('location/network.yaml')

```


#### Systemd

The directory systemd of this repo contains systemd unit files for the proxy and pxe servers. The files enable both servers to be started at system boot and halted at system shutdown. If the servers are interrupted unexpectedly, the untis will try to restart the servers. 

Both unit files use the Makefile in this repo to run commands for starting and stopping the VM servers. An SSH command is also used to provide a continuous way of keeping each VM up and running after they have been successfully provisioned. This is needed because once the VM has been provisioned, systemd thinks that the process has completed successfully and no longer requires the process to be running and therefore begins to shutdown the VM. The SSH runs a tail command within an empty file on each of the servers in a continuous loop until the server is shutdown. 

If running an ubuntu host machine, these files should be placed into the following location:

```
/etc/systemd/system
```

Once added, the units need to be started with the following commands:

``` 
systemctl enable proxy-vbox-vm.service

systemctl enable pxe-vbox-vm.service
``` 

To check whether the units are running, run the following commands:

```
systemctl status proxy-vbox-vm.service

systemctl status pxe-vbox-vm.service
```

If you make changes to the unit files, then a daemon re-load is required to reload the systemd manager configuration and recreate the dependency tree;

```
systemctl daemon-reload

systemctl restart name_of_unit_service_changed
```



