#!/usr/bin/env bash
set -euo pipefail

# setup-conan-presets.sh [BUILD_TYPE...]
# Detects Conan profile and installs dependencies for the provided build types.
# If no build types are provided, defaults to Debug and Release.

CPPSTD=${CPPSTD:-23}

if [ "$#" -eq 0 ]; then
  BUILD_TYPES=(Debug Release)
else
  BUILD_TYPES=("$@")
fi

echo "[setup-conan] Using C++ standard: ${CPPSTD}"
conan --version || true
conan profile detect --force || conan profile detect || true

for BT in "${BUILD_TYPES[@]}"; do
  echo "[setup-conan] Installing deps for build_type=${BT}"
  conan install . \
    -s build_type="${BT}" \
    -s compiler.cppstd="${CPPSTD}" \
    -c tools.cmake.cmaketoolchain:generator=Ninja \
    --build=missing
done

echo "[setup-conan] done"
