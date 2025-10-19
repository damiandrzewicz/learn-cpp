#!/usr/bin/env bash
set -euo pipefail

# Fix ownership (first run after create)
sudo mkdir -p /home/vscode/.ccache
sudo chown -R vscode:vscode /home/vscode/.ccache

# Prime ccache
ccache -M 10G || true
ccache -s || true

# Conan setup
conan --version || true
# Try forced detect first (overwrites), then plain detect as fallback
conan profile detect --force || conan profile detect || true
