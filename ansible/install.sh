#!/bin/bash
set -x

PROXY=${PROXY:-}
OS=$(cat /etc/os-release|sed -e 's/"//'|grep ID_LIKE|awk -F '=' '{print $2}'|awk '{print $1}')

if [ ${OS} == "debian" ]
then
  apt-get -y install python-pip git libssl-dev libffi-dev
  pip install 'docker-py==1.9.0'
fi

if [ ${OS} == "rhel" ]
then
  yum install -y epel-release 
  yum install -y git python-pip gcc-c++ openssl-devel python-devel
  pip install 'docker-py==1.9.0'
fi

pip install --upgrade pip setuptools ansible

if [ -d /vagrant ]
then
  if [ ${PROXY} ]
  then
    echo "Acquire::http::Proxy \"http://${PROXY}/\";" > /etc/apt/apt.conf
    echo "Acquire::http::Proxy::apt.dockerproject.org \"DIRECT\";" > /etc/apt/apt.conf.d/01_docker_proxy.conf
  fi
  cd /vagrant/ansible
  ansible-galaxy install -vv -r requirements.yml --force
  PYTHONUNBUFFERED=1 ansible-playbook -i hostfile -v site.yml
else
  mkdir -p /opt/GIT
  cd /opt/GIT
  if [ ! -d development_environment ]
  then
    git clone https://github.com/UKHomeOffice/development_environment.git development_environment
  fi
  cd development_environment
  git fetch
  git clean -fxd
  git reset --hard
  TAG=${TAG:-$(git tag | tail -n 1)}
  echo "Running with Tag: ${TAG}"
  git checkout ${TAG}
  ansible-galaxy install -r requirements.yml --force
  ansible-playbook -i hostfile -v site.yml
fi

exit 0
