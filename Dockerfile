# ---------------------------------------------------------------------------- #
#                        Stage 1: Build the final image                        #
# ---------------------------------------------------------------------------- #
FROM python:3.10.14-slim AS build_final_image

ARG A1111_RELEASE=v1.9.3

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    ROOT=/stable-diffusion-webui \
    PYTHONUNBUFFERED=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt install -y \
    fonts-dejavu-core rsync git jq moreutils aria2 wget libgoogle-perftools-dev libtcmalloc-minimal4 procps libgl1 libglib2.0-0 && \
    apt-get autoremove -y && rm -rf /var/lib/apt/lists/* && apt-get clean -y

RUN --mount=type=cache,target=/root/.cache/pip \
    export GIT_TERMINAL_PROMPT=0 && \
    git config --global url."https://".insteadOf git:// && \
    git clone https://github.com/niekvugteveen/stable-diffusion-webui.git && \
    cd stable-diffusion-webui && \
    pip install xformers && \
    pip install -r requirements_versions.txt && \
    mkdir -p /stable-diffusion-webui/repositories && \
    cd /stable-diffusion-webui/repositories && \
    (git clone https://github.com/Stability-AI/stablediffusion.git stable-diffusion-stability-ai || \
     git clone https://github.com/CompVis/stable-diffusion.git stable-diffusion-stability-ai) && \
    git clone https://github.com/CompVis/taming-transformers.git && \
    git clone https://github.com/crowsonkb/k-diffusion.git && \
    git clone https://github.com/sczhou/CodeFormer.git && \
    git clone https://github.com/salesforce/BLIP.git

# Copy local model files instead of downloading
COPY stable-diffusion-webui/models/Stable-diffusion/*.safetensors /stable-diffusion-webui/models/Stable-diffusion/

# install dependencies
COPY sd_runpod_worker/worker-a1111/requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir -r requirements.txt

COPY sd_runpod_worker/worker-a1111/test_input.json .

ADD sd_runpod_worker/worker-a1111/src .

RUN chmod +x /start.sh
CMD /start.sh