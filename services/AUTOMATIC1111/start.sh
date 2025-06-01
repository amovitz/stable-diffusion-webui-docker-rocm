#! /bin/bash

# Stable Diffusion WebUI
docker stop automatic1111
docker container rm automatic1111

docker run \
    -it \
    --add-host=host.docker.internal:host-gateway \
    --network=host \
    --device=/dev/kfd:/dev/kfd \
    --device=/dev/dri:/dev/dri \
    --group-add=video \
    --ipc=host \
    --cap-add=SYS_PTRACE \
    --security-opt seccomp=unconfined \
    -v /NVMe/automatic1111/data:/data \
    -v /NVMe/automatic1111/output:/output \
    -e CLI_ARGS="--api --medvram --autolaunch --no-half --precision full --no-half-vae --medvram --opt-sub-quad-attention --opt-split-attention-v1 --allow-code --enable-insecure-extension-access --xformers --upcast-sampling" \
    -e IGNORE_CMD_ARGS_ERRORS=1 \
    -e HSA_OVERRIDE_GFX_VERSION=10.3.0 \
    -e ROC_ENABLE_PRE_VEG=1 \
    -e XFORMERS_PACKAGE="xformers==0.0.30" \
    --shm-size 8G \
    --name automatic1111 \
    stable-diffusion-webui-rocm

# Run Options
# replace '-it' with '-d' to detach and run in the background
# add '--restart=always' to run as a background service
