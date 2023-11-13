FROM ubuntu:22.04

WORKDIR /working

RUN apt-get update && \
    apt-get install -y build-essential git curl vim-tiny

RUN apt-get install -y python3 python3-venv libopenmpi3 libstdc++-11-dev libopenblas-dev

RUN curl -LO https://repo.radeon.com/amdgpu-install/22.40.3/ubuntu/focal/amdgpu-install_5.4.50403-1_all.deb && \
    apt-get install -y ./amdgpu-install_5.4.50403-1_all.deb && \
    amdgpu-install --no-dkms -y --usecase=rocm,hiplibsdk,mlsdk

COPY torch-whls /torch-whls

RUN cat /torch-whls/torch-1.13.1-cp310-cp310-linux_x86_64.whl.* > \
  /torch-whls/torch-1.13.1-cp310-cp310-linux_x86_64.whl

RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui && \
    cd stable-diffusion-webui/ && \
    python3 -m venv venv && \
    venv/bin/pip install /torch-whls/*whl && \
    venv/bin/pip install --upgrade pip wheel

EXPOSE 7860

ENV ROC_ENABLE_PRE_VEGA=1 \
  HSA_OVERRIDE_GFX_VERSION=8.0.3

WORKDIR /working/stable-diffusion-webui

COPY scripts/configure.py .

RUN ./venv/bin/python configure.py --skip-torch-cuda-test

# Add Tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

ENTRYPOINT ["/tini", "--"]
CMD [ \
  "./venv/bin/python", \
  "launch.py", \
  "--no-download-sd-model", \
  "--listen", \
  "--enable-insecure-extension-access"]

# docker run --rm -ti  --network=host --device=/dev/kfd --device=/dev/dri --group-add=video --ipc=host --cap-add=SYS_PTRACE --security-opt seccomp=unconfined -v $PWD/models:/working/stable-diffusion-webui/models:ro -P --entrypoint /bin/bash sd:latest
