#!/usr/bin/env bash
set -euo pipefail

# Ensure the mounted volume is owned by vscode on every start
sudo mkdir -p /home/vscode/.ccache
sudo chown -R vscode:vscode /home/vscode/.ccache

# (Optional) show current owner for sanity
ls -ld /home/vscode/.ccache || true
