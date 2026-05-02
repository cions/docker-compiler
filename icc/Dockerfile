FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        g++ \
        g++-multilib \
        gnupg \
 && curl -fsSL "https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB" | gpg --dearmor > /etc/apt/trusted.gpg.d/intel.gpg \
 && echo "deb https://apt.repos.intel.com/oneapi all main" > /etc/apt/sources.list.d/intel-oneapi.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
        intel-oneapi-compiler-dpcpp-cpp \
 && rm -rf /var/lib/apt/lists/*


ENV PATH="/opt/intel/oneapi/compiler/latest/bin:$PATH"

LABEL org.opencontainers.image.source="https://github.com/cions/docker-compiler"
