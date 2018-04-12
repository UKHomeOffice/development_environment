#!/bin/bash
set -euxo pipefail

PROXY=${PROXY:-}

if [[ ! -z ${PROXY} ]]
then
  if [[ ${PROXY} == */* ]]
  then
    PROXY=$(echo ${PROXY} | awk -F'/' '{print $1}')
    echo "Proxy is set to: ${PROXY}"
  fi
fi

if [[ -f /etc/os-release ]]
then
  OS=$(cat /etc/os-release|sed -e 's/"//'|grep ID_LIKE|awk -F '=' '{print $2}'|awk '{print $1}')
elif [[ -f /etc/redhat-release ]]
then
  OS=$(cat /etc/redhat-release | awk '{print tolower($1)}')
else
  echo "OS Unknown"
  exit 2
fi

AWM=${AWM:-false}
DESKTOP=${DESKTOP:-true}

echo "Install Desktop: ${DESKTOP}"
echo "Installing AWM: ${AWM}"

function delete_proxy {
unset http_proxy
unset https_proxy
rm -rf /${USER}/.pip

if [[ ${OS} == "debian" ]]
then
    rm -f /etc/apt/apt.conf
    rm -f /etc/apt/apt.conf.d/01_docker_proxy.conf
    rm -f /etc/apt/apt.conf.d/02_packagecloud_proxy.conf
elif [[ ${OS} == "rhel" ]] || [[ ${OS} == "centos" ]]
then
  sed -i -e "/^proxy/d" /etc/yum.conf 
fi
}


delete_proxy

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
    mkdir -p /${USER}/.pip
    echo "[global]\nindex-url = http://${PROXY}:3141/pypi/\n--trusted-host http://${PROXY}:3141\n\n[search]\nindex = http://${PROXY}:3141/pypi" > /${USER}/.pip/pip.conf
  fi
  apt-mark hold linux-image-generic linux-headers-generic
  apt-get -y install python-pip git git-gui libssl-dev libffi-dev
  pip install 'docker-py==1.9.0'
elif [[ ${OS} == "rhel" ]] || [[ ${OS} == "centos" ]]
then
  if [[ ! -z ${PROXY} ]]
  then
    echo "Setting Proxy to: ${PROXY}"
    awk "1; END {print \"proxy=http://${PROXY}:3128\"}" /etc/yum.conf > /etc/yum.conf.tmp && mv /etc/yum.conf.tmp /etc/yum.conf 
    sed -i -e 's/^#baseurl/baseurl/g' -e 's/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/*
    export http_proxy=${PROXY}
  fi
  yum install -y epel-release 
  yum install -y git git-gui python-pip gcc-c++ openssl-devel python-devel libffi-devel
  pip install 'docker-py==1.9.0'
fi

pip install --upgrade pip setuptools ansible

# gpg ssl fudge for docker
mkdir -p /${USER}/.gnupg
chmod 700 /${USER}/.gnupg
touch /${USER}/.gnupg/dirmngr_ldapservers.conf
chmod 600 /${USER}/.gnupg/dirmngr_ldapservers.conf

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
  GIT_REF=${GIT_REF:-$(git tag | tail -n 1)}
  echo "Switching to ref: ${GIT_REF}"
  git reset --hard ${GIT_REF}
  git clean -fxd
  cd ansible
  ansible-galaxy install -r requirements.yml --force
  if [[ ${USB}=1 ]]
  then 
    ansible-playbook -i hostfile -v site.yml -e awesomewm=${AWM} -e os_desktop_enable=${DESKTOP} --skip-tags "usb"
  else
    ansible-playbook -i hostfile -v site.yml -e awesomewm=${AWM} -e os_desktop_enable=${DESKTOP}
  fi
fi

if [[ ${OS} == "debian" ]]
then
  systemctl start apt-daily.service
fi

#Writing the date and version of the ansible run to /etc/issue for easy debugging/ version management later
DATE=`date +"%F %T %Z"`
echo "Ansible Provisioning Date - ${DATE} Git Version - ${GIT_REF}" >> /etc/issue
echo "Writing the Time and Date (${DATE}) as well as the version (${GIT_REF}) to /etc/issue"

delete_proxy

exit 0
