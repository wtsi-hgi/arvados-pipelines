#!/bin/bash

SOJDK_VERSIONS=(3.4 3.5 3.6 3.7)
OPENJDK_VERSIONS=(3.8)


for version in ${SOJDK_VERSIONS[@]}
do
    docker build . -f Dockerfile-sojdk -t gatk:$version --build-arg version=$version
done

for version in ${OPENJDK_VERSIONS[@]}
do
    docker build . -f Dockerfile-openjdk -t gatk:$version --build-arg version=$version
done
