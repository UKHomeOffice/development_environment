#!/bin/bash
set -eux

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
git checkout v0.0.1
ansible-galaxy install -r requirements.yml

ansible-playbook -i hostfile -v site.yml

exit
