#!/bin/bash
set -eux

OS=$(cat /etc/os-release|sed -e 's/"//'|grep ID_LIKE|awk -F '=' '{print $2}'|awk '{print $1}')

if [ ${OS} == "debian" ]
then
  apt-get -y install python-pip git libssl-dev
fi

if [ ${OS} == "rhel" ]
then
  yum install -y epel-release 
  yum install -y git python-pip gcc-c++ openssl-devel python-devel
fi

pip install --upgrade pip setuptools ansible

mkdir -p ~/GIT
cd ~/GIT

if [ ! -d development_environment ]
then
  git clone https://github.com/KEAOSolutions/development_environment.git development_environment
fi

cd development_environment
git clean -fxd
git reset --hard
git checkout develop
git pull
ansible-galaxy install -r requirements.yml

#ansible-playbook -i hostfile -v site.yml

#exit
