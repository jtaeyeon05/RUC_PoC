#!/bin/bash

# build docker images
docker build -f dockers/resolver_software/bind.Dockerfile -t ruc-bind:9.20.3 .

# start docker containers
docker run -d --name ruc-bind --network ruc-test-net --ip 172.22.1.1 ruc-bind:9.20.3

echo "[*] Start containers of tested DNS resolvers for the RUC test, done."