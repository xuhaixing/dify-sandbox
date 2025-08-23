#!bin/bash

# 启动指令示例：
# sh docker/start-dify-sandbox.sh 160  1.4.1 arm64

env=$1
version=$2
archive=$3

if [ -z "$env" ] || [ -z "$version" ]; then
  echo "Usage: $0 <env> <version>"
  exit 1
fi


docker stop dify-sandbox
docker rm dify-sandbox
docker rmi $(docker images | grep "dify-sandbox" | awk '{print $3}')

dockerfile_path="docker/$archive/dify-sandbox.Dockerfile"


# docker build -f $dockerfile_path --progress=plain --build-arg APP_ENV=$env -t xuhaixing/dify-sandbox:$version .
docker build -f $dockerfile_path --progress=plain --build-arg APP_ENV=$env -t xuhaixing/dify-sandbox:$version .


echo "Starting new dify-sandbox container..."
docker run -d --name dify-sandbox -p 18194:8194 xuhaixing/dify-sandbox:$version

echo "Done. Containers are up and running."