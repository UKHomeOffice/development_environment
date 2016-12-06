#!/bin/bash


if [ ${USER} -ne "root" ]
then
  if [ $(minikube status) -ne "Does not Exist" ]
  then
    $(minikube start)
  fi
  DOCKER_API_VERSION={{ docker_api_version }}
  eval $(minikube docker-env)
fi
