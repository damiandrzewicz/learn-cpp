FROM mcr.microsoft.com/devcontainers/cpp:ubuntu-24.04

# ccache + Python venv tools
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ccache python3-venv python3-pip clangd clang-format sudo && \
    rm -rf /var/lib/apt/lists/*

# Create isolated venv for Conan (avoids PEP 668)
RUN python3 -m venv /opt/conan \
 && /opt/conan/bin/pip install --no-cache-dir -U pip \
 && /opt/conan/bin/pip install --no-cache-dir "conan>=2.4,<3" \
 && ln -s /opt/conan/bin/conan /usr/local/bin/conan

# ccache defaults
ENV CCACHE_DIR=/home/vscode/.ccache
ENV CCACHE_COMPRESS=1
ENV CCACHE_SLOPPINESS=time_macros
