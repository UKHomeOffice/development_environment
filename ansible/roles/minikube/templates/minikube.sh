if [[  ${USER} == "root" ]]
then
  echo "Not running minikube for root"
else
  STATUS=$(minikube status)
  echo "minikube status: ${STATUS}"
  if [[ ${STATUS} == 'Does not Exist' ]]
  then
    echo "Starting minikube"
    minikube start
  else
    echo "Not Starting minikube"
  fi
  DOCKER_API_VERSION={{ docker_api_version }}
  eval $(minikube docker-env)
fi
