#!/usr/bin/env bash
set -Eeuo pipefail

source env.sh

echo "start to build and install macos"
docker compose up macos-build -d --build --force-recreate

echo "streaming logs..."
docker logs -f macos-build | tee macos-build.log &

echo "waiting for macos-build container to be healthy..."
while [[ "$(docker inspect --format='{{.State.Health.Status}}' macos-build 2>/dev/null)" != "healthy" ]]; do
    sleep 2
done

echo "macos installed, now stop container"
docker stop macos-build

echo "commit all the changes"
docker commit macos-build "$IMAGE_NAME:$IMAGE_VERSION"
docker images

echo "start container with macos installed"
docker compose up macos-installed -d

echo "streaming logs..."
docker logs -f macos-installed | tee macos-installed.log &

echo "waiting for macos-installed container to be healthy..."
while [[ "$(docker inspect --format='{{.State.Health.Status}}' macos-installed 2>/dev/null)" != "healthy" ]]; do
    sleep 2
done

# docker push "$IMAGE_NAME:$IMAGE_VERSION"