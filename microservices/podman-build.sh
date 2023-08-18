#!/bin/bash

export VERSION=$(cat package.json | jq -r '.version')

podman login docker.io
podman build . -t rod4n4m1/node-api:$VERSION
podman push rod4n4m1/node-api:$VERSION
