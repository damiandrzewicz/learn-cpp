#!/usr/bin/env bash
set -euo pipefail

# build.sh [Debug|Release]
# Shared local/CI entrypoint: prepares Conan, configures, builds, tests.
# When BUILD_TYPE=Debug, coverage flags are enabled via the 'debug' preset.

BUILD_TYPE=${1:-Debug}
LOWER=$(echo "$BUILD_TYPE" | tr '[:upper:]' '[:lower:]')
PRESET="$LOWER"

if [[ "$BUILD_TYPE" != "Debug" && "$BUILD_TYPE" != "Release" ]]; then
  echo "[build] Unknown build type: $BUILD_TYPE (expected Debug|Release)" >&2
  exit 2
fi

# 1) Ensure Conan dependencies and toolchains are present for this build type
bash scripts/setup-conan-presets.sh "$BUILD_TYPE"

# 2) Configure, build, and test via CMake presets
echo "[build] Configure: $PRESET"
cmake --preset "$PRESET"

echo "[build] Build: $PRESET"
cmake --build --preset "$PRESET" -j"$(nproc)"

# Prefer ctest via preset when available; otherwise test from build dir
if cmake --build --preset "$PRESET" >/dev/null 2>&1; then
  echo "[build] Test: $PRESET"
  ctest --preset "$PRESET" --output-on-failure
else
  BUILD_DIR="build/$BUILD_TYPE"
  echo "[build] Test dir: $BUILD_DIR"
  ctest --test-dir "$BUILD_DIR" --output-on-failure
fi

# 3) Produce coverage report for Debug
if [[ "$BUILD_TYPE" == "Debug" ]]; then
  # Avoid mixing stale coverage artifacts from older layouts
  if [[ -d build/Coverage ]]; then
    echo "[build] Removing stale build/Coverage to avoid gcovr conflicts"
    rm -rf build/Coverage || true
  fi
  if [ -x scripts/coverage-report.sh ]; then
    scripts/coverage-report.sh "build/Debug"
  else
    bash scripts/coverage-report.sh "build/Debug"
  fi
fi

echo "[build] done"
