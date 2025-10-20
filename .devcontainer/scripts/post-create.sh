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

# Install dependencies & generate presets for both configs.
# This produces CMakeUserPresets.json and includes Conan-generated CMakePresets.
# See: https://docs.conan.io/.../build_project_cmake_presets.html
conan install . -s build_type=Release -s compiler.cppstd=23 --build=missing
conan install . -s build_type=Debug   -s compiler.cppstd=23 --build=missing

# ---------- CMake (using presets) ----------
# Multi-config generators expose a "conan-default" configure preset.
# Single-config generators use per-config configure presets (conan-debug / conan-release).
if cmake --preset conan-default >/dev/null 2>&1; then
  echo "[post-create] Detected multi-config generator (conan-default)."
  cmake --preset conan-default

  # Build both variants
  cmake --build --preset conan-debug
  cmake --build --preset conan-release
else
  echo "[post-create] Detected single-config generator."
  # Debug
  cmake --preset conan-debug
  cmake --build --preset conan-debug

  # Release
  cmake --preset conan-release
  cmake --build --preset conan-release
fi


# ---------- compile_commands.json convenience ----------
# Symlink the Debug compile DB to the repo root so clangd finds it automatically.
# The generated layout typically puts it in build/Debug or similar (managed by cmake_layout).
if [ -f "build/Debug/compile_commands.json" ]; then
  ln -sf build/Debug/compile_commands.json compile_commands.json
elif [ -f "build/compile_commands.json" ]; then
  ln -sf build/compile_commands.json compile_commands.json
fi

echo "[post-create] done"

