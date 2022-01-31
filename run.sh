#!/usr/bin/env bash

docker build -t openwrt .
docker run -v $(pwd)/openwrt:/opt/openwrt -it openwrt bash
