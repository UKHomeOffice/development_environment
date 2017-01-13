#!/bin/bash
set -euxo pipefail

PROXY=${PROXY:-}

if [[ ! -z ${PROXY} ]]
then
  if [[ ${PROXY} == */* ]]
  then
    PROXY=$(echo ${PROXY} | awk -F'/' '{print $1}')
  fi
fi

OS=$(cat /etc/os-release|sed -e 's/"//'|grep ID_LIKE|awk -F '=' '{print $2}'|awk '{print $1}')
AWM=${AWM:-false}

if [[ ${OS} == "debian" ]]
then
  systemctl stop apt-daily.service
  if [[ ! -z ${PROXY} ]]
  then
    echo "Setting Proxy to: ${PROXY}"
    echo "Acquire::http::Proxy \"http://${PROXY}:3142/\";" > /etc/apt/apt.conf
    echo "Acquire::http::Proxy::apt.dockerproject.org \"DIRECT\";" > /etc/apt/apt.conf.d/01_docker_proxy.conf
    export http_proxy=${PROXY}:3128
    mkdir -p /root/.pip
    echo "[global]\nindex-url = http://${PROXY}:3141/pypi/\n--trusted-host http://${PROXY}:3141\n\n[search]\nindex = http://${PROXY}:3141/pypi" > /root/.pip/pip.conf
  else
    unset http_proxy
    unset https_proxy
    rm -f /etc/apt/apt.conf
    rm -f /etc/apt/apt.conf.d/01_docker_proxy.conf
    rm -rf /root/.pip
  fi
  apt-get -y install python-pip git libssl-dev libffi-dev
  pip install 'docker-py==1.9.0'
fi

if [[ ${OS} == "rhel" ]]
then
  if [[ ! -z ${PROXY} ]]
  then
    echo "Setting Proxy to: ${PROXY}"
    export http_proxy=${PROXY}
  else
    unset http_proxy
    unset https_proxy
  fi
  yum install -y epel-release 
  yum install -y git python-pip gcc-c++ openssl-devel python-devel
  pip install 'docker-py==1.9.0'
fi

pip install --upgrade pip setuptools ansible

if [[ -d /vagrant ]]
then
  if [ ${PROXY} ]
  then
    echo "Acquire::http::Proxy \"http://${PROXY}:3142/\";" > /etc/apt/apt.conf
    echo "Acquire::http::Proxy::apt.dockerproject.org \"DIRECT\";" > /etc/apt/apt.conf.d/01_docker_proxy.conf
    export http_proxy=${PROXY}:3128
    mkdir -p /root/.pip
    echo "[global]\nindex-url = http://${PROXY}:3141/pypi/\n--trusted-host http://${PROXY}:3141\n\n[search]\nindex = http://${PROXY}:3141/pypi" > /root/.pip/pip.conf
  else
    unset http_proxy
    unset https_proxy
    rm -f /etc/apt/apt.conf
    rm -f /etc/apt/apt.conf.d/01_docker_proxy.conf
  fi
  cd /vagrant/ansible
  ansible-galaxy install -vv -r requirements.yml --force
  PYTHONUNBUFFERED=1 ansible-playbook -i hostfile -v site.yml -e awesomewm=${AWM}
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
  git reset --hard HEAD
  TAG=${TAG:-$(git tag | tail -n 1)}
  echo "Running with Tag: ${TAG}"
  git checkout ${TAG}
  cd ansible
  ansible-galaxy install -r requirements.yml --force
  ansible-playbook -i hostfile -v site.yml -e awesomewm=${AWM}
fi

if [[ ${OS} == "debian" ]]
then
  systemctl start apt-daily.service
fi

exit 0
