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
DESKTOP=${DESKTOP:-true}

echo "Install Desktop: ${DESKTOP}"
echo "Installing AWM: ${AWM}"

if [[ ${OS} == "debian" ]]
then
  systemctl stop apt-daily.service
  if [[ ! -z ${PROXY} ]]
  then
    echo "Setting Proxy to: ${PROXY}"
    echo "Acquire::http::Proxy \"http://${PROXY}:3142/\";" > /etc/apt/apt.conf
    echo "Acquire::http::Proxy::apt.dockerproject.org \"DIRECT\";" > /etc/apt/apt.conf.d/01_docker_proxy.conf
    echo "Acquire::http::Proxy::packagecloud.io \"DIRECT\";" > /etc/apt/apt.conf.d/02_packagecloud_proxy.conf
    export http_proxy=${PROXY}:3128
    mkdir -p /root/.pip
    echo "[global]\nindex-url = http://${PROXY}:3141/pypi/\n--trusted-host http://${PROXY}:3141\n\n[search]\nindex = http://${PROXY}:3141/pypi" > /root/.pip/pip.conf
  else
    unset http_proxy
    unset https_proxy
    rm -f /etc/apt/apt.conf
    rm -f /etc/apt/apt.conf.d/01_docker_proxy.conf
    rm -f /etc/apt/apt.conf.d/02_packagecloud_proxy.conf
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
    sed -i -n -e "/^proxy/!p" -e "aproxy=http://${PROXY}:3128" /etc/yum.conf
    sed -i -e 's/^#baseurl/baseurl/g' -e 's/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/*
    export http_proxy=${PROXY}
  else
    sed -n -e "/proxy/!p" > /etc/yum.conf
    unset http_proxy
    unset https_proxy
  fi
  yum install -y epel-release 
  yum install -y git python-pip gcc-c++ openssl-devel python-devel
  pip install 'docker-py==1.9.0'
fi

pip install --upgrade pip setuptools ansible

# gpg ssl fudge for docker
mkdir -p /root/.gnupg
chmod 700 /root/.gnupg
touch /root/.gnupg/dirmngr_ldapservers.conf
chmod 600 /root/.gnupg/dirmngr_ldapservers.conf

if [[ -d /vagrant ]]
then
  cd /vagrant/ansible
  ansible-galaxy install -vv -r requirements.yml --force
  PYTHONUNBUFFERED=1 ansible-playbook -i hostfile -v site.yml -e awesomewm=${AWM} -e os_desktop_enable=${DESKTOP}
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
  git pull --ff-only
  cd ansible
  ansible-galaxy install -r requirements.yml --force
  ansible-playbook -i hostfile -v site.yml -e awesomewm=${AWM} -e os_desktop_enable=${DESKTOP}
fi

if [[ ${OS} == "debian" ]]
then
  systemctl start apt-daily.service
fi

exit 0
