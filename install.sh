#!/bin/bash
set -eux

pip install --upgrade pip setuptools ansible

mkdir -p ~/GIT
cd ~/GIT
git clone https://gitlab.digital.homeoffice.gov.uk/dsab-portpilot/dsab_dev_environment.git dsab_dev_environment
cd dsab_dev_environment

ansible-playbook -i hostfile -v -K default_playbook.yml

exit
