#! /bin/bash

#docker builder prune -f
DOCKER_BUILDKIT=1 docker build \
    -t stable-diffusion-webui-rocm \
    --network="host" .
