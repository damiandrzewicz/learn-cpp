#!/usr/bin/env bash
set -euo pipefail

# build-type.sh [Debug|Release]
# Uses Conan-generated CMakePresets (conan-debug/conan-release) to configure, build, and run tests.

BUILD_TYPE=${1:-Debug}
PRESET="conan-$(echo "${BUILD_TYPE}" | tr '[:upper:]' '[:lower:]')"

# EXTRA_CMAKE_FLAGS environment variable can be used to pass -D options, e.g. -DENABLE_COVERAGE=ON
EXTRA_CMAKE_FLAGS=${EXTRA_CMAKE_FLAGS:-}

echo "[build-type] Configure preset: ${PRESET} (BUILD_TYPE=${BUILD_TYPE})"
cmake --preset "${PRESET}" ${EXTRA_CMAKE_FLAGS}

echo "[build-type] Build preset: ${PRESET}"
cmake --build --preset "${PRESET}" -j

BUILD_DIR="build/${BUILD_TYPE}"
echo "[build-type] Test dir: ${BUILD_DIR}"
ctest --test-dir "${BUILD_DIR}" --output-on-failure

echo "[build-type] done"
