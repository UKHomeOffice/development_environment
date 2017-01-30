
PROXY := "192.168.87.250"
PXE := "192.168.87.254"

export PROXY

removeboxes:
	@vagrant box remove ubuntu16.04
	@vagrant box remove bento/ubuntu-16.04
	@vagrant box remove bento/centos-7.3
	@vagrant box remove bento/centos-6.8

proxycache:
	@vagrant up proxy --provision

box:
	@PROXY="$(PROXY)" sed "s|PROXY|$(PROXY):3142|g" http/preseed.cfg.orig > http/preseed.cfg
	@packer build -on-error=abort -force ubuntu-16.04.json

ubuntutest:
	@vagrant box add ubuntu16.04 ./builds/ubuntu-16.04-amd64-virtualbox.box --force
	@PROXY=$(PROXY) AWM=false DESKTOP=true vagrant up ubuntutest --provision

centos7test:
	#@vagrant box add ubuntu16.04 ./builds/centos-7-amd64-virtualbox.box --force
	@PROXY=$(PROXY) AWM=false DESKTOP=false vagrant up centos7test --provision

centos6test:
	#@vagrant box add ubuntu16.04 ./builds/centos-6-amd64-virtualbox.box --force
	@PROXY=$(PROXY) AWM=false DESKTOP=false vagrant up centos6test --provision

awmtest:
	@vagrant box add ubuntu16.04 ./builds/ubuntu-16.04-amd64-virtualbox.box --force
	@PROXY=$(PROXY) AWM=true DESKTOP=true vagrant up ubuntutest --provision

pxe:
	@PXE=$(PXE) PROXY=$(PROXY) vagrant up pxe --provision

develop:
	curl https://raw.githubusercontent.com/UKHomeOffice/development_environment/develop/ansible/install.sh | GIT_REF=develop bash

ubuntuclean:
	@vagrant destroy -f ubuntutest
	@vagrant destroy -f pxe

centos7clean:
	@vagrant destroy -f centos7test

centos6clean:
	@vagrant destroy -f centos6test

packerclean:
	@rm -rf packer_cache/*

pxeclean:
	@vagrant destroy -f pxe

proxyclean:
	@vagrant destroy -f proxy
