#!/usr/bin/env bash
set -euo pipefail

# Coverage build uses Debug + ENABLE_COVERAGE=ON
BUILD_TYPE="Debug"

# Prepare Conan-generated presets for Debug
bash scripts/setup-conan-presets.sh "${BUILD_TYPE}"

# Configure, build, and test with coverage enabled
export EXTRA_CMAKE_FLAGS="-DENABLE_COVERAGE=ON"
bash scripts/build-type.sh "${BUILD_TYPE}"

# Generate coverage report
if [ -x scripts/coverage-report.sh ]; then
  scripts/coverage-report.sh
else
  bash scripts/coverage-report.sh
fi
