#!/bin/bash
set -eux

pip install --upgrade pip setuptools ansible

mkdir -p ~/GIT
cd ~/GIT
git clone https://github.com/KEAOSolutions/development_environment.git
cd dsab_dev_environment
git checkout develop
ansible-galaxy install -r requirements.yml

ansible-playbook -i hostfile -v -K site.yml

exit
