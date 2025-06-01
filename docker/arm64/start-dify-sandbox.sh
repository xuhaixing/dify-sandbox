#!bin/bash

# 启动指令示例：
# sh docker/arm64/start-dify-sandbox.sh 160 1.4.1

env=$1
version=$2

if [ -z "$env" ] || [ -z "$version" ]; then
  echo "Usage: $0 <env> <version>"
  exit 1
fi


docker stop dify-sandbox
docker rm dify-sandbox
docker rmi xuhaixing/dify-sandbox:$version

dockerfile_path="docker/arm64/dify-sandbox.Dockerfile"


docker build -f $dockerfile_path --build-arg APP_ENV=$env -t xuhaixing/dify-sandbox:$version .


echo "Starting new dify-sandbox container..."
docker run -d --name dify-sandbox -p 18194:8194 xuhaixing/dify-sandbox:$version

echo "Done. Containers are up and running."