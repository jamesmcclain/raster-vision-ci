#!/usr/bin/env bash

if [[ ! -d raster-vision-master ]]; then
    rm -f master.zip
    curl 'https://github.com/azavea/raster-vision/archive/master.zip' -L -C - -O
    unzip master.zip
fi

cd raster-vision-master/

IMAGE="quay.io/jmcclain/raster-vision-pytorch"
CUDA_VERSION="10.0"

# Discover critical lines
RUN_PIP=$(cat Dockerfile | grep -n '^RUN pip' | tail -1 | cut -f1 -d:)
WORKDIR=$(cat Dockerfile | grep -n '^WORKDIR /opt/src' | tail -1 | cut -f1 -d:)

# Produce Dockerfile.base
cat Dockerfile | head -n ${WORKDIR} | tail -n +2 | sed "s,\${CUDA_VERSION},${CUDA_VERSION}," > Dockerfile.base
BASE_HASH=$(cat Dockerfile.base | md5sum | cut -f1 -d' ')
BASE_IMAGE=${IMAGE}:${BASE_HASH}

# Produce Dockerfile.python
echo "FROM ${BASE_IMAGE}" > Dockerfile.python
cat Dockerfile | tail -n +$(expr ${WORKDIR} + 1) >> Dockerfile.python
PYTHON_HASH=$(cat Dockerfile.python $(find | grep 'requirements[a-z]*\.txt') | md5sum | cut -f1 -d' ')
PYTHON_IMAGE=${IMAGE}:${PYTHON_HASH}

# Produce Dockerfile.rv
echo "FROM ${PYTHON_IMAGE}" > Dockerfile.rv
cat Dockerfile | tail -n +$(expr ${RUN_PIP} + 1) >> Dockerfile.rv
RV_IMAGE=${IMAGE}:$(date | sed 's, \+,_,g' | sed 's,:,_,g')

# Pull or produce base image
if ! (docker pull ${BASE_IMAGE} || docker images | grep ${BASE_HASH}); then
    docker build -t ${BASE_IMAGE} -f Dockerfile.base .
fi

# Pull or produce python image
if ! (docker pull ${PYTHON_IMAGE} || docker images | grep ${PYTHON_HASH}); then
    docker build -t ${PYTHON_IMAGE} -f Dockerfile.python .
fi

# Produce raster-vision image
docker build -t ${RV_IMAGE} -f Dockerfile.rv .
docker tag ${RV_IMAGE} ${IMAGE}:latest
