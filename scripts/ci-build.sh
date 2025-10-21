#!/usr/bin/env bash
set -euo pipefail

# ci-build.sh [Debug|Release]
BUILD_TYPE="${1:-Debug}"

echo "[ci-build] Build type: ${BUILD_TYPE}"

# Prepare Conan-generated presets for this build type
bash scripts/setup-conan-presets.sh "${BUILD_TYPE}"

# Configure, build, and test using the preset
bash scripts/build-type.sh "${BUILD_TYPE}"
