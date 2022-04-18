#!/usr/bin/env bash

docker build -t openwrt .
docker run -v $(pwd)/openwrt:/home/build/openwrt --user 1000:1000 -it openwrt bash
