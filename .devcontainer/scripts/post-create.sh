#!/usr/bin/env bash
set -euo pipefail

# Fix ownership (first run after create)
sudo mkdir -p /home/vscode/.ccache
sudo chown -R vscode:vscode /home/vscode/.ccache

# Prime ccache
ccache -M 10G || true
ccache -s || true

# Conan setup
bash scripts/setup-conan-presets.sh Debug Release

# Build both variants via reusable script
bash scripts/build-type.sh Debug
bash scripts/build-type.sh Release


# ---------- compile_commands.json convenience ----------
# Symlink the Debug compile DB to the repo root so clangd finds it automatically.
# The generated layout typically puts it in build/Debug or similar (managed by cmake_layout).
if [ -f "build/Debug/compile_commands.json" ]; then
  ln -sf build/Debug/compile_commands.json compile_commands.json
elif [ -f "build/compile_commands.json" ]; then
  ln -sf build/compile_commands.json compile_commands.json
fi

echo "[post-create] done"

