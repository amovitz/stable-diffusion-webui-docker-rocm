#! /bin/bash

reset

docker builder prune -f
DOCKER_BUILDKIT=1 docker build \
    -t stable-diffusion-webui-rocm \
    --progress=plain \
    --network="host" .

if [ $? -ne 0 ] ; then
    tput bel
else
    tput bel
    sleep 0.5
    tput bel
fi
