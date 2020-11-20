#!/usr/bin/env bash

if [[ ! -d raster-vision-master ]]; then
    curl 'https://github.com/azavea/raster-vision/archive/master.zip' -L -C - -O
    unzip master.zip
fi
