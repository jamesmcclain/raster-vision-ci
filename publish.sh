#!/usr/bin/env bash

IMAGE="quay.io/jmcclain/raster-vision-pytorch"

docker login -u="$QUAY_USERNAME" -p="$QUAY_PASSWORD" quay.io

for i in $(docker images | grep ${IMAGE} | sed 's,[[:space:]]\+,:,g' | cut -f2 -d:); do
    docker push ${IMAGE}:$i
done
