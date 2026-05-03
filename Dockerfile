# MAME WASM Build Factory - Dockerfile
# Provides a stable Linux environment for full MAME builds

FROM debian:bookworm-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    python3 \
    python3-pip \
    cmake \
    wget \
    curl \
    zip \
    unzip \
    pkg-config \
    libxml2-dev \
    libexpat1-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /src

# Clone EMSDK
RUN git clone --depth 1 https://github.com/emscripten-core/emsdk.git /emsdk
WORKDIR /emsdk

# Install and activate latest emsdk
# We use a specific version known to be stable for MAME wasm32 if "latest" causes issues
RUN ./emsdk install latest && \
    ./emsdk activate latest

# Set environment variables for emscripten
ENV PATH="/emsdk:/emsdk/upstream/emscripten:/emsdk/node/18.20.3_64bit/bin:${PATH}"
ENV EMSCRIPTEN="/emsdk/upstream/emscripten"

# Add a script to source emsdk_env and run build
RUN echo '#!/bin/bash\n\
source /emsdk/emsdk_env.sh\n\
cd /src/mame\n\
emmake make -j$(nproc) "$@"' > /usr/local/bin/mame-build && \
    chmod +x /usr/local/bin/mame-build

# Default to bash
WORKDIR /src
CMD ["/bin/bash"]
