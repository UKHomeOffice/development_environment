#!/bin/bash
set -euxo pipefail

TAG=${TAG:-}

if [ ! -d ansible-devops ]
then
  mkdir ansible-devops
fi

cd ansible-devops

if [ ${TAG} ]
then
  wget https://raw.githubusercontent.com/UKHomeOffice/development_environment/${TAG}/ansible/devops/{hostfile,vars.yml,requirements.yml,site.yml}
else
  # default branch is develop
  wget https://raw.githubusercontent.com/UKHomeOffice/development_environment/develop/ansible/devops/{hostfile,vars.yml,requirements.yml,site.yml}
fi
ansible-galaxy install -r requirements.yml --force
ansible-playbook -i hostfile -v site.yml

cd ..
rm -rf ansible-devops
exit 0
