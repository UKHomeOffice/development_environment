#!/bin/bash
set -eux

pip install --upgrade pip setuptools ansible

apt-get install virtualbox-ext-pack
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.7.1/minikube-linux-amd64
chmod +x minikube
sudo mv minikube /usr/local/bin/

curl -L#o kubectl http://storage.googleapis.com/kubernetes-release/release/v1.3.4/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

sudo /bin/su -c "cat << 'EOF' > /etc/profile.d/minikube.sh
eval $(minikube docker-env)
EOF"

source /etc/profile.d/minikube.sh

docker pull quay.io/ukhomeofficedigital/kb8or
docker pull quay.io/ukhomeofficedigital/toolbox:v0.0.1
