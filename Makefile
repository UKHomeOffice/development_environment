
PROXY := "192.168.22.124"

export PROXY

box:
	@PROXY="$(PROXY)" sed "s|PROXY|$(PROXY):3142|g" http/preseed.cfg.orig > http/preseed.cfg
	@packer build -on-error=abort -force ubuntu-16.04.json

test:
	@vagrant box add ubuntu16.04 ./builds/ubuntu-16.04-amd64-virtualbox.box --force
	@PROXY=$(PROXY) AWM=false vagrant up ubuntu_test --provision

awmtest:
	@vagrant box add ubuntu16.04 ./builds/ubuntu-16.04-amd64-virtualbox.box --force
	@PROXY=$(PROXY) AWM=true vagrant up ubuntu_test --provision

pxe:
	@vagrant box add ubuntu16.04 ./builds/ubuntu-16.04-amd64-virtualbox.box --force
	@PROXY=$(PROXY) vagrant up pxe --provision

develop:
	curl https://raw.githubusercontent.com/UKHomeOffice/development_environment/develop/ansible/install.sh | GIT_REF=develop bash

clean:
	@vagrant destroy -f ubuntu_test
	@vagrant destroy -f pxe
	@vagrant box remove ubuntu16.04
	rm -rf packer_cache/*
