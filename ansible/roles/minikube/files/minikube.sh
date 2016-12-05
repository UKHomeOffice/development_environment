#!/bin/bash

set -eux -o pipefail

if [ ! ${USER} == "root" ]
then
  if [ ! $(minikube status) == "Does not Exist" ]
  then
    $(minikube start)
  fi
  DOCKER_API_VERSION={{ docker_api_version }}
  eval $(minikube docker-env)
fi
