FROM ubuntu:22.04

WORKDIR /working

RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    vim-tiny \
    python3 \
    python3-venv \
    libopenmpi3 \
    libstdc++-11-dev \
    libopenblas-dev \
    ffmpeg \
    libsm6 \
    libxext6 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui && \
cd stable-diffusion-webui/ && \
python3 -m venv venv && \
venv/bin/pip install --upgrade pip wheel && \
venv/bin/pip install -r requirements.txt

EXPOSE 7860

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
