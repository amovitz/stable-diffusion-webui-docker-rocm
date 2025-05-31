FROM alpine/git:2.36.2 AS download

COPY clone.sh /clone.sh

RUN . /clone.sh stable-diffusion-stability-ai https://github.com/Stability-AI/stablediffusion.git cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf \
  && rm -rf assets data/**/*.png data/**/*.jpg data/**/*.gif

RUN . /clone.sh BLIP https://github.com/salesforce/BLIP.git 48211a1594f1321b00f14c9f7a5b4813144b2fb9
RUN . /clone.sh k-diffusion https://github.com/crowsonkb/k-diffusion.git ab527a9a6d347f364e3d185ba6d714e22d80cb3c
RUN . /clone.sh clip-interrogator https://github.com/pharmapsychotic/clip-interrogator 2cf03aaf6e704197fd0dae7c7f96aa59cf1b11c9
RUN . /clone.sh generative-models https://github.com/Stability-AI/generative-models 45c443b316737a4ab6e40413d7794a7f5657c19f
RUN . /clone.sh stable-diffusion-webui-assets https://github.com/AUTOMATIC1111/stable-diffusion-webui-assets 6f7db241d2f8ba7457bac5ca9753331f0c266917



# Use the ROCm 6.4 docker, with py3.10 as a base
#FROM rocm/pytorch:rocm6.4.1_ubuntu22.04_py3.10_pytorch_release_2.3.0
FROM rocm/pytorch:rocm6.4_ubuntu22.04_py3.10_pytorch_release_2.6.0 AS rocm
ENV ROCM_VERSION=6.4
ENV DEBIAN_FRONTEND=noninteractive PIP_PREFER_BINARY=1
ENV PIP_CACHE_DIR=/root/.cache/pip

COPY clone.sh /clone.sh

RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/var/lib/apt \
  apt-get update && \
  apt-get install -y fonts-dejavu-core rsync git jq moreutils aria2 \
  libsm6 libxext6 libssl-dev \
  ffmpeg libglfw3-dev libgles2-mesa-dev pkg-config libcairo2 libcairo2-dev build-essential

RUN apt-get -y install libgoogle-perftools-dev && apt-get clean
ENV LD_PRELOAD=libtcmalloc.so
COPY . /docker

RUN git config --global --add safe.directory '*'

# Get Stable Diffusion WebUI 1.10.1
FROM rocm AS sd
ENV ROOT=/stable-diffusion-webui
WORKDIR /repositories
RUN bash -c ". /clone.sh stable-diffusion-webui https://github.com/AUTOMATIC1111/stable-diffusion-webui.git 82a973c04367123ae98bd9abdf80d9eda9b910e2"
RUN --mount=type=cache,target=/root/.cache/pip \
  cp -r stable-diffusion-webui / && \
  cd ${ROOT} && \
  pip install -r requirements_versions.txt \
    --extra-index-url https://download.pytorch.org/whl/rocm6.3

RUN find / -path '*gradio/routes.py' -exec sed -i 's/in_app_dir = .*/in_app_dir = True/g' {} +

# Get base models
FROM sd AS models
COPY --from=download /repositories/ ${ROOT}/repositories/
RUN mkdir ${ROOT}/interrogate && cp ${ROOT}/repositories/clip-interrogator/clip_interrogator/data/* ${ROOT}/interrogate

# Install xFormers 0.0.30 ROCm
FROM models AS xformers
RUN --mount=type=cache,target=/root/.cache/pip \
  pip3 install -U xformers --index-url https://download.pytorch.org/whl/rocm6.3

RUN --mount=type=cache,target=/root/.cache/pip \
  pip install pyngrok \
  git+https://github.com/TencentARC/GFPGAN.git@8d2447a2d918f8eba5a4a01463fd48e45126a379 \
  git+https://github.com/openai/CLIP.git@d50d76daa670286dd6cacf3bcd80b5e4823fc8e1 \
  git+https://github.com/mlfoundations/open_clip.git@v2.20.0 \
  torch==2.4.0+rocm6.3.4.git7cecbf6d \
  torchvision==0.19.0+rocm6.3.4.gitfab84886 \
  torchaudio==2.4.0+rocm6.3.4.git69d40773 \
  pytorch_triton_rocm==3.0.0+rocm6.3.4.git75cc27c2 \
  --find-links=https://repo.radeon.com/rocm/manylinux/rocm-rel-6.3.4/ \
  --extra-index-url https://download.pytorch.org/whl/rocm6.3

WORKDIR ${ROOT}
ENV CLI_ARGS=""
EXPOSE 7860
ENTRYPOINT ["/docker/entrypoint.sh"]
CMD python -u webui.py --listen --port 7860 ${CLI_ARGS}
