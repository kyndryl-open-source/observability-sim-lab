#!/bin/bash

export VERSION=$(cat package.json | jq -r '.version')

docker login
docker build . -t rod4n4m1/node-api:$VERSION
docker push rod4n4m1/node-api:$VERSION
